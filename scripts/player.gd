extends CharacterBody2D
class_name Player

# References
@onready var sprite := $ColorRect
@onready var camera := $Camera2D
@onready var weapon_pivot = $WeaponPivot
@onready var collision := $CollisionShape2D
var upgrade_menu  

# Stats
var stats := PlayerStats.new()
var current_hp: float
var current_mana: float
var current_xp: float = 0.0
var level: int = 1

# Stats tracking - THÊM 2 DÒNG NÀY ↓
var total_kills: int = 0
var xp_to_next_level: float = 100.0  # Để UI hiển thị

# Additional stats tracking for Game Over screen
var total_gold: int = 0
var highest_wave: int = 0
var defeated_bosses: Array[String] = []
var total_damage_dealt: int = 0
var total_damage_taken: int = 0
var total_xp_gained: int = 0
var weapons_used: Array[String] = []
var current_biome: String = "Starting Forest"
var game_start_time: float = 0.0

# Gold system
var gold: int = 0

# Buff system
var buff_speed_multiplier: float = 1.0
var buff_damage_multiplier: float = 1.0
var is_invisible: bool = false
var buff_manager: BuffManager = null

# Movement
var input_vector := Vector2.ZERO
var last_direction := Vector2.RIGHT
var mobile_input_vector := Vector2.ZERO  # Mobile touch input

# Combat
# OLD: var current_weapon: Weapon = null  # ← DEPRECATED: Use equipped_weapons instead
var equipped_weapons: Array[Node] = []  # ← NEW: Support multiple weapons
var attack_cooldown: float = 0.0

# Buffs
var kiku_active: bool = false
var kiku_buffs := {
	"attack_speed": 1.0,
	"hp_regen": 1.0,
	"crit_chance": 0.0,
	"move_speed": 1.0
}

# Cheat system properties (for CheatCommands)
var god_mode: bool = false
var one_shot_kill: bool = false
var invincible_hp: bool = false
var invincible_mana: bool = false

# Special items (for quest system)
var special_items: Dictionary = {}
var has_kiku_seal_key: bool = false

# Preload particle scene
var levelup_particle_scene = preload("res://scenes/effects/levelup_particle.tscn")

# Signals
signal hp_changed(current, maximum)
signal mana_changed(current, maximum)
signal level_up(new_level)
signal player_died
signal xp_gained(amount)
signal stat_changed
signal gold_changed(current_gold) 

func _ready():
	current_hp = stats.max_hp
	current_mana = stats.max_mana
	xp_to_next_level = get_xp_for_next_level()
	apply_permanent_upgrades()

	# Initialize game start time for stats tracking
	game_start_time = Time.get_ticks_msec() / 1000.0

	# Setup camera shake
	if camera and not camera.get_script():
		var shake_script = load("res://scripts/camera_shake.gd")
		if shake_script:
			camera.set_script(shake_script)
			print("✓ Camera shake enabled")

	# Initialize BuffManager
	buff_manager = BuffManager.new()
	buff_manager.name = "BuffManager"
	add_child(buff_manager)
	print("✓ BuffManager initialized")

	# OLD weapon initialization (commented for multi-weapon system)
	# if weapon_pivot and weapon_pivot.get_child_count() > 0:
	# 	current_weapon = weapon_pivot.get_child(0)
	# 	print("Player equipped weapon: ", current_weapon.name)

	# NEW: Multi-weapon system (weapons loaded from inventory via HotbarUI)
	# Give starting weapon (Wooden Sword)
	await get_tree().process_frame

	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory:
		# Give starting weapon if inventory empty
		if inventory.get_all_weapons().is_empty():
			print("🪵 No weapons in inventory - adding starting Wooden Sword")
			inventory.add_item(
				inventory.ItemType.WEAPON,
				"wooden_sword",
				1,
				{
					"weapon_name": "Wooden Sword",
					"rarity": 0,  # COMMON
					"damage": 8.0,
					"attack_speed": 1.0
				}
			)

		# Load equipped weapons from inventory
		update_equipped_weapons(inventory.get_all_weapons())
	else:
		print("⚠️ No inventory system found - player has no weapons!")

	# Get upgrade menu reference - THÊM ↓
	await get_tree().process_frame

	print("🔍 Searching for upgrade menu in groups...")
	var nodes_in_group = get_tree().get_nodes_in_group("upgrade_menu")
	print("🔍 Found ", nodes_in_group.size(), " nodes in 'upgrade_menu' group")
	for node in nodes_in_group:
		print("  - Node: ", node.name, " | Path: ", node.get_path())

	upgrade_menu = get_tree().get_first_node_in_group("upgrade_menu")
	if not upgrade_menu:
		print("❌ ERROR: No upgrade menu found in scene!")
		print("❌ Make sure UpgradeMenu is in 'upgrade_menu' group!")
	else:
		print("✅ Upgrade menu found:", upgrade_menu.name)
		print("✅ Path: ", upgrade_menu.get_path())
		print("✅ Type: ", upgrade_menu.get_class())
		print("✅ Has show_menu method: ", upgrade_menu.has_method("show_menu"))

	get_tree().paused = false

