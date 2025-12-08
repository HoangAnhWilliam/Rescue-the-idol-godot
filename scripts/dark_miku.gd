extends Enemy
class_name DarkMiku

# Dark Miku specific mechanics - Anti-Miku mini-boss
var current_mirrored_weapon: String = "DarkBlast"
var weapon_switch_timer: float = 15.0
var weapon_switch_time: float = 0.0
var available_weapons: Array[String] = []

var web_cooldown: float = 12.0
var web_timer: float = 0.0
var web_damage: float = 15.0
var is_tethered: bool = false
var tether_timer: float = 0.0
var tether_duration: float = 4.0
var tether_max_distance: float = 400.0
var tether_slow_amount: float = 0.5

var dash_cooldown: float = 10.0
var dash_timer: float = 0.0
var dash_damage: float = 25.0
var backstab_distance: float = 80.0

var despair_aura_active: bool = false
var despair_heal_rate: float = 10.0  # HP per second
var despair_heal_timer: float = 0.0

# Projectile scenes
var blood_web_scene: PackedScene
var tether_line: Line2D = null

func _ready():
	# Override base stats - Mini-boss tier (COMPLETE QUEST VERSION)
	max_hp = 300.0  # Full mini-boss HP
	current_hp = max_hp
	damage = 15.0  # Base weapon damage
	move_speed = 65.0
	xp_reward = 200.0  # Higher XP reward
	detection_range = 500.0
	attack_range = 100.0  # Varies by weapon
	attack_cooldown = 1.2

	add_to_group("enemies")
	add_to_group("dark_miku")  # Special group for quest tracking

	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Load projectile scene
	blood_web_scene = preload("res://scenes/projectiles/blood_web.tscn")

	# Setup tether line
	tether_line = Line2D.new()
	tether_line.width = 3.0
	tether_line.default_color = Color.RED
	tether_line.visible = false
	add_child(tether_line)

	# Chat messages (boss introduction)
	ChatBox.send_chat_message("System", "⚠️ Dark Miku has appeared!", "System", get_tree())
	ChatBox.send_chat_message("Dark Miku", "Have you come to kill me?", "DarkMiku", get_tree())

	print("Dark Miku spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if web_timer > 0:
		web_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta
	if weapon_switch_time > 0:
		weapon_switch_time -= delta

	# Weapon switching
	if weapon_switch_time <= 0:
		mirror_player_weapon()
		weapon_switch_time = weapon_switch_timer

	# Handle tether
	if is_tethered:
		handle_tether(delta)

	# Check despair aura
	check_despair_aura(delta)

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func mirror_player_weapon():
	if not player:
		current_mirrored_weapon = "DarkBlast"
		return

	# Get player's equipped weapons
	available_weapons.clear()

	if player.has_method("get_equipped_weapons"):
		var weapons = player.get_equipped_weapons()
		if weapons and weapons.size() > 0:
			# Convert to Array[String] to fix type mismatch
			for weapon in weapons:
				if weapon is String:
					available_weapons.append(weapon)
				elif weapon is Node and weapon.has_method("get_name"):
					available_weapons.append(weapon.get_name())
				else:
					available_weapons.append(str(weapon))

	# If no weapons found, use default
	if available_weapons.is_empty():
		current_mirrored_weapon = "DarkBlast"
		print("Dark Miku mirroring: DarkBlast (default)")
		return

	# Pick random weapon
	current_mirrored_weapon = available_weapons.pick_random()
	print("Dark Miku mirroring weapon: ", current_mirrored_weapon)

func handle_tether(delta):
	tether_timer -= delta

	if not player or tether_timer <= 0:
		break_tether()
		return

	# Check distance
	var distance = global_position.distance_to(player.global_position)
	if distance > tether_max_distance:
		print("Blood web tether broken (distance)")
		break_tether()
		return

	# Update tether line
	if tether_line:
		tether_line.clear_points()
		tether_line.add_point(Vector2.ZERO)
		tether_line.add_point(to_local(player.global_position))
		tether_line.visible = true

	# Apply slow to player moving away
	if player.has_method("apply_slow"):
		# Check if player is moving away
		var direction_to_player = (player.global_position - global_position).normalized()
		var player_velocity = Vector2.ZERO
		if player.has_method("get_velocity"):
			player_velocity = player.get_velocity()

		# If player moving away, slow them
		if player_velocity.dot(direction_to_player) > 0:
			player.apply_slow(tether_slow_amount, 0.2)

func break_tether():
	is_tethered = false
	tether_timer = 0.0

	if tether_line:
		tether_line.visible = false
		tether_line.clear_points()

func check_despair_aura(delta):
	if not player:
		despair_aura_active = false
		return

	# Check if player HP < 30%
	var player_hp_percent = 1.0
	if player.has_method("get_current_hp") and player.has_method("get_max_hp"):
		player_hp_percent = player.get_current_hp() / player.get_max_hp()

	if player_hp_percent < 0.3:
		if not despair_aura_active:
			print("Dark Miku DESPAIR AURA activated!")
			despair_aura_active = true

		# Heal Dark Miku
		despair_heal_timer -= delta
		if despair_heal_timer <= 0:
			current_hp = min(current_hp + despair_heal_rate, max_hp)
			despair_heal_timer = 1.0  # Heal every second
			print("Dark Miku healing from despair: ", despair_heal_rate, " HP")

			# Visual: Red particles flowing player -> Dark Miku
			if has_node("/root/ParticleManager"):
				get_node("/root/ParticleManager").create_hit_effect(global_position)
	else:
		despair_aura_active = false

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Shadow dash (teleport backstab)
	if dash_timer <= 0 and distance > 150.0 and distance < 400.0:
		shadow_dash()
		return

	# Blood web
	if web_timer <= 0 and distance > 100.0 and distance <= 350.0 and not is_tethered:
		shoot_blood_web()
		return

	# Attack with mirrored weapon
	if attack_timer <= 0:
		attack_with_mirrored_weapon()

	# Move closer if too far
	if distance > attack_range:
		current_state = State.CHASE
	else:
		velocity = Vector2.ZERO

func shadow_dash():
	if not player:
		return

	print("Dark Miku SHADOW DASH!")

	# Teleport behind player (180 degrees from facing)
	var player_facing = Vector2.RIGHT  # Default
	if player.has_method("get_facing_direction"):
		player_facing = player.get_facing_direction()

	var behind_offset = -player_facing.normalized() * backstab_distance
	global_position = player.global_position + behind_offset

	# Immediate backstab attack
	if player.has_method("take_damage"):
		player.take_damage(dash_damage)
		print("Shadow dash backstab: ", dash_damage, " damage!")

	dash_timer = dash_cooldown

	# Visual effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_hit_effect(global_position)

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.4, 0.3)

