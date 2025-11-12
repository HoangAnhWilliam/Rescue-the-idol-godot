extends Area2D
class_name XPGem

## XP Gem pickup - replaces direct XP add from enemies
## Features: Visual tiers, magnet system, pulse animation, despawn timer

@export var xp_value: float = 10.0

# Magnet system
const MAGNET_RANGE: float = 150.0
const MAGNET_SPEED: float = 300.0
const INITIAL_BOUNCE_SPEED: float = 150.0
const BOUNCE_DECAY: float = 0.95

# Visual properties
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.2
const PULSE_DURATION: float = 0.5

# Despawn
const DESPAWN_TIME: float = 30.0

var player: CharacterBody2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0

@onready var sprite: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready():
	add_to_group("pickups")
	add_to_group("xp_gems")

	# Find player
	player = get_tree().get_first_node_in_group("player")

	# Setup visual based on XP value
	setup_visual_tier()

	# Start pulse animation
	start_pulse_animation()

	# Initial bounce (random direction)
	var angle = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * INITIAL_BOUNCE_SPEED

	# Connect collision
	body_entered.connect(_on_body_entered)

	print("💎 XP Gem spawned: %.0f XP" % xp_value)

func setup_visual_tier():
	if not sprite:
		return

	# Determine tier based on XP value
	var size: Vector2
	var color: Color

	if xp_value < 20:
		# Small gem - Green
		size = Vector2(8, 8)
		color = Color(0, 1, 0)
	elif xp_value < 50:
		# Medium gem - Cyan
		size = Vector2(10, 10)
		color = Color(0, 1, 0.5)
	elif xp_value < 100:
		# Large gem - Blue
		size = Vector2(12, 12)
		color = Color(0, 0.5, 1)
	else:
		# Huge gem - Magenta
		size = Vector2(16, 16)
		color = Color(1, 0, 1)

	sprite.size = size
	sprite.position = -size / 2.0  # Center
	sprite.color = color

	# Update collision shape
	if collision and collision.shape is CircleShape2D:
		collision.shape.radius = (size.x / 2.0) + 2.0

func start_pulse_animation():
	if not sprite:
		return

	# Create infinite pulse tween
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(PULSE_SCALE_MAX, PULSE_SCALE_MAX), PULSE_DURATION)
	tween.tween_property(sprite, "scale", Vector2(PULSE_SCALE_MIN, PULSE_SCALE_MIN), PULSE_DURATION)

func _physics_process(delta):
	# Track lifetime for despawn
	time_alive += delta

	# Despawn check
	if time_alive >= DESPAWN_TIME:
		despawn()
		return

	# Check magnet range if not already attracted
	if not is_attracted and player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance < MAGNET_RANGE:
			is_attracted = true
			velocity = Vector2.ZERO  # Stop bounce
			print("💎 XP Gem attracted to player!")

	# Magnet movement
	if is_attracted and player and is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * MAGNET_SPEED * delta

	# Bounce movement (if not attracted)
	elif not is_attracted:
		global_position += velocity * delta
		velocity *= BOUNCE_DECAY  # Slow down over time

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		collect(body)

func collect(player_body: CharacterBody2D):
	# Add XP to player (direct add, bypasses inventory)
	if player_body.has_method("add_xp"):
		player_body.add_xp(xp_value)
		print("✅ Player collected %.0f XP" % xp_value)

	# Spawn particle effect
	var gem_color = sprite.color if sprite else Color.GREEN
	ParticleManager.create_hit_effect(global_position, gem_color)

	# Remove gem
	queue_free()

func despawn():
	print("⏰ XP Gem despawned (timeout)")

	# Fade out animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
