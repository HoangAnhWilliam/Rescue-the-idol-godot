extends Weapon
class_name LightningChain

## Lightning Chain - RARE Rarity
## Chain lightning that jumps between enemies
## Hits initial target then jumps to nearby enemies

# Weapon metadata
var weapon_id: String = "lightning_chain"
var weapon_name: String = "Lightning Chain"
var rarity: int = 2  # RARE

var chain_jumps: int = 4  # Hits initial + 4 jumps = 5 total
var chain_range: float = 120.0

func _ready():
	# Set weapon stats
	damage = 12.0  # Per enemy (12 × 5 = 60 total if all hit)
	attack_speed = 0.7
	attack_range = 350.0
	is_projectile = false

	super._ready()

	print("⚡ Lightning Chain equipped - Chain lightning attacks!")

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return

	# Start chain lightning
	var hit_enemies: Array = []
	chain_lightning(target, hit_enemies, chain_jumps)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed

func chain_lightning(current_target: CharacterBody2D, hit_list: Array, jumps_left: int):
	if not is_instance_valid(current_target) or current_target in hit_list:
		return

	# Damage current target
	if current_target.has_method("take_damage"):
		current_target.take_damage(damage, global_position)

	hit_list.append(current_target)

	# Visual feedback
	ParticleManager.create_hit_effect(
		current_target.global_position,
		Color(0.3, 0.5, 1.0)  # Electric blue
	)
	CameraShake.shake(4.0, 0.15)

	print("⚡ Lightning hit ", current_target.name, " (", jumps_left, " jumps left)")

	# No more jumps
	if jumps_left <= 0:
		return

	# Find next target
	var next_target = find_next_chain_target(current_target, hit_list)

	if next_target:
		# Draw lightning arc visual
		draw_lightning_arc(current_target.global_position, next_target.global_position)

		# Small delay then chain
		await get_tree().create_timer(0.1).timeout

		# Check if target still valid after await (could be freed during delay)
		if not is_instance_valid(next_target):
			return

		# Continue chain
		chain_lightning(next_target, hit_list, jumps_left - 1)

func find_next_chain_target(from: CharacterBody2D, exclude: Array) -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: CharacterBody2D = null
	var min_dist = chain_range

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy in exclude:
			continue

		var dist = from.global_position.distance_to(enemy.global_position)

		if dist < min_dist:
			min_dist = dist
			closest = enemy

	return closest

func draw_lightning_arc(from: Vector2, to: Vector2):
	# Create line of particles from -> to
	var steps = 5

	for i in range(steps + 1):
		var t = float(i) / steps
		var pos = from.lerp(to, t)

		# Add random offset for lightning zigzag effect
		pos += Vector2(
			randf_range(-10, 10),
			randf_range(-10, 10)
		)

		ParticleManager.create_hit_effect(
			pos,
			Color(0.8, 0.9, 1.0)  # Bright electric blue
		)
