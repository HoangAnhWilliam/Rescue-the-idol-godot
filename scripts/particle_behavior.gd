extends ColorRect

## Auto-attached to particles for movement, gravity, lifetime, and fade out
## Reads metadata: velocity, gravity, lifetime, fade_out

var velocity: Vector2 = Vector2.ZERO
var gravity: float = 0.0
var lifetime: float = 1.0
var fade_out: bool = false

var time_alive: float = 0.0
var initial_alpha: float = 1.0

func _ready():
	# Read metadata set by ParticleManager
	if has_meta("velocity"):
		velocity = get_meta("velocity")
	if has_meta("gravity"):
		gravity = get_meta("gravity")
	if has_meta("lifetime"):
		lifetime = get_meta("lifetime")
	if has_meta("fade_out"):
		fade_out = get_meta("fade_out")

	initial_alpha = modulate.a

func _process(delta):
	# Update position
	global_position += velocity * delta

	# Apply gravity to velocity
	if gravity != 0.0:
		velocity.y += gravity * delta

	# Track lifetime
	time_alive += delta

	# Fade out effect
	if fade_out:
		var fade_progress = time_alive / lifetime
		modulate.a = initial_alpha * (1.0 - fade_progress)

	# Auto-destroy after lifetime
	if time_alive >= lifetime:
		queue_free()
