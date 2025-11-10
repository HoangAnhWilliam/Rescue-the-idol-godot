extends CharacterBody2D
class_name MagmaSlime

# Stats - MINI-BOSS stats (3x stronger than zombie)
@export var max_hp: float = 100.0  # 3x zombie (30)
@export var damage: float = 15.0  # 3x zombie (5)
@export var move_speed: float = 80.0  # Slower than zombie (100)
@export var xp_reward: float = 50.0  # 5x zombie (10)
@export var detection_range: float = 400.0
@export var jump_range: float = 200.0  # Range to trigger jump attack
@export var gold_drop_min: int = 50
@export var gold_drop_max: int = 150

# Jump mechanics
@export var jump_cooldown: float = 2.0
@export var jump_height: float = 150.0  # Arc height
@export var jump_speed: float = 300.0  # Horizontal speed during jump
@export var jump_damage: float = 25.0  # Landing damage
@export var jump_radius: float = 80.0  # Area damage radius
@export var knockback_force: float = 300.0

# State
var current_hp: float
var jump_timer: float = 0.0
var player: CharacterBody2D = null

# Jump state
var is_jumping: bool = false
var jump_start_pos: Vector2
var jump_target_pos: Vector2
var jump_progress: float = 0.0
var jump_duration: float = 1.0

# State machine
enum State { IDLE, CHASE, JUMP_PREPARE, JUMPING, LANDING, DEAD }
var current_state: State = State.IDLE

# References
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var damage_area = $DamageArea if has_node("DamageArea") else null
@onready var jump_timer_node = $JumpTimer if has_node("JumpTimer") else null

# Preload effects
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")

func _ready():
	print("🔥 Magma Slime spawned!")

	current_hp = max_hp
	add_to_group("enemies")

	# Setup jump timer
	if jump_timer_node:
		jump_timer_node.wait_time = jump_cooldown
		jump_timer_node.timeout.connect(_on_jump_timer_timeout)
	else:
		print("⚠️ JumpTimer not found, using manual timer")

	# Setup damage area (for landing damage)
	if damage_area:
		damage_area.monitoring = false  # Start disabled
		print("✓ Damage area configured")

	# Magma slime is orange-red
	if sprite:
		sprite.modulate = Color(1.0, 0.4, 0.1)  # Orange-red glow

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update timers
	if jump_timer > 0:
		jump_timer -= delta

	# State machine
	match current_state:
		State.IDLE:
			search_for_player()

		State.CHASE:
			chase_player(delta)

		State.JUMP_PREPARE:
			prepare_jump(delta)

		State.JUMPING:
			update_jump(delta)

		State.LANDING:
			handle_landing(delta)

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Don't detect invisible player
	if "is_invisible" in player and player.is_invisible:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.CHASE
		print("🔥 Magma Slime chasing player!")

func chase_player(delta):
	if not player:
		current_state = State.IDLE
		return

	# Stop chasing if player becomes invisible
	if "is_invisible" in player and player.is_invisible:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	# Too far - return to idle
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	# In jump range - prepare to jump!
	if distance < jump_range and jump_timer <= 0:
		start_jump()
		return

	# Move towards player (slower than zombies)
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update sprite direction
	update_sprite()

func start_jump():
	print("🔥 Magma Slime preparing to jump!")

	current_state = State.JUMP_PREPARE
	velocity = Vector2.ZERO

	# Store jump positions
	jump_start_pos = global_position
	jump_target_pos = player.global_position

	# Calculate jump duration based on distance
	var distance = jump_start_pos.distance_to(jump_target_pos)
	jump_duration = distance / jump_speed

	# Visual: Scale up before jump (charge up)
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.3)
		tween.tween_callback(execute_jump)

func execute_jump():
	print("🚀 Magma Slime JUMPING!")

	current_state = State.JUMPING
	is_jumping = true
	jump_progress = 0.0

	# Disable collision during jump
	if collision:
		collision.disabled = true

func prepare_jump(delta):
	# Wait for tween to finish (handled by tween callback)
	pass

func update_jump(delta):
	if not is_jumping:
		return

	# Update jump progress
	jump_progress += delta / jump_duration

	if jump_progress >= 1.0:
		# Jump complete - land!
		land()
		return

	# Calculate parabolic arc position
	# x: Linear interpolation
	var horizontal_pos = jump_start_pos.lerp(jump_target_pos, jump_progress)

	# y: Parabolic arc (quadratic ease)
	# Arc peaks at 0.5 progress, height = jump_height
	var arc_offset = -4 * jump_height * jump_progress * (jump_progress - 1)

	# Set position
	global_position = horizontal_pos + Vector2(0, -arc_offset)

	# Rotate during jump for visual effect
	if sprite:
		sprite.rotation = jump_progress * TAU * 2  # 2 full rotations

