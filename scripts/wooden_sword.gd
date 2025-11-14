extends Weapon
class_name WoodenSword

## Wooden Sword - COMMON Rarity
## Basic starting weapon for all players
## Simple melee, single-target damage

func _ready():
	# Set weapon properties
	weapon_id = "wooden_sword"
	weapon_name = "Wooden Sword"
	rarity = 0  # COMMON

	damage = 8.0
	attack_speed = 1.0  # 1 attack per second
	range = 140.0
	is_projectile = false

	super._ready()

	print("🪵 Wooden Sword equipped - Basic starter weapon")

func attack(target_position: Vector2):
	# Find closest enemy
	var target = find_closest_enemy()

	if not target:
		return

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		print("🪵 Wooden Sword hit for ", damage, " damage")

	# Simple visual feedback
	create_hit_effect(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed
