extends Weapon
class_name ShadowDaggers

## Shadow Daggers - UNCOMMON Rarity
## Fast melee with multi-hit combo
## Highest single-target DPS weapon

# Weapon metadata
var weapon_id: String = "shadow_daggers"
var weapon_name: String = "Shadow Daggers"
var rarity: int = 1  # UNCOMMON
var hits_per_attack: int = 3
var crit_chance: float = 0.15

func _ready():
	# Set weapon stats
	damage = 5.0  # Per hit (5 × 3 = 15 per attack)
	attack_speed = 2.0  # Very fast (2 attacks/second)
	attack_range = 120.0  # Short range
	is_projectile = false

	super._ready()

	print("🗡️ Shadow Daggers equipped - Triple strike combo!")

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return

	# Triple strike combo
	execute_combo(target)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed

func execute_combo(target: CharacterBody2D):
	var total_damage = 0.0

	for i in range(hits_per_attack):
		# Small delay between hits
		if i > 0:
			await get_tree().create_timer(0.05).timeout

		# Check if target still valid
		if not is_instance_valid(target):
			break

		var hit_damage = damage

		# Crit check per hit
		var is_crit = randf() < crit_chance

		if is_crit:
			hit_damage *= 3.0
			ParticleManager.create_hit_effect(
				target.global_position,
				Color(1.0, 0.0, 0.0)  # Red crit
			)
			print("🗡️ SHADOW DAGGER CRIT! Hit ", i + 1)

		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(hit_damage, global_position)

		total_damage += hit_damage

		# Visual feedback
		create_hit_effect(target.global_position)

	print("🗡️ Shadow Daggers combo: ", total_damage, " total damage (", hits_per_attack, " hits)")
