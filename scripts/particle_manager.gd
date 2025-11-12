extends Node
class_name ParticleManager

## Singleton pattern for spawning particles anywhere in the game
## Use static methods: ParticleManager.create_hit_effect(pos, color)

static var instance: ParticleManager = null

func _ready():
	instance = self
	print("✨ ParticleManager ready!")

# ========== HIT EFFECT ==========
## Creates a burst of 8 particles when an enemy is hit
static func create_hit_effect(pos: Vector2, color: Color = Color.WHITE):
	if not instance:
		push_warning("ParticleManager instance not found!")
		return

	var particle_count = 8
	var speed_min = 100.0
	var speed_max = 200.0
	var lifetime_min = 0.3
	var lifetime_max = 0.6

	for i in range(particle_count):
		var angle = (TAU / particle_count) * i  # Evenly distributed 360°
		var direction = Vector2(cos(angle), sin(angle))
		var speed = randf_range(speed_min, speed_max)

		var particle = instance._create_particle(pos, Vector2(6, 6), color)
		particle.set_meta("velocity", direction * speed)
		particle.set_meta("gravity", 0.0)  # No gravity for hit effects
		particle.set_meta("lifetime", randf_range(lifetime_min, lifetime_max))
		particle.set_meta("fade_out", true)

# ========== DEATH EXPLOSION ==========
## Creates an explosion of particles when an entity dies
## size_multiplier: 1.0 = normal enemy, 2.0 = mini-boss, 5.0 = boss
static func create_death_explosion(pos: Vector2, color: Color, size_multiplier: float = 1.0):
	if not instance:
		return

	var particle_count = int(12 * size_multiplier)
	var speed_min = 150.0
	var speed_max = 300.0
	var size_min = 4.0 * size_multiplier
	var size_max = 12.0 * size_multiplier
	var gravity = 500.0
	var lifetime = 0.8

	for i in range(particle_count):
		# Random direction (360°)
		var angle = randf() * TAU
		var direction = Vector2(cos(angle), sin(angle))
		var speed = randf_range(speed_min, speed_max)

		# Random size variation
		var size = randf_range(size_min, size_max)

		var particle = instance._create_particle(pos, Vector2(size, size), color)
		particle.set_meta("velocity", direction * speed)
		particle.set_meta("gravity", gravity)
		particle.set_meta("lifetime", lifetime)
		particle.set_meta("fade_out", true)

	print("💥 Death explosion at: ", pos)

# ========== LEVEL UP EFFECT ==========
## Creates 3 expanding rings of gold particles when player levels up
static func create_level_up_effect(pos: Vector2):
	if not instance:
		return

	var gold_color = Color(1.0, 0.84, 0.0)  # Gold
	var particles_per_ring = 16
	var ring_count = 3

	for ring_idx in range(ring_count):
		var delay = ring_idx * 0.1  # 0.1s between rings
		var radius = 50.0 + (ring_idx * 30.0)  # Expanding radius

		# Use timer for delay
		instance.get_tree().create_timer(delay).timeout.connect(
			func():
				for i in range(particles_per_ring):
					var angle = (TAU / particles_per_ring) * i
					var offset = Vector2(cos(angle), sin(angle)) * radius

					var particle = instance._create_particle(pos + offset, Vector2(8, 8), gold_color)
					particle.set_meta("velocity", Vector2.ZERO)  # Static particles
					particle.set_meta("gravity", 0.0)
					particle.set_meta("lifetime", 0.5)
					particle.set_meta("fade_out", true)
		)

	print("⭐ Level up effect at: ", pos)

# ========== BOSS PHASE CHANGE EFFECT ==========
## Creates dramatic shockwave rings and particle burst for boss phase transitions
static func create_phase_change_effect(pos: Vector2, radius: float = 300.0):
	if not instance:
		return

	var shockwave_color = Color(1.0, 0.4, 0.0, 0.8)  # Orange
	var burst_color = Color(1.0, 0.2, 0.0)  # Red-orange

	# 5 expanding shockwave rings
	for ring_idx in range(5):
		var delay = ring_idx * 0.1
		instance.get_tree().create_timer(delay).timeout.connect(
			func():
				create_shockwave_ring(pos, radius + (ring_idx * 50.0), shockwave_color)
		)

	# 30 particle burst
	var particle_count = 30
	for i in range(particle_count):
		var angle = randf() * TAU
		var direction = Vector2(cos(angle), sin(angle))
		var speed = randf_range(200.0, 400.0)

		var particle = instance._create_particle(pos, Vector2(10, 10), burst_color)
		particle.set_meta("velocity", direction * speed)
		particle.set_meta("gravity", 200.0)
		particle.set_meta("lifetime", 0.8)
		particle.set_meta("fade_out", true)

	print("🔥 Phase change effect!")

# ========== SHOCKWAVE RING ==========
## Creates a ring of particles at a specific radius
static func create_shockwave_ring(pos: Vector2, radius: float, color: Color):
	if not instance:
		return

	var particle_count = 24
	for i in range(particle_count):
		var angle = (TAU / particle_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * radius

		var particle = instance._create_particle(pos + offset, Vector2(8, 8), color)
		particle.set_meta("velocity", Vector2.ZERO)
		particle.set_meta("gravity", 0.0)
		particle.set_meta("lifetime", 0.4)
		particle.set_meta("fade_out", true)

# ========== SNOW PARTICLES (Biome Ambient) ==========
## Creates falling snow particles for Frozen Tundra biome
static func create_snow_particles(pos: Vector2, count: int = 2):
	if not instance:
		return

	var snow_color = Color(0.9, 0.95, 1.0, 0.7)  # Light blue-white

	for i in range(count):
		# Spawn above player, random X offset
		var spawn_offset = Vector2(randf_range(-300, 300), randf_range(-200, -150))
		var particle_pos = pos + spawn_offset

		var particle = instance._create_particle(particle_pos, Vector2(4, 4), snow_color)
		particle.set_meta("velocity", Vector2(randf_range(-20, 20), randf_range(30, 60)))  # Slow fall
		particle.set_meta("gravity", 0.0)  # No additional gravity
		particle.set_meta("lifetime", 3.0)  # Long lifetime
		particle.set_meta("fade_out", true)

# ========== LAVA BUBBLE (Biome Ambient) ==========
## Creates rising lava bubbles for Volcanic Darklands biome
static func create_lava_bubble(pos: Vector2):
	if not instance:
		return

	var lava_color = Color(1.0, 0.3, 0.0, 0.6)  # Orange with transparency

	var particle = instance._create_particle(pos, Vector2(6, 6), lava_color)
	particle.set_meta("velocity", Vector2(randf_range(-10, 10), randf_range(-80, -120)))  # Rise up
	particle.set_meta("gravity", 0.0)  # No gravity (bubbles rise)
	particle.set_meta("lifetime", 1.5)
	particle.set_meta("fade_out", true)

# ========== CORE PARTICLE CREATION ==========
## Creates a single particle ColorRect with metadata
## This is the base particle that all effects use
func _create_particle(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var particle = ColorRect.new()
	particle.size = size
	particle.color = color
	particle.global_position = pos - (size / 2.0)  # Center on position
	particle.z_index = 100  # Above everything

	# Attach behavior script
	var behavior_script = load("res://scripts/particle_behavior.gd")
	particle.set_script(behavior_script)

	# Add to scene root (not as child of this node)
	get_tree().root.add_child(particle)

	return particle
