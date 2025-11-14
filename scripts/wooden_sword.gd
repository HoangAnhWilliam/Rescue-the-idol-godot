extends Weapon
class_name WoodenSword

## Wooden Sword - COMMON Rarity
## Basic starting weapon for all players
## Simple melee, single-target damage

# Weapon metadata
var weapon_id: String = "wooden_sword"
var weapon_name: String = "Wooden Sword"
var rarity: int = 0  # COMMON

func _ready():
	# Set weapon stats
	damage = 8.0
	attack_speed = 1.0  # 1 attack per second
	attack_range = 140.0
	is_projectile = false

	super._ready()

	print("🪵 Wooden Sword equipped - Basic starter weapon")

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage, global_position)
		print("🪵 Wooden Sword hit for ", damage, " damage")

	# Simple visual feedback
	create_hit_effect(target.global_position)

	# Reset cooldown
	attack_cooldown = 1.0 / attack_speed