func _physics_process(delta):
	handle_input()
	apply_movement(delta)
	#handle_weapon(delta)
	regenerate(delta)
	update_sprite_direction()

func handle_input():
	# Check if input is disabled (for cutscenes)
	if input_disabled:
		input_vector = Vector2.ZERO
		return

	# CHEAT: Check if chat is open and focused - don't move player
	var chat_box = get_tree().get_first_node_in_group("chat_box")
	if chat_box and "is_chat_open" in chat_box and chat_box.is_chat_open:
		input_vector = Vector2.ZERO
		return

	# DEBUG: Press PageUp to manually test upgrade menu
	if Input.is_key_pressed(KEY_PAGEUP):
		print("")
		print("🔧 ========== PAGE UP PRESSED ==========")
		print("🔧 upgrade_menu reference: ", upgrade_menu)
		print("🔧 upgrade_menu null? ", upgrade_menu == null)
		if upgrade_menu:
			print("🔧 upgrade_menu name: ", upgrade_menu.name)
			print("🔧 upgrade_menu path: ", upgrade_menu.get_path())
		print("🔧 Manually triggering upgrade menu")
		show_level_up_menu()
		print("🔧 ====================================")
		print("")
		return

	input_vector = Vector2.ZERO

	# Keyboard/Controller
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1

	input_vector = input_vector.normalized()

	# Mobile touch input (combines with keyboard if both active)
	if mobile_input_vector.length() > 0.1:
		# If no keyboard input, use mobile input directly
		if input_vector.length() < 0.1:
			input_vector = mobile_input_vector
		else:
			# Combine inputs (keyboard takes priority)
			input_vector = input_vector.normalized()

	# Special skill
	#if Input.is_action_just_pressed("special_skill"):
	#	use_special_skill()

func apply_movement(delta):
	var speed = stats.move_speed * kiku_buffs["move_speed"] * buff_speed_multiplier
	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		last_direction = input_vector

func handle_weapon(delta):
	# Multi-weapon system: Handle all equipped weapons
	if equipped_weapons.is_empty():
		return

	attack_cooldown -= delta
	if attack_cooldown <= 0:
		var attack_rate = stats.attack_speed * kiku_buffs["attack_speed"]
		attack_cooldown = 1.0 / attack_rate

		# Each weapon attacks independently
		for weapon in equipped_weapons:
			if not is_instance_valid(weapon):
				continue

			var target = find_closest_enemy(weapon)
			if target:
				weapon.attack(target.global_position)

func find_closest_enemy(weapon: Node) -> Enemy:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null

	var closest: Enemy = null
	var min_distance := INF

	# Get weapon range (default 500 if not available)
	var weapon_range = weapon.get("range") if "range" in weapon else 500.0

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance and distance < weapon_range:
			closest = enemy
			min_distance = distance

	return closest

func regenerate(delta):
	# HP regeneration
	if current_hp < stats.max_hp:
		var regen = stats.hp_regen_per_second * kiku_buffs["hp_regen"] * delta
		current_hp = min(current_hp + regen, stats.max_hp)
		hp_changed.emit(current_hp, stats.max_hp)
	
	# Mana regeneration
	if current_mana < stats.max_mana:
		current_mana = min(current_mana + stats.mana_regen_per_second * delta, stats.max_mana)
		mana_changed.emit(current_mana, stats.max_mana)

func update_sprite_direction():
	if not sprite:
		return
	if input_vector.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = input_vector.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if input_vector.x > 0 else 1

func take_damage(amount: float):
	# CHEAT: God mode / Invincible HP check
	if god_mode or invincible_hp:
		print("💫 Damage blocked by god mode/invincible HP")
		return

	# Track damage taken
	track_damage_taken(int(amount))

	current_hp -= amount
	hp_changed.emit(current_hp, stats.max_hp)

	# ← AUDIO: Play hurt sound
	AudioManager.play_sfx("player_hurt")

	# ← THÊM: Camera shake when hit
	CameraShake.shake(6.0, 0.2)

	# Camera shake when hit (old method - kept for compatibility)
	if camera and camera.has_method("small_shake"):
		camera.small_shake()

	# Visual feedback
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color.WHITE

	if current_hp <= 0:
		die()

