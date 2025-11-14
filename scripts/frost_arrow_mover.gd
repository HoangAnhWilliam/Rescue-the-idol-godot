extends Area2D

## Frost Arrow Movement Script
## Handles movement and lifetime for Frost Bow projectiles

func _physics_process(delta):
	# Move projectile
	if has_meta("direction") and has_meta("speed"):
		var direction = get_meta("direction")
		var speed = get_meta("speed")
		global_position += direction * speed * delta

	# Lifetime countdown
	if has_meta("lifetime"):
		var lifetime = get_meta("lifetime")
		lifetime -= delta
		set_meta("lifetime", lifetime)

		if lifetime <= 0:
			queue_free()
