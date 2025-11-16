extends Node2D
class_name EnemySpawner

# Enemy scenes - Original
@export var zombie_scene: PackedScene
@export var skeleton_bad_scene: PackedScene
@export var skeleton_buff_scene: PackedScene
@export var anime_ghost_scene: PackedScene
@export var elite_monster_scene: PackedScene
@export var mini_boss_scene: PackedScene
@export var magma_slime_scene: PackedScene  # Magma Slime for Volcanic Darklands

# NEW: 8 Biome-Specific Enemies
@export var vampire_bat_scene: PackedScene  # Desert Wasteland
@export var skeleton_camel_scene: PackedScene  # Desert Wasteland
@export var desert_nomad_scene: PackedScene  # Desert Wasteland
@export var ice_golem_scene: PackedScene  # Frozen Tundra
@export var snowman_warrior_scene: PackedScene  # Frozen Tundra
@export var snowdwarf_traitor_scene: PackedScene  # Frozen Tundra
@export var lava_elemental_scene: PackedScene  # Volcanic Darklands
@export var dark_miku_scene: PackedScene  # Blood Temple

# Spawn settings
@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.3
@export var spawn_radius: float = 300.0
@export var difficulty_increase_rate: float = 0.1  # 10% per minute

# State
var current_spawn_interval: float
var spawn_timer: float = 0.0
var game_time: float = 0.0
var difficulty_timer: float = 0.0

# References
var player: CharacterBody2D
var biome_generator: BiomeGenerator  # NEW: Reference to BiomeGenerator

func _ready():
	print("=== EnemySpawner Init ===")

	current_spawn_interval = base_spawn_interval
	spawn_timer = base_spawn_interval

	# Find player
	player = get_tree().get_first_node_in_group("player")

	# NEW: Find BiomeGenerator
	await get_tree().process_frame
	biome_generator = get_tree().get_first_node_in_group("biome_generator")

	if biome_generator:
		print("✓ BiomeGenerator found!")
	else:
		print("⚠️ WARNING: BiomeGenerator not found! Enemies will spawn normally.")

	# Debug info
	print("Player found: ", player != null)
	print("Zombie scene: ", zombie_scene != null)

	# Force load scenes if null
	if not zombie_scene:
		print("WARNING: Zombie scene not assigned, loading manually...")
		zombie_scene = load("res://scenes/enemies/zombie.tscn")
		if zombie_scene:
			print("✓ Zombie scene loaded!")
		else:
			print("ERROR: Cannot load zombie scene!")

	if not skeleton_bad_scene:
		skeleton_bad_scene = load("res://scenes/enemies/skeleton_bad.tscn")
		if skeleton_bad_scene:
			print("✓ Bad Skeleton scene loaded!")

	if not skeleton_buff_scene:
		skeleton_buff_scene = load("res://scenes/enemies/skeleton_buff.tscn")
		if skeleton_buff_scene:
			print("✓ Buff Skeleton scene loaded!")

	if not anime_ghost_scene:
		anime_ghost_scene = load("res://scenes/enemies/anime_ghost.tscn")
		if anime_ghost_scene:
			print("✓ Anime ghost scene loaded!")

	# NEW: Load Magma Slime
	if not magma_slime_scene:
		magma_slime_scene = load("res://scenes/enemies/magma_slime.tscn")
		if magma_slime_scene:
			print("✓ Magma Slime scene loaded!")
		else:
			print("⚠️ WARNING: Magma Slime scene not found!")

	# NEW: Load 8 Biome-Specific Enemies
	if not vampire_bat_scene:
		vampire_bat_scene = load("res://scenes/enemies/vampire_bat.tscn")
		if vampire_bat_scene:
			print("✓ Vampire Bat scene loaded!")

	if not skeleton_camel_scene:
		skeleton_camel_scene = load("res://scenes/enemies/skeleton_camel.tscn")
		if skeleton_camel_scene:
			print("✓ Skeleton Camel scene loaded!")

	if not desert_nomad_scene:
		desert_nomad_scene = load("res://scenes/enemies/desert_nomad.tscn")
		if desert_nomad_scene:
			print("✓ Desert Nomad scene loaded!")

	if not ice_golem_scene:
		ice_golem_scene = load("res://scenes/enemies/ice_golem.tscn")
		if ice_golem_scene:
			print("✓ Ice Golem scene loaded!")

	if not snowman_warrior_scene:
		snowman_warrior_scene = load("res://scenes/enemies/snowman_warrior.tscn")
		if snowman_warrior_scene:
			print("✓ Snowman Warrior scene loaded!")

	if not snowdwarf_traitor_scene:
		snowdwarf_traitor_scene = load("res://scenes/enemies/snowdwarf_traitor.tscn")
		if snowdwarf_traitor_scene:
			print("✓ Snowdwarf Traitor scene loaded!")

	if not lava_elemental_scene:
		lava_elemental_scene = load("res://scenes/enemies/lava_elemental.tscn")
		if lava_elemental_scene:
			print("✓ Lava Elemental scene loaded!")

	if not dark_miku_scene:
		dark_miku_scene = load("res://scenes/enemies/dark_miku.tscn")
		if dark_miku_scene:
			print("✓ Dark Miku scene loaded!")

	print("========================")