func die():
	player_died.emit()
	set_physics_process(false)
	sprite.modulate = Color(0.5, 0.5, 0.5)

	# ← AUDIO: Play game over music
	AudioManager.play_music("game_over", 1.0)

	# Camera shake on death
	if camera and camera.has_method("large_shake"):
		camera.large_shake()

	# Collect game stats
	var stats_data = {
		"time": get_game_time(),
		"kills": total_kills,
		"level": level,
		"gold": total_gold,
		"wave": highest_wave,
		"bosses": defeated_bosses,
		"damage_dealt": total_damage_dealt,
		"damage_taken": total_damage_taken,
		"xp": total_xp_gained,
		"weapons": weapons_used,
		"biome": current_biome
	}

	# Show game over screen
	var game_over = load("res://scenes/ui/game_over_screen.tscn").instantiate()
	game_over.set_stats(stats_data)
	get_tree().root.add_child(game_over)

func add_xp(amount: float):
	current_xp += amount
	xp_gained.emit(amount)  # ← THÊM emit để UI update
	track_xp_gained(int(amount))  # Track total XP

	# ← AUDIO: Play XP collect sound
	AudioManager.play_sfx("xp_collect")

	print("Gained ", amount, " XP! Total: ", current_xp, "/", xp_to_next_level)
	
	# Update xp_to_next_level cho lần đầu
	xp_to_next_level = get_xp_for_next_level()
	
	# Level up loop
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		level += 1

		# Recalculate for next level
		xp_to_next_level = get_xp_for_next_level()

		print("🎉 ========== LEVEL UP! ==========")
		print("📊 New Level: ", level)
		print("🎯 Next Level XP Required: ", xp_to_next_level)

		# Emit level up signal
		level_up.emit(level)

		# ← AUDIO: Play level up sound
		AudioManager.play_sfx("level_up")

		# ← THÊM: Level up particle effect and camera shake
		ParticleManager.create_level_up_effect(global_position)
		CameraShake.shake(8.0, 0.3)

		# Small heal on level up
		current_hp = min(current_hp + 20, stats.max_hp)
		hp_changed.emit(current_hp, stats.max_hp)

		# Spawn level up particles
		spawn_levelup_particle()

		# Camera shake on level up
		if camera and camera.has_method("medium_shake"):
			camera.medium_shake()

		# Show upgrade menu (SINGLE CALL)
		show_level_up_menu()

func spawn_levelup_particle():
	if not levelup_particle_scene:
		print("WARNING: Level up particle scene not loaded!")
		return
	
	var particle = levelup_particle_scene.instantiate()
	particle.global_position = global_position
	
	# Add to scene root
	get_tree().root.add_child(particle)
	
	print("✨ Level up particle spawned!")


func get_xp_for_next_level() -> float:
	return 100.0 * pow(level, 1.5)

func show_level_up_menu():
	print("📜 Attempting to show upgrade menu...")

	if not upgrade_menu:
		print("❌ ERROR: upgrade_menu is null!")
		print("❌ Cannot show upgrade menu")
		get_tree().paused = false
		return

	if not upgrade_menu.has_method("show_menu"):
		print("❌ ERROR: upgrade_menu has no show_menu method!")
		get_tree().paused = false
		return

	print("✅ Calling upgrade_menu.show_menu()")
	upgrade_menu.show_menu(self, level)
	print("✅ Upgrade menu should now be visible")
"""
func use_special_skill():
	if current_weapon and current_mana >= current_weapon.mana_cost:
		current_mana -= current_weapon.mana_cost
		current_weapon.special_attack()
		mana_changed.emit(current_mana, stats.max_mana)
"""

func apply_kiku_buffs():
	kiku_active = true
	kiku_buffs = {
		"attack_speed": 1.3,
		"hp_regen": 1.2,
		"crit_chance": 0.1,
		"move_speed": 1.15
	}

func remove_kiku_buffs():
	kiku_active = false
	kiku_buffs = {
		"attack_speed": 1.0,
		"hp_regen": 1.0,
		"crit_chance": 0.0,
		"move_speed": 1.0
	}

func apply_permanent_upgrades():
	var save_data = SaveSystem.load_game()
	stats.max_hp = 100 + (save_data.player.permanent_hp_upgrades * 50)
	stats.lucky = 1.0 + (save_data.player.permanent_luck_upgrades * 0.3)
	stats.max_mana = 50 + ((save_data.player.total_kills / 100000) * 25)

	current_hp = stats.max_hp
	current_mana = stats.max_mana


