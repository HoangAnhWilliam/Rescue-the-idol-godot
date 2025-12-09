extends Area2D
class_name TearProjectile

## Projectile used by Despair Kiku boss
## Can be homing or straight-line

@onready var sprite: ColorRect = $ColorRect
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# Properties
var damage: float = 15.0
var speed: float = 100.0
var direction: Vector2 = Vector2.RIGHT
var is_homing: bool = false
var target: Node2D = null
var lifetime: float = 5.0
var homing_strength: float = 3.0

func _ready() -> void:
	# Setup sprite
	if sprite:
		sprite.size = Vector2(12, 12)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0.6, 0.8, 1.0, 0.8)  # Light cyan (tear drop)

	# Setup collision
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)

	var shape := CircleShape2D.new()
	shape.radius = 6
	collision_shape.shape = shape

	# Connect collision
	body_entered.connect(_on_body_entered)

	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	if is_instance_valid(self):
		queue_free()


func setup(target_node: Node2D, dmg: float, spd: float, homing: bool = false) -> void:
	"""Setup projectile properties"""

	target = target_node
	damage = dmg
	speed = spd
	is_homing = homing

	if target:
		direction = (target.global_position - global_position).normalized()


func _physics_process(delta: float) -> void:
	# Update direction if homing
	if is_homing and target and is_instance_valid(target):
		var target_direction := (target.global_position - global_position).normalized()
		direction = direction.lerp(target_direction, homing_strength * delta).normalized()

	# Move projectile
	global_position += direction * speed * delta

	# Rotate to face direction
	if sprite:
		sprite.rotation = direction.angle()


func _on_body_entered(body: Node2D) -> void:
	"""Handle collision with bodies"""

	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)

		# Hit effect
		var particle_manager := get_node_or_null("/root/ParticleManager")
		if particle_manager:
			particle_manager.create_hit_effect(global_position)

	# Destroy projectile
	queue_free()