func _process(delta):
	game_time += delta
	difficulty_timer += delta
	spawn_timer -= delta

	# Increase difficulty every minute
	if difficulty_timer >= 60.0:
		difficulty_timer = 0.0
		increase_difficulty()

	# Spawn enemies
	if spawn_timer <= 0:
		spawn_enemy()
		# NEW: Apply biome spawn multiplier
		var biome_multiplier = get_biome_spawn_multiplier()
		spawn_timer = current_spawn_interval / biome_multiplier

func increase_difficulty():
	current_spawn_interval *= (1.0 - difficulty_increase_rate)
	current_spawn_interval = max(current_spawn_interval, min_spawn_interval)
	print("⚡ Difficulty increased! Spawn interval: %.2f" % current_spawn_interval)

# NEW: Get biome spawn multiplier
func get_biome_spawn_multiplier() -> float:
	if not biome_generator:
		return 1.0

	var current_biome = biome_generator.get_current_biome()
	if not current_biome:
		return 1.0

	return current_biome.enemy_spawn_multiplier

func spawn_enemy():
	# Safety checks
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("ERROR: No player found!")
			return

	# NEW: Get enemy type based on biome
	var enemy_scene = get_enemy_type_for_biome()

	if not enemy_scene:
		print("ERROR: No enemy scene to spawn!")
		return

	# Instantiate enemy
	var enemy = enemy_scene.instantiate()

	# Random position around player
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset

	# NEW: Apply biome tint to enemy
	apply_biome_tint(enemy)

	# Add to scene
	get_parent().add_child(enemy)

	var biome_name = get_current_biome_name()
	print("✓ Spawned %s in %s at: %v" % [enemy.name, biome_name, enemy.global_position])

	# Scale stats based on game time
	apply_difficulty_scaling(enemy)

# NEW: Get enemy type based on current biome
func get_enemy_type_for_biome() -> PackedScene:
	var current_biome = null
	if biome_generator:
		current_biome = biome_generator.get_current_biome()

	# If no biome system, use default spawning
	if not current_biome:
		return get_default_enemy_type()

	# Biome-specific spawning logic
	match current_biome.type:
		BiomeGenerator.BiomeType.STARTING_FOREST:
			return get_forest_enemy()

		BiomeGenerator.BiomeType.DESERT_WASTELAND:
			return get_desert_enemy()

		BiomeGenerator.BiomeType.FROZEN_TUNDRA:
			return get_tundra_enemy()

		BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS:
			return get_volcanic_enemy()  # Can spawn Magma Slime!

		BiomeGenerator.BiomeType.BLOOD_TEMPLE:
			return get_temple_enemy()

		_:
			return get_default_enemy_type()

# Forest enemies (easier)
func get_forest_enemy() -> PackedScene:
	var roll = randf()

	if roll < 0.02:  # 2% - Buff Skeleton
		return skeleton_buff_scene if skeleton_buff_scene else zombie_scene
	elif roll < 0.17:  # 15% - Anime Ghost
		return anime_ghost_scene if anime_ghost_scene else zombie_scene
	elif roll < 0.47:  # 30% - Bad Skeleton
		return skeleton_bad_scene if skeleton_bad_scene else zombie_scene
	else:  # 53% - Zombie
		return zombie_scene

