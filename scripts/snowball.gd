extends Area2D
class_name Snowball

var direction: Vector2 = Vector2.RIGHT
var speed: float = 180.0
var damage: float = 15.0
var lifetime: float = 5.0
var apply_slow: bool = false
var slow_amount: float = 0.4
var slow_duration: float = 3.0

# For lava elemental variant
var is_lava: bool = false
var lava_pool_scene: PackedScene = null

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	position += direction * speed * delta
	lifetime -= delta

	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		# Apply slow effect
		if apply_slow and body.has_method("apply_slow"):
			body.apply_slow(slow_amount, slow_duration)

		# Create lava pool if lava variant
		if is_lava:
			create_lava_pool()

		queue_free()
	elif body is TileMap or body.is_in_group("walls"):
		# Create lava pool on impact with terrain
		if is_lava:
			create_lava_pool()
		queue_free()

func _on_area_entered(area):
	# Hit other entities
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player and player.has_method("take_damage"):
			player.take_damage(damage)

		if apply_slow and player and player.has_method("apply_slow"):
			player.apply_slow(slow_amount, slow_duration)

		if is_lava:
			create_lava_pool()

		queue_free()

func create_lava_pool():
	if not lava_pool_scene:
		return

	var pool = lava_pool_scene.instantiate()
	pool.global_position = global_position
	get_parent().add_child(pool)
