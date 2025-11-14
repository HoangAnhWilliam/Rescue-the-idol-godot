extends Weapon
class_name EarthshatterStaff

## Earthshatter Staff - UNCOMMON Rarity
## AoE ground slam weapon
## Hits ALL enemies in radius with stun effect

func _ready():
	# Set weapon properties
	weapon_id = "earthshatter_staff"
	weapon_name = "Earthshatter Staff"
	rarity = 1  # UNCOMMON

	damage = 40.0  # High single-hit damage
	attack_speed = 0.33  # Slow (1 hit per 3 seconds)
	range = 150.0  # AoE radius
	is_projectile = false

	super._ready()

	print("🌍 Earthshatter Staff equipped - AoE ground slam!")

func attack(target_position: Vector2):
	# Get player position for slam center
	var player = get_tree().get_first_node_in_group("player")
	var hit_position = player.global_position if player else global_position

	# Find ALL enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = hit_position.distance_to(enemy.global_position)

		if distance <= range:
			# Deal damage
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, hit_position)

			# Stun effect (freeze enemy briefly)
			if "velocity" in enemy:
				enemy.velocity = Vector2.ZERO

			hit_count += 1

	if hit_count > 0:
		# Visual effects
		create_slam_effect(hit_position)
		CameraShake.shake(12.0, 0.4)  # Heavy shake

		print("💥 Earthshatter hit ", hit_count, " enemies for ", damage, " damage each!")

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed

func create_slam_effect(position: Vector2):
	# Create 3 expanding crack rings
	for i in range(3):
		await get_tree().create_timer(0.1 * i).timeout

		var radius = 50.0 + (i * 50.0)

		# Create ring of particles
		for angle in range(0, 360, 30):
			var rad = deg_to_rad(angle)
			var offset = Vector2(cos(rad), sin(rad)) * radius
			ParticleManager.create_hit_effect(
				position + offset,
				Color(0.5, 0.3, 0.1)  # Earth/brown color
			)

# Override to always trigger (area effect doesn't need specific target)
func find_closest_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if not enemies.is_empty():
		# Return any enemy to trigger attack
		return enemies[0] as CharacterBody2D
	return null
