extends Area2D
class_name BloodWeb

## Blood Web projectile for Dark Miku
## Creates tether that slows player when moving away

@onready var sprite: ColorRect = $ColorRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Properties
var damage: float = 0.0  # No initial damage, just tether
var speed: float = 250.0
var direction: Vector2 = Vector2.RIGHT
var caster: Node2D = null
var lifetime: float = 3.0

# Tether
var is_tethered: bool = false
var tether_target: Node2D = null
var tether_line: Line2D = null
var tether_duration: float = 4.0
var tether_timer: float = 0.0
const MAX_TETHER_DISTANCE := 400.0

func _ready() -> void:
	# Setup sprite
	if sprite:
		sprite.size = Vector2(16, 16)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0.8, 0.1, 0.1, 0.8)  # Red

	# Setup collision
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)

	var shape := CircleShape2D.new()
	shape.radius = 8
	collision_shape.shape = shape

	# Connect collision
	body_entered.connect(_on_body_entered)


func setup(caster_node: Node2D, target_position: Vector2, dmg: float) -> void:
	"""Setup projectile"""

	caster = caster_node
	damage = dmg
	direction = (target_position - global_position).normalized()


func _physics_process(delta: float) -> void:
	if is_tethered:
		# Update tether
		update_tether(delta)
	else:
		# Move projectile
		global_position += direction * speed * delta

		# Rotate to face direction
		if sprite:
			sprite.rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision - create tether"""

	if is_tethered:
		return

	if body.is_in_group("player"):
		# Create tether
		create_tether(body)


func create_tether(target: Node2D) -> void:
	"""Create tether connection to target"""

	is_tethered = true
	tether_target = target
	tether_timer = tether_duration

	# Create visual line
	tether_line = Line2D.new()
	tether_line.width = 3.0
	tether_line.default_color = Color(0.8, 0.0, 0.0, 0.8)  # Red
	tether_line.z_index = -1
	add_child(tether_line)

	# Hide sprite
	if sprite:
		sprite.hide()

	# Disable collision
	if collision_shape:
		collision_shape.disabled = true

	print("Blood Web tether created on player")


func update_tether(delta: float) -> void:
	"""Update tether logic"""

	if not tether_target or not is_instance_valid(tether_target):
		break_tether()
		return

	# Update timer
	tether_timer -= delta
	if tether_timer <= 0:
		break_tether()
		return

	# Check distance
	var distance := global_position.distance_to(tether_target.global_position)
	if distance > MAX_TETHER_DISTANCE:
		break_tether()
		return

	# Update visual line
	if tether_line:
		tether_line.clear_points()
		tether_line.add_point(Vector2.ZERO)
		var target_local := to_local(tether_target.global_position)
		tether_line.add_point(target_local)

	# Apply slow effect
	apply_tether_slow()


func apply_tether_slow() -> void:
	"""Apply movement slow when player moves away"""

	if not tether_target or not is_instance_valid(tether_target):
		return

	# Check if player is moving away from caster
	if caster and is_instance_valid(caster):
		var to_player := (tether_target.global_position - caster.global_position).normalized()

		# Explicit type annotation to fix type inference
		var player_velocity: Vector2 = Vector2.ZERO
		if tether_target.get("velocity") != null:
			player_velocity = tether_target.velocity

		if player_velocity.length() > 0:
			var velocity_dir: Vector2 = player_velocity.normalized()
			var dot: float = velocity_dir.dot(to_player)

			# If moving away (dot > 0), apply slow
			if dot > 0:
				# Reduce player's velocity by 50%
				if tether_target.get("velocity") != null:
					tether_target.velocity *= 0.5


func break_tether() -> void:
	"""Break the tether"""

	if not is_tethered:
		return

	print("Blood Web tether broken")
	queue_free()


func _exit_tree() -> void:
	"""Cleanup when removed"""

	if tether_line and is_instance_valid(tether_line):
		tether_line.queue_free()
