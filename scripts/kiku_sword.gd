extends Weapon
class_name KikuSword

## Kiku Sword - LEGENDARY Rarity
## Obtained from rescuing Kiku (70% chance)
## Special: 15% critical hit chance for 2x damage

# Weapon metadata
var weapon_id: String = "kiku_sword"
var weapon_name: String = "Kiku Sword"
var rarity: int = 4  # LEGENDARY
var crit_chance: float = 0.15

func _ready():
	# Set weapon stats
	damage = 15.0
	attack_speed = 1.2  # Faster than basic
	attack_range = 160.0
	is_projectile = false

	super._ready()

	print("🎤 Kiku Sword equipped - LEGENDARY weapon with crit chance!")

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return

	var final_damage = damage

	# Critical hit chance
	if randf() < crit_chance:
		final_damage *= 2.0

		# Visual feedback for crit
		ParticleManager.create_hit_effect(target.global_position, Color(1.0, 0.84, 0.0))  # Gold sparkle
		CameraShake.shake(3.0, 0.15)

		print("✨ MIKU SWORD CRITICAL HIT! ", final_damage, " damage!")
	else:
		print("🎤 Kiku Sword hit for ", final_damage, " damage")

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(final_damage, global_position)

	# Normal hit effect
	create_hit_effect(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed
