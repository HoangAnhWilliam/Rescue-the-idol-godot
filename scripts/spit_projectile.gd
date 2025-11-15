extends Area2D
class_name SpitProjectile

var direction: Vector2 = Vector2.RIGHT
var speed: float = 200.0
var damage: float = 10.0
var lifetime: float = 5.0
var apply_slow: bool = false
var slow_amount: float = 0.3
var slow_duration: float = 3.0

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

		queue_free()
	elif body is TileMap or body.is_in_group("walls"):
		queue_free()

func _on_area_entered(area):
	# Hit other entities
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player and player.has_method("take_damage"):
			player.take_damage(damage)

		if apply_slow and player and player.has_method("apply_slow"):
			player.apply_slow(slow_amount, slow_duration)

		queue_free()
