extends Weapon
class_name AcidGauntlets

## Acid Storm Gauntlets - RARE Rarity
## Periodic AoE damage over time
## Creates acid rain that damages all enemies in large radius

# Weapon metadata
var weapon_id: String = "acid_gauntlets"
var weapon_name: String = "Acid Storm Gauntlets"
var rarity: int = 2  # RARE

var rain_active: bool = false
var rain_timer: float = 0.0
var rain_duration: float = 5.0
var tick_timer: float = 0.0
var tick_rate: float = 1.0

func _ready():
	# Set weapon stats
	damage = 8.0  # Per second (8 dmg/tick × 5 ticks = 40 total)
	attack_speed = 0.125  # Cooldown of 8 seconds (1/8)
	attack_range = 250.0  # Large radius
	is_projectile = false

	super._ready()

	print("🌧️ Acid Storm Gauntlets equipped - Periodic acid rain!")

func _process(delta):
	# Base weapon cooldown
	if attack_cooldown > 0:
		attack_cooldown -= delta

	# Trigger rain when cooldown ready
	if attack_cooldown <= 0 and not rain_active:
		var enemies = get_tree().get_nodes_in_group("enemies")
		if not enemies.is_empty():
			start_rain()
			attack_cooldown = 1.0 / attack_speed  # 8 seconds

	# Handle active rain
	if rain_active:
		rain_timer += delta
		tick_timer += delta

		# Damage tick
		if tick_timer >= tick_rate:
			tick_timer = 0.0
			apply_rain_damage()

		# End rain
		if rain_timer >= rain_duration:
			stop_rain()

func start_rain():
	rain_active = true
	rain_timer = 0.0
	tick_timer = 0.0

	print("☠️ ACID RAIN STARTED! 5 seconds of DoT")

	# Visual: Spawn rain particles
	spawn_rain_particles()

func apply_rain_damage():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var hit_position = player.global_position
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = hit_position.distance_to(enemy.global_position)

		if distance <= attack_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, hit_position)
			hit_count += 1

	if hit_count > 0:
		print("🌧️ Acid rain tick: ", hit_count, " enemies hit for ", damage, " damage")

func stop_rain():
	rain_active = false
	print("🌧️ Acid rain ended")

func spawn_rain_particles():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	# Create 20 falling green particles
	for i in range(20):
		var offset = Vector2(
			randf_range(-attack_range, attack_range),
			randf_range(-attack_range, attack_range)
		)

		ParticleManager.create_hit_effect(
			player.global_position + offset,
			Color(0.2, 1.0, 0.2)  # Acid green
		)

	# Schedule next particle spawn if rain still active
	if rain_active:
		await get_tree().create_timer(0.5).timeout
		if rain_active:
			spawn_rain_particles()

# Area effect, no specific target needed
func attack(target_position: Vector2):
	# Attack handled by _process() timer
	pass

func find_closest_enemy() -> CharacterBody2D:
	# Area effect, no specific target
	return null
