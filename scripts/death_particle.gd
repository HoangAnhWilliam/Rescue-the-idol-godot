extends CPUParticles2D
class_name DeathParticle

func _ready():
	# Setup particles
	emitting = true
	one_shot = true
	explosiveness = 1.0
	
	# More particles than hit effect
	amount = 20
	lifetime = 0.8
	
	# Emission shape
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 10.0
	
	# Movement
	direction = Vector2.ZERO
	spread = 180
	initial_velocity_min = 100
	initial_velocity_max = 200
	
	# Gravity
	gravity = Vector2(0, 300)
	
	# Visual
	scale_amount_min = 3.0
	scale_amount_max = 6.0
	
	# Color based on enemy type
	color = Color.RED
	
	# Auto cleanup
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func set_color_for_enemy(enemy_name: String):
	# Different colors for different enemies
	if "Zombie" in enemy_name:
		color = Color(1.0, 0.2, 0.2)  # Red
	elif "Skeleton" in enemy_name:
		color = Color(0.7, 0.7, 0.7)  # Gray
	else:
		color = Color(1.0, 1.0, 1.0)  # White
