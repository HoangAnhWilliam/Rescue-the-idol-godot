extends Node2D  # ← ĐỔI từ Node thành Node2D
class_name EnemySpawner

# Enemy scenes
@export var zombie_scene: PackedScene 
@export var skeleton_scene: PackedScene
@export var anime_ghost_scene: PackedScene
@export var elite_monster_scene: PackedScene
@export var mini_boss_scene: PackedScene

# Spawn settings
@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.3
@export var spawn_radius: float = 300.0  # ← Giảm từ 500 → 300 (dễ thấy hơn)
@export var difficulty_increase_rate: float = 0.1  # 10% per minute

# State
var current_spawn_interval: float
var spawn_timer: float = 0.0
var game_time: float = 0.0
var difficulty_timer: float = 0.0

# References
var player: CharacterBody2D  # ← ĐỔI từ Player thành CharacterBody2D

func _ready():
	print("=== EnemySpawner Init ===")
	
	current_spawn_interval = base_spawn_interval
	spawn_timer = base_spawn_interval  # ← THÊM: Spawn ngay lần đầu
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Debug info
	print("Player found: ", player)
	print("Zombie scene: ", zombie_scene)
	
	# Force load zombie nếu null
	if not zombie_scene:
		print("WARNING: Zombie scene not assigned, loading manually...")
		zombie_scene = load("res://scenes/enemies/zombie.tscn")
		if zombie_scene:
			print("✓ Zombie scene loaded!")
		else:
			print("ERROR: Cannot load zombie scene!")
	
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
		spawn_timer = current_spawn_interval

func increase_difficulty():
	current_spawn_interval *= (1.0 - difficulty_increase_rate)
	current_spawn_interval = max(current_spawn_interval, min_spawn_interval)
	print("Difficulty increased! Spawn interval: ", current_spawn_interval)

func spawn_enemy():
	# Safety checks
	if not player:
		player = get_tree().get_first_node_in_group("player")
		if not player:
			print("ERROR: No player found!")
			return
	
	# Get enemy type
	var enemy_type = get_enemy_type_for_time()
	
	if not enemy_type:
		print("ERROR: No enemy scene to spawn!")
		return
	
	# Instantiate enemy
	var enemy = enemy_type.instantiate()
	
	# Random position around player
	var angle = randf() * TAU
	var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
	enemy.global_position = player.global_position + offset
	
	# Add to scene
	get_parent().add_child(enemy)
	
	print("✓ Spawned enemy at: ", enemy.global_position)
	
	# Scale stats based on game time (chỉ nếu enemy có properties này)
	if enemy.has_method("apply_difficulty_scaling"):
		enemy.apply_difficulty_scaling(game_time)
	else:
		# Manual scaling nếu enemy không có method
		apply_difficulty_scaling(enemy)

func get_enemy_type_for_time() -> PackedScene:
	# Chỉ dùng zombie trong giai đoạn đầu
	# Các enemy khác sẽ implement sau
	
	# 0-10 minutes: Only zombies (vì chưa có skeleton, ghost)
	if game_time < 600:
		return zombie_scene
	
	# Sau này sẽ uncomment khi có đủ enemy types
	"""
	var roll = randf()
	
	# 0-10 minutes: Basic enemies
	if game_time < 600:
		if roll < 0.7:
			return zombie_scene
		else:
			return skeleton_scene if skeleton_scene else zombie_scene
	
	# 10-20 minutes: Add Anime Ghosts
	elif game_time < 1200:
		if roll < 0.5:
			return zombie_scene
		elif roll < 0.8:
			return skeleton_scene if skeleton_scene else zombie_scene
		else:
			return anime_ghost_scene if anime_ghost_scene else zombie_scene
	
	# 20+ minutes: Add Elite Monsters and Mini-Bosses
	else:
		if roll < 0.4:
			return zombie_scene
		elif roll < 0.7:
			return skeleton_scene if skeleton_scene else zombie_scene
		elif roll < 0.85:
			return anime_ghost_scene if anime_ghost_scene else zombie_scene
		elif roll < 0.95:
			return elite_monster_scene if elite_monster_scene else zombie_scene
		else:
			return mini_boss_scene if mini_boss_scene else zombie_scene
	"""
	
	return zombie_scene  # Fallback

func apply_difficulty_scaling(enemy):
	# Check if enemy is valid
	if not enemy:
		return
	
	var wave = int(game_time / 60.0)
	
	var hp_multiplier = 1.0 + (wave * 0.15)
	var damage_multiplier = 1.0 + (wave * 0.10)
	var xp_multiplier = 1.0 + (wave * 0.05)
	
	# Apply scaling - Dùng "in" thay vì has()
	if "max_hp" in enemy:
		enemy.max_hp *= hp_multiplier
		print("Scaled HP: ", enemy.max_hp)
		
		if "current_hp" in enemy:
			enemy.current_hp = enemy.max_hp
	
	if "damage" in enemy:
		enemy.damage *= damage_multiplier
		print("Scaled DMG: ", enemy.damage)
	
	if "xp_reward" in enemy:
		enemy.xp_reward *= xp_multiplier
		print("Scaled XP: ", enemy.xp_reward)
	
	print("Applied wave ", wave, " scaling to ", enemy.name)

func spawn_boss(boss_scene: PackedScene, position: Vector2):
	if not boss_scene:
		print("ERROR: No boss scene provided!")
		return null
	
	var boss = boss_scene.instantiate()
	boss.global_position = position
	get_parent().add_child(boss)
	
	print("Boss spawned at: ", position)
	return boss
