extends CPUParticles2D
class_name HitParticle

func _ready():
	# Setup particles
	emitting = true
	one_shot = true
	explosiveness = 1.0
	
	# Particle properties
	amount = 8
	lifetime = 0.5
	
	# Emission shape
	emission_shape = EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 5.0
	
	# Movement
	direction = Vector2.ZERO
	spread = 180
	initial_velocity_min = 50
	initial_velocity_max = 100
	
	# Gravity
	gravity = Vector2(0, 200)
	
	# Visual
	scale_amount_min = 2.0
	scale_amount_max = 4.0
	
	# Color (white particles)
	color = Color.WHITE
	
	# Auto cleanup
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func set_color_from_damage(is_crit: bool):
	if is_crit:
		color = Color.YELLOW
		amount = 12
		initial_velocity_max = 150
	else:
		color = Color.WHITE