func shoot_blood_web():
	if not player or not blood_web_scene:
		return

	print("Dark Miku shooting BLOOD WEB!")

	var projectile = blood_web_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 250.0
	projectile.damage = web_damage
	projectile.caster = self  # Reference for tether callback

	get_parent().add_child(projectile)

	web_timer = web_cooldown

func on_web_hit():
	# Called by blood web projectile when it hits player
	is_tethered = true
	tether_timer = tether_duration
	print("Blood web tether connected!")

func attack_with_mirrored_weapon():
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# Simulate weapon attacks based on mirrored weapon
	match current_mirrored_weapon:
		"WoodenSword", "MikuSword":
			# Melee attack
			if distance <= 60.0:
				if player.has_method("take_damage"):
					player.take_damage(damage)
					attack_timer = attack_cooldown

		"FrostBow", "FireBow":
			# Ranged arrow attack
			if distance <= 300.0:
				shoot_projectile_attack()
				attack_timer = attack_cooldown * 1.5

		"EnchantingFlute":
			# Charm attempt (doesn't work on player, just melee)
			if distance <= 60.0:
				if player.has_method("take_damage"):
					player.take_damage(damage)
					attack_timer = attack_cooldown

		"DarkBlast", _:
			# Default dark energy blast
			if distance <= 200.0:
				shoot_dark_blast()
				attack_timer = attack_cooldown

func shoot_projectile_attack():
	# Generic projectile attack
	var projectile_scene = preload("res://scenes/projectiles/fireball.tscn")
	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 220.0
	projectile.damage = damage

	get_parent().add_child(projectile)

func shoot_dark_blast():
	# Dark energy blast
	var projectile_scene = preload("res://scenes/projectiles/fireball.tscn")
	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 200.0
	projectile.damage = 12.0

	# Dark visual (will be purple in scene)
	get_parent().add_child(projectile)

	print("Dark Miku used Dark Blast!")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color(0.1, 0.0, 0.0)

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 150

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	is_tethered = false
	despair_aura_active = false
	set_physics_process(false)

	# Chat messages (death dialogue)
	ChatBox.send_chat_message("Dark Miku", "No... I have been defeated...", "DarkMiku", get_tree())

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Hide tether
	if tether_line:
		tether_line.visible = false

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		await tween.finished

	# Death effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_death_effect(global_position)

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.8, 0.5)

	# ★ DROP MIKU'S SEAL KEY ★
	drop_seal_key()

	# Chat notification about key
	ChatBox.send_chat_message("System", "You obtained Miku's Seal Key!", "System", get_tree())

	print("Dark Miku defeated! Key dropped.")

	queue_free()


# ============ KEY DROP ============

func drop_seal_key() -> void:
	"""Add Miku's Seal Key to player inventory"""

	if not player:
		return

	# Try different methods to add the key
	if player.has_method("add_special_item"):
		player.add_special_item("Miku's Seal Key")
	elif player.has_method("add_item"):
		player.add_item("Miku's Seal Key")
	elif player.has_method("set"):
		# Fallback: Set a property
		player.set("has_miku_seal_key", true)

	print("✓ Miku's Seal Key added to player inventory")
