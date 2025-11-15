extends Enemy
class_name IceGolem

# Ice Golem specific mechanics
var grab_cooldown: float = 12.0
var grab_timer: float = 0.0
var grab_damage: float = 20.0
var grab_range: float = 50.0

var snowball_cooldown: float = 6.0
var snowball_timer: float = 0.0
var snowball_damage: float = 15.0
var snowball_range: float = 300.0

var is_fleeing: bool = false
var flee_timer: float = 0.0
var flee_duration: float = 5.0
var flee_speed: float = 70.0
var base_speed: float = 35.0

# Projectile scene
var snowball_scene: PackedScene

func _ready():
	# Override base stats
	max_hp = 150.0
	current_hp = max_hp
	damage = 20.0
	move_speed = base_speed
	xp_reward = 40.0
	detection_range = 400.0
	attack_range = 50.0
	attack_cooldown = 2.0

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Load projectile scene
	snowball_scene = preload("res://scenes/projectiles/snowball.tscn")

	print("Ice Golem spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if grab_timer > 0:
		grab_timer -= delta
	if snowball_timer > 0:
		snowball_timer -= delta

	# Handle fleeing state
	if is_fleeing:
		handle_flee(delta)
		return

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func handle_flee(delta):
	flee_timer -= delta

	if not player or flee_timer <= 0:
		exit_flee_state()
		return

	# Run away from player
	var flee_direction = (global_position - player.global_position).normalized()
	velocity = flee_direction * flee_speed
	move_and_slide()

	print("Ice Golem fleeing...")

func exit_flee_state():
	is_fleeing = false
	flee_timer = 0.0
	move_speed = base_speed

	# Remove green tint
	if sprite:
		sprite.modulate = Color(0.7, 0.9, 1.0)

	current_state = State.IDLE
	print("Ice Golem stopped fleeing")

func enter_flee_state():
	is_fleeing = true
	flee_timer = flee_duration
	move_speed = flee_speed

	# Add green tint
	if sprite:
		sprite.modulate = Color(0.5, 1.0, 0.7)

	print("Ice Golem FLEEING!")

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Try grab attack
	if grab_timer <= 0 and distance <= grab_range:
		grab_and_throw()
		return

	# Try snowball attack
	if snowball_timer <= 0 and distance > grab_range and distance <= snowball_range:
		throw_snowball()
		return

	# Move closer if in detection range
	if distance > attack_range:
		current_state = State.CHASE
	else:
		velocity = Vector2.ZERO

func grab_and_throw():
	if not player or not player.has_method("take_damage"):
		return

	print("Ice Golem GRAB AND THROW!")

	# Damage
	player.take_damage(grab_damage)

	# Knockback
	var throw_direction = (player.global_position - global_position).normalized()
	if player.has_method("apply_knockback"):
		player.apply_knockback(throw_direction * 200.0)

	# Stun player
	if player.has_method("apply_effect"):
		player.apply_effect("stun", 0.5)

	grab_timer = grab_cooldown

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.5, 0.3)

	# Particle effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_hit_effect(player.global_position)

func throw_snowball():
	if not player or not snowball_scene:
		return

	var projectile = snowball_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 180.0
	projectile.damage = snowball_damage
	projectile.apply_slow = true
	projectile.slow_amount = 0.4
	projectile.slow_duration = 3.0

	get_parent().add_child(projectile)

	snowball_timer = snowball_cooldown
	print("Ice Golem threw snowball!")

# Special handling for Enchanting Flute charm
func on_charmed(weapon_name: String):
	if weapon_name == "EnchantingFlute":
		print("Ice Golem charmed by Enchanting Flute!")

		# Lose 50% current HP
		var hp_loss = current_hp * 0.5
		current_hp -= hp_loss

		# Visual feedback
		if sprite:
			sprite.modulate = Color.YELLOW
			await get_tree().create_timer(0.2).timeout

		# Enter flee state
		enter_flee_state()

		print("Ice Golem lost ", hp_loss, " HP (50% of current HP)!")

		if current_hp <= 0:
			die()

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			if is_fleeing:
				sprite.modulate = Color(0.5, 1.0, 0.7)
			else:
				sprite.modulate = Color(0.7, 0.9, 1.0)

	# Knockback (only if not fleeing)
	if from_position != Vector2.ZERO and not is_fleeing:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 120  # Slower knockback for heavy enemy

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	is_fleeing = false
	set_physics_process(false)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	# Death effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_death_effect(global_position)

	print("Ice Golem died")
