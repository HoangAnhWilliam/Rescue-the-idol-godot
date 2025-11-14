extends Weapon
class_name MikuSword

## Miku Sword - LEGENDARY Rarity
## Obtained from rescuing Miku (70% chance)
## Special: 15% critical hit chance for 2x damage

var crit_chance: float = 0.15

func _ready():
	# Set weapon properties
	weapon_id = "miku_sword"
	weapon_name = "Miku Sword"
	rarity = 4  # LEGENDARY

	damage = 15.0
	attack_speed = 1.2  # Faster than basic
	range = 160.0
	is_projectile = false

	super._ready()

	print("🎤 Miku Sword equipped - LEGENDARY weapon with crit chance!")

func attack(target_position: Vector2):
	# Find closest enemy
	var target = find_closest_enemy()

	if not target:
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
		print("🎤 Miku Sword hit for ", final_damage, " damage")

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(final_damage, global_position)

	# Normal hit effect
	create_hit_effect(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed
