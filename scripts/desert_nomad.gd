extends Enemy
class_name DesertNomad

# Desert Nomad specific mechanics
var has_cloned: bool = false
var is_clone: bool = false
var clone_lifetime: float = 15.0
var clone_timer: float = 0.0

var fireball_cooldown: float = 8.0
var fireball_timer: float = 0.0
var fireball_damage: float = 15.0
var fireball_range: float = 350.0
var low_hp_threshold: float = 0.3

# Projectile scene
var fireball_scene: PackedScene

func _ready():
	# Override base stats
	if is_clone:
		max_hp = 15.0
		damage = 5.0
		xp_reward = 0.0  # Clones don't give XP
	else:
		max_hp = 50.0
		damage = 12.0
		xp_reward = 30.0

	current_hp = max_hp
	move_speed = 55.0
	detection_range = 400.0
	attack_range = 50.0
	attack_cooldown = 1.2

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Load projectile scene
	fireball_scene = preload("res://scenes/projectiles/fireball.tscn")

	# Visual transparency for clones
	if is_clone and sprite:
		sprite.modulate.a = 0.7
		clone_timer = clone_lifetime

	print("Desert Nomad spawned (Clone: ", is_clone, ") at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if fireball_timer > 0:
		fireball_timer -= delta

	# Handle clone lifetime
	if is_clone:
		clone_timer -= delta
		if clone_timer <= 0:
			print("Desert Nomad clone expired")
			die()
			return

	# Create clones on first player encounter (real nomad only)
	if not has_cloned and not is_clone and player:
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_range:
			create_clones()
			has_cloned = true

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func create_clones():
	print("Desert Nomad creating clones!")

	for i in range(2):
		var clone_instance = load("res://scenes/enemies/desert_nomad.tscn").instantiate()
		var clone_script = clone_instance.get_script()

		# Set clone flag before adding to tree
		clone_instance.is_clone = true

		# Position offset from main body
		var angle = (TAU / 2.0) * i + randf_range(-0.3, 0.3)
		var offset = Vector2(cos(angle), sin(angle)) * 60.0
		clone_instance.global_position = global_position + offset

		get_parent().add_child(clone_instance)

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Check if should use fireball barrage (low HP)
	var hp_percent = current_hp / max_hp
	if hp_percent < low_hp_threshold and fireball_timer <= 0 and not is_clone:
		fireball_barrage()
		return

	# Regular fireball at range
	if distance > attack_range and distance <= fireball_range and fireball_timer <= 0:
		shoot_fireball()
		return

	# Melee attack
	if distance <= attack_range:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				attack_timer = attack_cooldown
	else:
		current_state = State.CHASE

func shoot_fireball():
	if not player or not fireball_scene:
		return

	var projectile = fireball_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 250.0
	projectile.damage = fireball_damage

	get_parent().add_child(projectile)

	fireball_timer = fireball_cooldown if not is_clone else fireball_cooldown * 0.5
	print("Desert Nomad shot fireball!")

func fireball_barrage():
	if not player or not fireball_scene:
		return

	print("Desert Nomad FIREBALL BARRAGE!")

	# Shoot 3 fireballs in spread pattern
	var base_direction = (player.global_position - global_position).normalized()
	var angles = [-15.0, 0.0, 15.0]  # Degrees

	for angle_deg in angles:
		var angle_rad = deg_to_rad(angle_deg)
		var rotated_dir = base_direction.rotated(angle_rad)

		var projectile = fireball_scene.instantiate()
		projectile.global_position = global_position
		projectile.direction = rotated_dir
		projectile.speed = 250.0
		projectile.damage = fireball_damage

		get_parent().add_child(projectile)

	fireball_timer = fireball_cooldown

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.4, 0.3)

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color(0.6, 0.5, 0.3)
			if is_clone:
				sprite.modulate.a = 0.7

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 180

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	set_physics_process(false)

	# Drop XP (only real nomad)
	if not is_clone and player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	if is_clone:
		print("Desert Nomad clone died")
	else:
		print("Desert Nomad (real) died")
