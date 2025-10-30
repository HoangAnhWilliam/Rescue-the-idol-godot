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
var camera: Camera2D

func _ready():
	player = get_parent().get_parent()  # Player -> WeaponPivot -> Weapon
	print("Weapon ready: ", name)
	
	# Get camera reference
	if player and player.has_node("Camera2D"):
		camera = player.get_node("Camera2D")
		print("✓ Camera found for ", name)

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
	
	#Calculate damage with crit
	var final_damage = calculate_damage()
	var is_crit = check_crit()
	
	print("Attacking ", target.name, " for ", final_damage, " damage!", " (Crit: ", is_crit, ")")
	
	if is_projectile:
		# TODO: Spawn projectile later
		pass
	else:
		# Melee attack - instant damage
		if target.has_method("take_damage"):
			target.take_damage(damage, global_position)
			
			# Camera shake on crit
			if is_crit and camera and camera.has_method("crit_shake"):
				camera.crit_shake()
			elif camera and camera.has_method("small_shake"):
				camera.small_shake()
			
			# Visual feedback
			create_hit_effect(target.global_position)

func calculate_damage() -> float:
	var base = damage
	
	# Get player stats if available
	if player and "stats" in player:
		base *= player.stats.attack_damage / 10.0  # Scale with player attack
	
	# Random variance ±10%
	base *= randf_range(0.9, 1.1)
	
	# Check for crit
	if check_crit():
		var crit_mult = 2.0
		if player and "stats" in player:
			crit_mult = player.stats.crit_multiplier
		base *= crit_mult
	
	return base

func check_crit() -> bool:
	var crit_chance = 0.05  # 5% base
	
	if player and "stats" in player:
		crit_chance = player.stats.crit_chance
	
	return randf() < crit_chance

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