# === SPECIAL ITEMS SYSTEM (for Kiku Quest) ===

func has_item(item_name: String) -> bool:
	"""Check if player has a special item"""
	if item_name == "Kiku's Seal Key":
		return has_kiku_seal_key
	return special_items.get(item_name, false)


func add_special_item(item_name: String) -> void:
	"""Add a special item to player's inventory"""
	special_items[item_name] = true

	if item_name == "Kiku's Seal Key":
		has_kiku_seal_key = true
		print("✓ Player obtained: Kiku's Seal Key")


func add_item(item_name: String) -> void:
	"""Fallback method for adding items"""
	add_special_item(item_name)


func apply_permanent_kiku_buffs() -> void:
	"""Apply permanent buffs from Permanent Kiku pet"""
	# +10% luck (better drops)
	if stats.has("lucky"):
		stats.lucky *= 1.1

	# +0.2 HP/s regen
	if stats.has("hp_regen_per_second"):
		stats.hp_regen_per_second += 0.2

	print("✓ Permanent Kiku buffs applied: +10% luck, +0.2 HP/s regen")


# === INPUT CONTROL (for cutscenes) ===

var input_disabled: bool = false

func disable_input() -> void:
	"""Disable player input (for cutscenes)"""
	input_disabled = true
	velocity = Vector2.ZERO


func enable_input() -> void:
	"""Re-enable player input"""
	input_disabled = false


func get_hp_percent() -> float:
	"""Get current HP as percentage"""
	return current_hp / stats.max_hp

func equip_weapon(weapon: Weapon):
	# DEPRECATED: Use update_equipped_weapons() instead for multi-weapon support
	# This old method is kept for backwards compatibility but not recommended

	# Clear all existing weapons
	for w in equipped_weapons:
		if is_instance_valid(w):
			w.queue_free()
	equipped_weapons.clear()

	# Add single weapon
	weapon_pivot.add_child(weapon)
	equipped_weapons.append(weapon)

	print("⚠️ equip_weapon() is deprecated - use update_equipped_weapons() instead")


func get_equipped_weapons() -> Array:
	"""Get list of currently equipped weapon names (for Dark Kiku mirroring)"""
	var weapon_names: Array = []

	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			if "weapon_name" in weapon:
				weapon_names.append(weapon.weapon_name)
			elif "name" in weapon:
				weapon_names.append(weapon.name)

	return weapon_names


func calculate_damage(base_damage: float) -> float:
	var damage = base_damage

	# Apply damage buff multiplier
	damage *= buff_damage_multiplier

	# Crit check
	var crit_chance = stats.crit_chance + kiku_buffs["crit_chance"]
	if randf() < crit_chance:
		damage *= stats.crit_multiplier
		show_crit_text(damage)

	# Random variance
	damage *= randf_range(0.9, 1.1)

	return damage

func show_crit_text(damage: float):
	# Spawn floating damage text with "CRIT!" indicator
	pass

# === GOLD SYSTEM ===
func add_gold(amount: int):
	gold += amount
	gold_changed.emit(gold)
	track_gold(amount)  # Track total gold earned
	print("💰 +", amount, " gold! Total: ", gold)

func remove_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		print("💰 -", amount, " gold! Remaining: ", gold)
		return true
	else:
		print("❌ Not enough gold! Need ", amount, " but have ", gold)
		return false

func has_gold(amount: int) -> bool:
	return gold >= amount

# === HEALING SYSTEM ===
func heal(amount: float):
	current_hp = min(current_hp + amount, stats.max_hp)
	hp_changed.emit(current_hp, stats.max_hp)
	print("💚 Healed ", amount, " HP")

# === MULTI-WEAPON SYSTEM (Phase 5.5.3) ===

