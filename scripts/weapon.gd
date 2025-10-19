extends Node2D
class_name Weapon

# Weapon stats
@export var damage: float = 10.0
@export var attack_speed: float = 1.0  # Attacks per second
@export var attack_range: float = 150.0
@export var projectile_speed: float = 300.0
@export var is_projectile: bool = false  # false = melee

# State
var attack_cooldown: float = 0.0
var level: int = 1

# References
var player: CharacterBody2D

func _ready():
	player = get_parent().get_parent()  # Player -> WeaponPivot -> Weapon
	print("Weapon ready: ", name)

func _process(delta):
	attack_cooldown -= delta
	
	if attack_cooldown <= 0:
		var target = find_closest_enemy()
		if target:
			attack(target)
			attack_cooldown = 1.0 / attack_speed

func find_closest_enemy() -> CharacterBody2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	if enemies.is_empty():
		return null
	
	var closest_enemy = null
	var closest_distance = attack_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
	
	return closest_enemy

func attack(target: CharacterBody2D):
	if not is_instance_valid(target):
		return
	
	print("Attacking ", target.name, " for ", damage, " damage!")
	
	if is_projectile:
		# TODO: Spawn projectile later
		pass
	else:
		# Melee attack - instant damage
		if target.has_method("take_damage"):
			target.take_damage(damage, global_position)
			
			# Visual feedback
			create_hit_effect(target.global_position)

func create_hit_effect(position: Vector2):
	# TODO: Add particle effect later
	print("Hit effect at: ", position)

func upgrade():
	level += 1
	damage *= 1.2
	attack_speed *= 1.1
	print("Weapon upgraded to level ", level)

func get_dps() -> float:
	return damage * attack_speed