func land():
	print("💥 Magma Slime LANDING!")

	current_state = State.LANDING
	is_jumping = false
	jump_progress = 0.0

	# Snap to ground
	global_position = jump_target_pos

	# Re-enable collision
	if collision:
		collision.disabled = false

	# Visual: Squash on landing
	if sprite:
		sprite.rotation = 0  # Reset rotation
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.5, 0.5), 0.1)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)

	# Deal area damage
	deal_jump_damage()

	# Spawn shockwave visual effect
	spawn_shockwave()

	# Start jump cooldown
	jump_timer = jump_cooldown

	# Return to chase
	await get_tree().create_timer(0.3).timeout
	if current_state != State.DEAD:
		current_state = State.CHASE

func deal_jump_damage():
	print("💥 Checking for players in landing zone...")

	# Get all bodies near landing position
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	# Create circle shape for area check
	var shape = CircleShape2D.new()
	shape.radius = jump_radius
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # Layer 1 (player layer)

	var results = space_state.intersect_shape(query, 32)

	for result in results:
		var body = result["collider"]

		# Check if it's the player
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(jump_damage)
				print("💥 Jump damage dealt: %.1f" % jump_damage)

				# Apply knockback
				var knockback_dir = (body.global_position - global_position).normalized()
				if "velocity" in body:
					body.velocity = knockback_dir * knockback_force
				print("💨 Knockback applied!")

func spawn_shockwave():
	# Spawn 3 expanding rings for shockwave effect
	for i in range(3):
		await get_tree().create_timer(i * 0.1).timeout
		spawn_shockwave_ring(i)

func spawn_shockwave_ring(ring_index: int):
	# Create a visual ring effect (using ColorRect for now)
	var ring = ColorRect.new()
	ring.color = Color(1.0, 0.4, 0.1, 0.5)  # Semi-transparent orange
	ring.size = Vector2(10, 10)
	ring.position = global_position - ring.size / 2

	get_tree().root.add_child(ring)

	# Animate expansion and fade
	var tween = create_tween()
	var final_size = jump_radius * 2 * (ring_index + 1)
	tween.set_parallel(true)
	tween.tween_property(ring, "size", Vector2(final_size, final_size), 0.5)
	tween.tween_property(ring, "position", global_position - Vector2(final_size, final_size) / 2, 0.5)
	tween.tween_property(ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ring.queue_free)

func handle_landing(delta):
	# Wait for animation (handled by tween)
	pass

func _on_jump_timer_timeout():
	# Jump ready again
	print("✓ Jump cooldown ready")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	print("🔥 Magma Slime took %.1f damage. HP: %.1f/%.1f" % [amount, current_hp, max_hp])

	# Spawn damage number
	spawn_damage_number(amount, is_crit)

	# Spawn hit particles
	spawn_hit_particle(is_crit)

	# Visual feedback
	if sprite:
		var original_color = sprite.modulate
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Check again after await
			sprite.modulate = original_color

	# Knockback
	if from_position != Vector2.ZERO and not is_jumping:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 150  # Less knockback for heavy slime

	if current_hp <= 0:
		die()

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		return

	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -30)

	get_tree().root.add_child(damage_num)

	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

func spawn_hit_particle(is_crit: bool = false):
	if not hit_particle_scene:
		return

	var particle = hit_particle_scene.instantiate()
	particle.global_position = global_position

	get_tree().root.add_child(particle)

	if particle.has_method("set_color_from_damage"):
		particle.set_color_from_damage(is_crit)

func spawn_death_particle():
	if not death_particle_scene:
		return

	var particle = death_particle_scene.instantiate()
	particle.global_position = global_position

	get_tree().root.add_child(particle)

	if particle.has_method("set_color_for_enemy"):
		particle.set_color_for_enemy("MagmaSlime")

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print("💀 Magma Slime defeated!")

	# Spawn death particle effect
	spawn_death_particle()

	# Increment player kill counter
	if player and "total_kills" in player:
		player.total_kills += 1

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
		print("⭐ Dropped %.1f XP" % xp_reward)

	# Death animation (melt effect)
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_property(sprite, "scale", Vector2(1.5, 0.3), 0.5)  # Melt into puddle
		tween.tween_callback(queue_free)
	else:
		queue_free()

	# Drop items
	attempt_drop_items()

func attempt_drop_items():
	# Gold drop (guaranteed)
	var gold_amount = randi_range(gold_drop_min, gold_drop_max)
	spawn_gold(gold_amount)

	# Rare drop (3% base - mini-boss has better drops!)
	var rare_chance = 0.03 * get_player_lucky()
	if randf() < rare_chance:
		spawn_rare_item()

func get_player_lucky() -> float:
	if not player:
		return 1.0

	if "lucky" in player:
		return player.lucky

	return 1.0

func spawn_gold(amount: int):
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
		print("💰 Dropped %d gold" % amount)

func spawn_rare_item():
	# TODO: Implement rare item drops
	print("💎 Would drop rare item!")

func update_sprite():
	if not sprite or is_jumping:
		return

	if velocity.x != 0:
		# Flip sprite based on movement direction
		if sprite is ColorRect:
			sprite.scale.x = abs(sprite.scale.x) * (-1 if velocity.x > 0 else 1)