func update_equipped_weapons(weapon_data: Array):
	"""
	Update player's equipped weapons from inventory data
	weapon_data format: [{slot_index, weapon_id, quantity, data}, ...]
	
	Behavior:
	- 1 weapon: Appears at player
	- 2 weapons: 180° apart
	- 3 weapons: 120° apart
	- Up to 9 weapons: All positioned in circle around player
	"""
	print("⚔️ Updating equipped weapons: %d weapons" % weapon_data.size())
	
	# Clear existing weapons
	for weapon in equipped_weapons:
		if is_instance_valid(weapon):
			weapon.queue_free()
	equipped_weapons.clear()
	
	# Early exit if no weapons
	if weapon_data.is_empty():
		print("  → No weapons equipped")
		return
	
	# Spawn weapons from inventory data
	var weapon_count = weapon_data.size()
	
	for i in range(weapon_count):
		var data = weapon_data[i]
		var weapon_scene = load_weapon_scene(data.weapon_id)
		
		if not weapon_scene:
			print("  ⚠️ Failed to load weapon: %s" % data.weapon_id)
			continue
		
		var weapon = weapon_scene.instantiate()
		
		# Position in circle around player
		var angle = (TAU / weapon_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 40.0
		weapon.position = offset
		
		# Add to weapon pivot
		if weapon_pivot:
			weapon_pivot.add_child(weapon)
			equipped_weapons.append(weapon)
			print("  → Equipped: %s at angle %.1f°" % [data.weapon_id, rad_to_deg(angle)])
	
	print("✅ Total equipped weapons: %d" % equipped_weapons.size())

func load_weapon_scene(weapon_id: String) -> PackedScene:
	"""
	Load weapon scene by weapon_id
	Phase 6: Complete Weapon System (8 weapons)
	"""
	match weapon_id:
		"wooden_sword":
			return load("res://scenes/weapons/WoodenSword.tscn")
		"kiku_sword":
			return load("res://scenes/weapons/KikuSword.tscn")
		"earthshatter_staff":
			return load("res://scenes/weapons/EarthshatterStaff.tscn")
		"acid_gauntlets":
			return load("res://scenes/weapons/AcidGauntlets.tscn")
		"enchanting_flute":
			return load("res://scenes/weapons/EnchantingFlute.tscn")
		"shadow_daggers":
			return load("res://scenes/weapons/ShadowDaggers.tscn")
		"frost_bow":
			return load("res://scenes/weapons/FrostBow.tscn")
		"lightning_chain":
			return load("res://scenes/weapons/LightningChain.tscn")
		"bow":
			return load("res://scenes/weapons/Bow.tscn")  # Legacy
		_:
			print("⚠️ Unknown weapon_id: %s, using Wooden Sword" % weapon_id)
			return load("res://scenes/weapons/WoodenSword.tscn")  # Default fallback


# === MOBILE CONTROLS SUPPORT ===

func set_mobile_input(direction: Vector2) -> void:
	"""Set mobile input direction from virtual joystick"""
	mobile_input_vector = direction


func use_kiku_blessing() -> void:
	"""Activate Kiku's Blessing special skill (mobile skill button)"""
	if kiku_active:
		print("Kiku's Blessing already active!")
		return

	# Apply Kiku buffs
	apply_kiku_buffs()

	# Visual feedback
	if sprite:
		sprite.modulate = Color(0, 0.85, 1)  # Cyan glow
		await get_tree().create_timer(0.5).timeout
		sprite.modulate = Color.WHITE

	# Camera effect
	CameraShake.shake(5.0, 0.2)

	print("Kiku's Blessing activated!")
	print("  +30% Attack Speed")
	print("  +20% HP Regen")
	print("  +10% Crit Chance")
	print("  +15% Move Speed")

	# Auto-remove after 30 seconds
	await get_tree().create_timer(30.0).timeout
	remove_kiku_buffs()
	print("Kiku's Blessing expired!")

# === STATS TRACKING FUNCTIONS ===

func get_game_time() -> float:
	"""Get elapsed game time in seconds"""
	return (Time.get_ticks_msec() / 1000.0) - game_start_time

func add_kill():
	"""Track enemy kill"""
	total_kills += 1

func track_gold(amount: int):
	"""Track total gold earned (called when gold is picked up)"""
	total_gold += amount

func track_damage_dealt(amount: int):
	"""Track total damage dealt to enemies"""
	total_damage_dealt += amount

func track_damage_taken(amount: int):
	"""Track total damage taken"""
	total_damage_taken += amount

func track_xp_gained(amount: int):
	"""Track total XP gained"""
	total_xp_gained += amount

func defeat_boss(boss_name: String):
	"""Track boss defeated"""
	if not boss_name in defeated_bosses:
		defeated_bosses.append(boss_name)
		print("Boss defeated: ", boss_name)

func track_weapon_used(weapon_name: String):
	"""Track weapon usage"""
	if not weapon_name in weapons_used:
		weapons_used.append(weapon_name)
		print("New weapon tracked: ", weapon_name)

func set_current_biome(biome_name: String):
	"""Update current biome"""
	current_biome = biome_name
	print("Current biome: ", biome_name)

func set_highest_wave(wave: int):
	"""Update highest wave reached"""
	if wave > highest_wave:
		highest_wave = wave
