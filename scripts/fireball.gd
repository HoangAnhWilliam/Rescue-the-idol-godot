extends Area2D
class_name Fireball

var direction: Vector2 = Vector2.RIGHT
var speed: float = 250.0
var damage: float = 15.0
var lifetime: float = 5.0

func _ready():
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _process(delta):
	position += direction * speed * delta
	lifetime -= delta

	# Rotate for visual effect
	rotation += delta * 5.0

	if lifetime <= 0:
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body is TileMap or body.is_in_group("walls"):
		queue_free()

func _on_area_entered(area):
	# Hit other entities
	if area.is_in_group("player"):
		var player = area.get_parent()
		if player and player.has_method("take_damage"):
			player.take_damage(damage)
		queue_free()
