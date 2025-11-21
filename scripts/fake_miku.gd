extends Enemy
class_name FakeMiku

# ========== FAKE MIKU ==========
# Miku clone summoned by Pam in Phase 2
# Attacks with musical notes

var projectile_mover_script = preload("res://scripts/projectile_mover.gd")
var shoot_cooldown: float = 0.0
const SHOOT_CD: float = 2.5
const PROJECTILE_DAMAGE: float = 15.0

func _ready():
	# Override base stats
	max_hp = 200.0
	current_hp = max_hp
	damage = 15.0
	move_speed = 90.0
	xp_reward = 80.0  # Good reward
	detection_range = 450.0
	attack_range = 250.0  # Ranged
	attack_cooldown = 2.5
	gold_drop_min = 0
	gold_drop_max = 0  # No gold (illusion)

	print("Fake Miku spawned!")

	# Add to groups
	add_to_group("enemies")
	add_to_group("fake_mikus")

	# Set visual (teal like Miku)
	if sprite and sprite is ColorRect:
		sprite.scale = Vector2(1.2, 1.5)
		sprite.color = Color(0.0, 0.8, 0.8)  # Teal (Miku color)
		print("✓ Fake Miku visual set")

	# Connect hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Fake Miku hitbox connected")

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
	"""Stay at mid-range"""
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# In range - attack
	if distance < attack_range and distance > attack_range * 0.3:
		current_state = State.ATTACK

	# Too far - approach
	elif distance >= attack_range:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		update_sprite()

	# Too close - back up
	else:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		update_sprite()

func perform_ranged_attack(delta):
	"""Shoot musical notes"""
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# Check range
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return

	# Stop moving
	velocity = Vector2.ZERO

	# Shoot projectile
	if shoot_cooldown <= 0:
		shoot_musical_note()
		shoot_cooldown = SHOOT_CD

func shoot_musical_note():
	"""Shoot a musical note projectile"""
	print("🎵 Fake Miku: Musical note!")

	var note = Area2D.new()
	note.name = "MusicalNote"

	var visual = ColorRect.new()
	visual.size = Vector2(24, 24)
	visual.position = -visual.size / 2
	visual.color = Color(0.0, 1.0, 1.0)  # Cyan note
	note.add_child(visual)

	var shape = CircleShape2D.new()
	shape.radius = 12
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	note.add_child(collision_shape)

	note.global_position = global_position

	var direction = (player.global_position - global_position).normalized()
	note.set_meta("direction", direction)
	note.set_meta("speed", 300.0)
	note.set_meta("damage", PROJECTILE_DAMAGE)
	note.set_meta("lifetime", 5.0)
	note.set_meta("from_boss", true)

	note.set_script(projectile_mover_script)
	get_tree().root.add_child(note)

func die():
	print("Fake Miku defeated!")

	# Illusion - no gold drops
	print("💨 It was an illusion!")

	# Visual: Fade to sparkles
	if sprite:
		ParticleManager.create_death_explosion(global_position, Color(0.0, 0.8, 0.8), 1.2)

	# Must call super AFTER custom logic to avoid null sprite
	super.die()
