extends Area2D
class_name ProjectileMover

# This script is attached dynamically to projectiles
# It reads movement data from metadata and auto-destroys

var direction: Vector2 = Vector2.ZERO
var speed: float = 0.0
var damage: float = 0.0
var lifetime: float = 0.0

var time_alive: float = 0.0

func _ready():
	# Read metadata set by spawner
	if has_meta("direction"):
		direction = get_meta("direction")
	if has_meta("speed"):
		speed = get_meta("speed")
	if has_meta("damage"):
		damage = get_meta("damage")
	if has_meta("lifetime"):
		lifetime = get_meta("lifetime")

	# Connect collision
	body_entered.connect(_on_body_entered)

	# Setup collision layer/mask
	collision_layer = 0  # Projectile on no layer
	collision_mask = 1   # Detect player (layer 1)

func _physics_process(delta):
	# Move projectile
	global_position += direction * speed * delta

	# Track lifetime
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_body_entered(body: Node):
	# Check if hit player
	if body.is_in_group("player"):
		# Apply damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
			print("🔥 Projectile hit player for ", damage, " damage")

		# Destroy projectile
		queue_free()