# Desert enemies - Time-based progression with Skeleton Buff
func get_desert_enemy() -> PackedScene:
	var minutes = int(game_time / 60.0)
	var roll = randf()

	# Skeleton Buff appears in all tiers with 2% chance
	if roll < 0.02 and skeleton_buff_scene:
		return skeleton_buff_scene

	# Time-based progression:
	# 0-10 min: Basic enemies (Vampire Bat, Zombie)
	# 10-20 min: Add medium enemies (Skeleton Camel)
	# 20+ min: Add hard enemies (Desert Nomad)

	if minutes >= 20:  # HARD MODE (20+ min)
		if roll < 0.12 and desert_nomad_scene:  # 10% - Desert Nomad (hard)
			return desert_nomad_scene
		elif roll < 0.42 and skeleton_camel_scene:  # 30% - Skeleton Camel
			return skeleton_camel_scene
		elif roll < 1.00 and vampire_bat_scene:  # 58% - Vampire Bat
			return vampire_bat_scene
		else:  # Fallback
			return zombie_scene

	elif minutes >= 10:  # MEDIUM MODE (10-20 min)
		if roll < 0.32 and skeleton_camel_scene:  # 30% - Skeleton Camel
			return skeleton_camel_scene
		elif roll < 0.92 and vampire_bat_scene:  # 60% - Vampire Bat
			return vampire_bat_scene
		else:  # 8% - Zombie
			return zombie_scene

	else:  # EASY MODE (0-10 min)
		if roll < 0.72 and vampire_bat_scene:  # 70% - Vampire Bat (basic)
			return vampire_bat_scene
		else:  # 28% - Zombie
			return zombie_scene

# Tundra enemies - Time-based progression with Skeleton Buff
func get_tundra_enemy() -> PackedScene:
	var minutes = int(game_time / 60.0)
	var roll = randf()

	# Skeleton Buff appears in all tiers with 2.5% chance
	if roll < 0.025 and skeleton_buff_scene:
		return skeleton_buff_scene

	# Time-based progression:
	# 0-10 min: Basic enemies (Snowman Warrior, Zombie)
	# 10-20 min: Add medium enemies (Ice Golem)
	# 20+ min: Add hard enemies (Snowdwarf Traitor)

	if minutes >= 20:  # HARD MODE (20+ min)
		if roll < 0.225 and snowdwarf_traitor_scene:  # 20% - Snowdwarf Traitor (hard)
			return snowdwarf_traitor_scene
		elif roll < 0.525 and ice_golem_scene:  # 30% - Ice Golem
			return ice_golem_scene
		elif roll < 1.00 and snowman_warrior_scene:  # 47.5% - Snowman Warrior
			return snowman_warrior_scene
		else:  # Fallback
			return zombie_scene

	elif minutes >= 10:  # MEDIUM MODE (10-20 min)
		if roll < 0.325 and ice_golem_scene:  # 30% - Ice Golem
			return ice_golem_scene
		elif roll < 0.825 and snowman_warrior_scene:  # 50% - Snowman Warrior
			return snowman_warrior_scene
		else:  # 17.5% - Zombie
			return zombie_scene

	else:  # EASY MODE (0-10 min)
		if roll < 0.625 and snowman_warrior_scene:  # 60% - Snowman Warrior (basic)
			return snowman_warrior_scene
		else:  # 37.5% - Zombie
			return zombie_scene

