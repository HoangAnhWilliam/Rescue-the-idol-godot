extends Enemy
class_name KeyboardWarrior

# ========== KEYBOARD WARRIOR ==========
# Ranged enemy in Otaku Fortress
# Shoots text bubble projectiles

var projectile_mover_script = preload("res://scripts/projectile_mover.gd")
var shoot_cooldown: float = 0.0
const SHOOT_CD: float = 3.0
const PROJECTILE_DAMAGE: float = 8.0

func _ready():
	# Override base stats
	max_hp = 80.0
	current_hp = max_hp
	damage = 8.0
	move_speed = 70.0  # Medium speed
	xp_reward = 40.0
	detection_range = 400.0
	attack_range = 200.0  # Stays at range
	attack_cooldown = 3.0
	gold_drop_min = 75
	gold_drop_max = 150

	print("Keyboard Warrior spawned!")

	# Add to groups
	add_to_group("enemies")
	add_to_group("keyboard_warriors")

	# Set visual
	if sprite and sprite is ColorRect:
		sprite.scale = Vector2(1.0, 1.0)
		sprite.color = Color(0.9, 0.9, 0.9)  # White (keyboard)
		print("✓ Keyboard Warrior visual set")

	# Connect hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Keyboard Warrior hitbox connected")

	# Initialize state
	current_state = State.IDLE
	attack_timer = 0.0

	# Find player
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	if shoot_cooldown > 0:
		shoot_cooldown -= delta

	# State machine
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player_ranged(delta)
		State.ATTACK:
			perform_ranged_attack(delta)

func chase_player_ranged(delta):
	"""Stay at range and backpedal if too close"""
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# Too close - backpedal
	if distance < attack_range * 0.5:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		update_sprite()

	# Too far - approach
	elif distance > attack_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		update_sprite()

	# In range - attack
	else:
		current_state = State.ATTACK

func perform_ranged_attack(delta):
	"""Shoot text bubble projectiles"""
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# Too close - back up
	if distance < attack_range * 0.5:
		current_state = State.CHASE
		return

	# Too far - chase
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return

	# Stop moving
	velocity = Vector2.ZERO

	# Shoot projectile
	if shoot_cooldown <= 0:
		shoot_text_bubble()
		shoot_cooldown = SHOOT_CD

func shoot_text_bubble():
	"""Shoot a text bubble at player"""
	print("💬 Keyboard Warrior: ACKCHYUALLY...")

	var bubble = Area2D.new()
	bubble.name = "TextBubble"

	var visual = ColorRect.new()
	visual.size = Vector2(30, 20)
	visual.position = -visual.size / 2
	visual.color = Color(1.0, 1.0, 1.0)  # White
	bubble.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	bubble.add_child(collision_shape)

	bubble.global_position = global_position

	var direction = (player.global_position - global_position).normalized()
	bubble.set_meta("direction", direction)
	bubble.set_meta("speed", 200.0)
	bubble.set_meta("damage", PROJECTILE_DAMAGE)
	bubble.set_meta("lifetime", 5.0)
	bubble.set_meta("from_boss", true)

	bubble.set_script(projectile_mover_script)
	get_tree().root.add_child(bubble)

func die():
	print("Keyboard Warrior defeated!")
	super.die()
