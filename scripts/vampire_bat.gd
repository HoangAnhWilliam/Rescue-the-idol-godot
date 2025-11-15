extends Enemy
class_name VampireBat

# Vampire Bat specific stats
var is_latched: bool = false
var latch_timer: float = 0.0
var latch_offset: Vector2 = Vector2.ZERO
var latch_duration: float = 5.0
var drain_rate: float = 5.0  # HP and Mana per second
var drain_timer: float = 0.0
var original_player_speed: float = 0.0

func _ready():
	# Override base stats
	max_hp = 20.0
	current_hp = max_hp
	damage = 3.0
	move_speed = 70.0
	xp_reward = 10.0
	detection_range = 350.0
	attack_range = 80.0
	attack_cooldown = 1.0

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	print("Vampire Bat spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta

	# Handle latched state
	if is_latched:
		handle_latch(delta)
		return

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func handle_latch(delta):
	if not player or not is_instance_valid(player):
		detach()
		return

	# Follow player with offset
	global_position = player.global_position + latch_offset

	# Countdown latch timer
	latch_timer -= delta
	if latch_timer <= 0:
		detach()
		return

	# Drain HP and Mana
	drain_timer -= delta
	if drain_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(drain_rate)

		# Drain mana if player has it
		if player.has_method("drain_mana"):
			player.drain_mana(drain_rate)

		drain_timer = 1.0  # Drain every second
		print("Vampire Bat draining: ", drain_rate, " HP/Mana per second")

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return

	# Attempt to latch
	if attack_timer <= 0 and not is_latched:
		latch_to_player()

func latch_to_player():
	if not player:
		return

	is_latched = true
	latch_timer = latch_duration
	drain_timer = 0.0  # Immediate first drain

	# Random offset around player
	var angle = randf() * TAU
	latch_offset = Vector2(cos(angle), sin(angle)) * 20.0

	# Apply slow to player
	if player.has_method("apply_slow"):
		player.apply_slow(0.3, latch_duration)  # 30% slow

	print("Vampire Bat latched to player!")

func detach():
	is_latched = false
	latch_timer = 0.0
	current_state = State.CHASE
	print("Vampire Bat detached")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color(0.3, 0.1, 0.4)  # Dark purple

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 200

	# Detach if hit while latched
	if is_latched:
		detach()

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	is_latched = false
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

	print("Vampire Bat died")
