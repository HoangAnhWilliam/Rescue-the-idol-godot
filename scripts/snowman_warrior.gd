extends Enemy
class_name SnowmanWarrior

# Snowman Warrior specific mechanics
var dash_cooldown: float = 8.0
var dash_timer: float = 0.0
var dash_damage: float = 12.0
var dash_distance: float = 150.0
var is_dashing: bool = false
var dash_duration: float = 0.3
var dash_time: float = 0.0
var dash_start_pos: Vector2 = Vector2.ZERO
var dash_target_pos: Vector2 = Vector2.ZERO

var aura_radius: float = 80.0
var aura_slow_amount: float = 0.2
var is_player_in_aura: bool = false

func _ready():
	# Override base stats
	max_hp = 60.0
	current_hp = max_hp
	damage = 8.0
	move_speed = 60.0
	xp_reward = 20.0
	detection_range = 380.0
	attack_range = 45.0
	attack_cooldown = 0.66  # Fast dual dagger attacks

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	print("Snowman Warrior spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if dash_timer > 0:
		dash_timer -= delta

	# Handle dashing
	if is_dashing:
		handle_dash(delta)
		return

	# Check freeze aura
	check_freeze_aura()

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func check_freeze_aura():
	if not player:
		is_player_in_aura = false
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= aura_radius:
		if not is_player_in_aura:
			# Player entered aura
			is_player_in_aura = true
			if player.has_method("apply_slow"):
				player.apply_slow(aura_slow_amount, 0.5)  # Reapply every 0.5s
	else:
		is_player_in_aura = false

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Try dash attack
	if dash_timer <= 0 and distance > attack_range and distance < 200.0:
		start_dash()
		return

	# Dual dagger combo attack
	if distance <= attack_range:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			dual_dagger_attack()
	else:
		current_state = State.CHASE

func dual_dagger_attack():
	if not player or not player.has_method("take_damage"):
		return

	# First hit
	player.take_damage(damage)

	# Small delay for second hit
	await get_tree().create_timer(0.1).timeout

	# Second hit
	if player and player.has_method("take_damage"):
		player.take_damage(damage)

	attack_timer = attack_cooldown
	print("Snowman Warrior dual dagger combo: ", damage * 2, " total damage!")

func start_dash():
	if not player:
		return

	is_dashing = true
	dash_time = 0.0
	dash_start_pos = global_position
	dash_target_pos = player.global_position

	print("Snowman Warrior ICE DASH!")

func handle_dash(delta):
	dash_time += delta

	if dash_time >= dash_duration:
		is_dashing = false
		dash_timer = dash_cooldown
		current_state = State.CHASE
		return

	# Linear interpolation
	var t = dash_time / dash_duration
	global_position = dash_start_pos.lerp(dash_target_pos, t)

	# Check for player hit
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < 30.0:  # Hit radius
			if player.has_method("take_damage"):
				player.take_damage(dash_damage)
				print("Snowman Warrior dash hit: ", dash_damage, " damage!")

			is_dashing = false
			dash_timer = dash_cooldown

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color(0.95, 0.95, 1.0)

	# Knockback (only if not dashing)
	if from_position != Vector2.ZERO and not is_dashing:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 180

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	is_dashing = false
	set_physics_process(false)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	print("Snowman Warrior died")
