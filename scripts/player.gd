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

# Combat
var current_weapon: Weapon = null
var attack_cooldown: float = 0.0

# Buffs
var miku_active: bool = false
var miku_buffs := {
	"attack_speed": 1.0,
	"hp_regen": 1.0,
	"crit_chance": 0.0,
	"move_speed": 1.0
}

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

	if weapon_pivot and weapon_pivot.get_child_count() > 0:
		current_weapon = weapon_pivot.get_child(0)
		print("Player equipped weapon: ", current_weapon.name)

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
	# DEBUG: Press PageUp to manually test upgrade menu
	if Input.is_action_just_pressed("ui_page_up"):
		print("")
		print("🔧 ========== DEBUG TRIGGER ==========")
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

	# Special skill
	#if Input.is_action_just_pressed("special_skill"):
	#	use_special_skill()

func apply_movement(delta):
	var speed = stats.move_speed * miku_buffs["move_speed"] * buff_speed_multiplier
	velocity = input_vector * speed
	move_and_slide()

	if input_vector != Vector2.ZERO:
		last_direction = input_vector

func handle_weapon(delta):
	if not current_weapon:
		return
	
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		var attack_rate = stats.attack_speed * miku_buffs["attack_speed"]
		attack_cooldown = 1.0 / attack_rate
		
		var target = find_closest_enemy()
		if target:
			current_weapon.attack(target.global_position)

func find_closest_enemy() -> Enemy:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var closest: Enemy = null
	var min_distance := INF
	
	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance and distance < current_weapon.range:
			closest = enemy
			min_distance = distance
	
	return closest

func regenerate(delta):
	# HP regeneration
	if current_hp < stats.max_hp:
		var regen = stats.hp_regen_per_second * miku_buffs["hp_regen"] * delta
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
	current_hp -= amount
	hp_changed.emit(current_hp, stats.max_hp)
	
	# Camera shake when hit
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
	
	# Camera shake on death
	if camera and camera.has_method("large_shake"):
		camera.large_shake()
	
	# Show game over screen

func add_xp(amount: float):
	current_xp += amount
	xp_gained.emit(amount)  # ← THÊM emit để UI update
	
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

func apply_miku_buffs():
	miku_active = true
	miku_buffs = {
		"attack_speed": 1.3,
		"hp_regen": 1.2,
		"crit_chance": 0.1,
		"move_speed": 1.15
	}

func remove_miku_buffs():
	miku_active = false
	miku_buffs = {
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

func equip_weapon(weapon: Weapon):
	if current_weapon:
		current_weapon.queue_free()
	
	current_weapon = weapon
	weapon_pivot.add_child(weapon)

func calculate_damage(base_damage: float) -> float:
	var damage = base_damage

	# Apply damage buff multiplier
	damage *= buff_damage_multiplier

	# Crit check
	var crit_chance = stats.crit_chance + miku_buffs["crit_chance"]
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
