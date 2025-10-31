extends CPUParticles2D
class_name LevelUpParticle

func _ready():
	# Setup particles
	emitting = true
	one_shot = true
	explosiveness = 0.5  # Less explosive for smoother effect
	
	# Lots of particles for celebration!
	amount = 30
	lifetime = 1.0
	
	# Emission shape - ring around player
	emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	emission_sphere_radius = 40.0	
	
	
	
	# Movement - burst outward
	direction = Vector2(0, -1)  # Up
	spread = 180
	initial_velocity_min = 80
	initial_velocity_max = 150
	
	# Gravity pulls down gently
	gravity = Vector2(0, 100)
	
	# Visual - gold sparkles
	scale_amount_min = 4.0
	scale_amount_max = 8.0
	
	# Gold color
	color = Color(1.0, 0.84, 0.0)  # Gold
	
	# Fade out
	color_ramp = create_fade_gradient()
	
	# Auto cleanup
	await get_tree().create_timer(lifetime + 0.5).timeout
	queue_free()

func create_fade_gradient() -> Gradient:
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1.0, 0.84, 0.0, 1.0))  # Full opacity
	gradient.add_point(1.0, Color(1.0, 0.84, 0.0, 0.0))  # Fade out
	return gradient