# Volcanic enemies - Time-based progression with Skeleton Buff
func get_volcanic_enemy() -> PackedScene:
	var minutes = int(game_time / 60.0)
	var roll = randf()

	# Skeleton Buff appears in all tiers with 2% chance
	if roll < 0.02 and skeleton_buff_scene:
		return skeleton_buff_scene

	# Time-based progression:
	# 0-10 min: Lava Elemental
	# 10-20 min: Add Lava Elemental
	# 20+ min: Mix of both

	if minutes >= 10:  # MEDIUM/HARD MODE (10+ min)
		if roll < 0.72 and lava_elemental_scene:  # 70% - Lava Elemental
			return lava_elemental_scene
		elif roll < 1.00 and magma_slime_scene:  # 28% - Magma Slime
			print("🔥 SPAWNING MAGMA SLIME!")
			return magma_slime_scene
		else:  # Fallback
			return zombie_scene

	else:  # EASY MODE (0-10 min)
		if roll < 0.82 and lava_elemental_scene:  # 80% - Lava Elemental
			return lava_elemental_scene
		else:  # 18% - Magma Slime
			if magma_slime_scene:
				print("🔥 SPAWNING MAGMA SLIME!")
			return magma_slime_scene if magma_slime_scene else zombie_scene

# Blood Temple enemies - NEW: Dark Miku + time-based
func get_temple_enemy() -> PackedScene:
	var minutes = int(game_time / 60.0)
	var roll = randf()

	# Time-based progression:
	# 0-10 min: Zombie
	# 10-20 min: Zombie
	# 20+ min: Dark Miku (mini-boss!)

	if minutes >= 20:  # HARD MODE (20+ min)
		if roll < 0.40 and dark_miku_scene:  # 40% - Dark Miku (mini-boss!)
			print("💀 SPAWNING DARK MIKU!")
			return dark_miku_scene
		else:  # 60% - Zombie
			return zombie_scene

	else:  # EASY/MEDIUM MODE (0-20 min)
		# Only zombies until player is ready
		return zombie_scene

# Fallback default enemy spawning
func get_default_enemy_type() -> PackedScene:
	var roll = randf()

	if roll < 0.02:
		return skeleton_buff_scene if skeleton_buff_scene else zombie_scene
	elif roll < 0.17:
		return anime_ghost_scene if anime_ghost_scene else zombie_scene
	elif roll < 0.47:
		return skeleton_bad_scene if skeleton_bad_scene else zombie_scene
	else:
		return zombie_scene

# NEW: Apply biome color tint to enemies
func apply_biome_tint(enemy: Node):
	if not enemy or not biome_generator:
		return

	var current_biome = biome_generator.get_current_biome()
	if not current_biome:
		return

	# Find sprite/ColorRect in enemy
	var sprite = null
	if enemy.has_node("ColorRect"):
		sprite = enemy.get_node("ColorRect")
	elif enemy.has_node("Sprite2D"):
		sprite = enemy.get_node("Sprite2D")

	if not sprite:
		return

	# Blend biome color with enemy's original color (30% biome, 70% original)
	var original_color = sprite.modulate
	var biome_color = current_biome.color
	var tinted_color = original_color.lerp(biome_color, 0.3)

	sprite.modulate = tinted_color

	print("🎨 Applied %s tint to %s" % [current_biome.name, enemy.name])

# Get current biome name for logging
func get_current_biome_name() -> String:
	if not biome_generator:
		return "Unknown"

	var current_biome = biome_generator.get_current_biome()
	if not current_biome:
		return "Unknown"

	return current_biome.name

func apply_difficulty_scaling(enemy):
	if not enemy:
		return

	var wave = int(game_time / 60.0)

	var hp_multiplier = 1.0 + (wave * 0.15)
	var damage_multiplier = 1.0 + (wave * 0.10)
	var xp_multiplier = 1.0 + (wave * 0.05)

	# Apply scaling
	if "max_hp" in enemy:
		enemy.max_hp *= hp_multiplier

		if "current_hp" in enemy:
			enemy.current_hp = enemy.max_hp

	if "damage" in enemy:
		enemy.damage *= damage_multiplier

	if "xp_reward" in enemy:
		enemy.xp_reward *= xp_multiplier

	if wave > 0:
		print("📈 Applied wave %d scaling to %s (HP: x%.2f, DMG: x%.2f)" % [wave, enemy.name, hp_multiplier, damage_multiplier])

func spawn_boss(boss_scene: PackedScene, position: Vector2):
	if not boss_scene:
		print("ERROR: No boss scene provided!")
		return null

	var boss = boss_scene.instantiate()
	boss.global_position = position
	get_parent().add_child(boss)

	print("👑 Boss spawned at: ", position)
	return boss
