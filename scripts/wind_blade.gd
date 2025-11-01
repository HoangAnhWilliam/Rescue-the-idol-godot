extends Weapon
class_name WindBladeWeapon

# Override base weapon stats
func _init():
	damage = 8.0
	attack_speed = 2.0
	attack_range = 80.0  # Orbit radius
	is_projectile = false

# Wind Blade specific properties
@export var orbit_radius: float = 80.0
@export var rotation_speed: float = 3.0  # Rotations per second
@export var num_blades: int = 1
@export var movement_offset: float = 40.0  # ← TĂNG TỪ 15 → 40 (dễ thấy hơn)

# State
var rotation_angle: float = 0.0
var blades: Array[Node2D] = []
var current_offset: Vector2 = Vector2.ZERO  # Offset động theo movement
var target_offset: Vector2 = Vector2.ZERO

func _ready():
	super._ready()  # Call parent Weapon._ready()
	print("WindBlade ready: ", name)
	print("Movement offset: ", movement_offset)
	
	# Create initial blades
	create_blades()

func _process(delta):
	# Update offset based on player movement
	update_movement_offset(delta)
	
	# Rotate blades around player
	rotation_angle += rotation_speed * TAU * delta
	if rotation_angle >= TAU:
		rotation_angle -= TAU
	
	# Update blade positions
	update_blade_positions()
	
	# Attack cooldown
	attack_cooldown -= delta
	if attack_cooldown <= 0:
		check_blade_hits()
		attack_cooldown = 1.0 / attack_speed

func update_movement_offset(delta: float):
	# Check player exists
	if not player:
		print("ERROR: Player not found in WindBlade!")
		return
	
	# Get player velocity
	var player_velocity = Vector2.ZERO
	if "velocity" in player:
		player_velocity = player.velocity
	
	# Calculate target offset based on velocity
	if player_velocity.length() > 10:  # Player đang di chuyển
		# Normalize và scale theo movement_offset
		target_offset = player_velocity.normalized() * movement_offset
		
		# DEBUG: In ra để check
		if int(Time.get_ticks_msec()) % 500 < 20:  # Print mỗi 0.5s
			print("Moving! Velocity: ", player_velocity.normalized(), " Offset: ", target_offset)
	else:
		# Player đứng yên → về trung tâm
		target_offset = Vector2.ZERO
	
	# Smooth interpolation (lerp) để offset mượt mà
	var lerp_speed = 8.0  # ← TĂNG TỪ 5.0 → 8.0 (nhanh hơn)
	current_offset = current_offset.lerp(target_offset, delta * lerp_speed)
	
	# Apply offset to weapon position
	position = current_offset

func create_blades():
	# Clear existing blades
	for blade in blades:
		if is_instance_valid(blade):
			blade.queue_free()
	blades.clear()
	
	# Create new blades
	for i in range(num_blades):
		var blade = create_single_blade()
		add_child(blade)
		blades.append(blade)
	
	print("Created ", num_blades, " wind blades")

func create_single_blade() -> Node2D:
	# Simple visual for now (ColorRect as placeholder)
	var blade = Node2D.new()
	
	# Visual (cyan rectangle) - TĂNG SIZE ĐỂ DỄ THẤY
	var visual = ColorRect.new()
	visual.size = Vector2(25, 50)  # ← TĂNG từ 20x40 → 25x50
	visual.position = Vector2(-12.5, -25)  # Center pivot
	visual.color = Color(0, 0.9, 1, 0.8)  # Cyan, more visible
	blade.add_child(visual)
	
	# Hitbox
	var area = Area2D.new()
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(25, 50)
	collision.shape = shape
	area.add_child(collision)
	blade.add_child(area)
	
	# Connect signal
	area.body_entered.connect(_on_blade_hit.bind(blade))
	
	return blade

func update_blade_positions():
	var angle_offset = TAU / num_blades  # Evenly space blades
	
	for i in range(blades.size()):
		if i >= num_blades:
			break
		
		if not is_instance_valid(blades[i]):
			continue
		
		var blade = blades[i]
		var angle = rotation_angle + (i * angle_offset)
		
		# Position blade in orbit
		blade.position = Vector2(
			cos(angle) * orbit_radius,
			sin(angle) * orbit_radius
		)
		
		# Rotate blade to face outward
		blade.rotation = angle + PI / 2

func check_blade_hits():
	# Check each blade for enemies in range
	for blade in blades:
		if not is_instance_valid(blade):
			continue
		
		if blade.get_child_count() < 2:
			continue
		
		var area = blade.get_child(1) as Area2D
		if not area:
			continue
		
		# Get overlapping bodies
		var overlapping = area.get_overlapping_bodies()
		
		for body in overlapping:
			if body.is_in_group("enemies") and is_instance_valid(body):
				attack_enemy(body)

func attack_enemy(enemy: CharacterBody2D):
	if not is_instance_valid(enemy):
		return
	
	# Calculate damage
	var final_damage = calculate_damage()
	var is_crit = check_crit()
	
	# Deal damage
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage, global_position, is_crit)
		
		# Camera shake on hit
		if camera:
			if is_crit and camera.has_method("crit_shake"):
				camera.crit_shake()
			elif camera.has_method("small_shake"):
				camera.small_shake()

func _on_blade_hit(body: Node2D, blade: Node2D):
	pass

func upgrade():
	level += 1
	damage *= 1.15
	
	if num_blades < 6:
		num_blades += 1
		create_blades()
	else:
		rotation_speed *= 1.1
		attack_speed *= 1.05
	
	print("WindBlade upgraded to level ", level)
	print("- Damage: ", damage)
	print("- Blades: ", num_blades)
	print("- Rotation speed: ", rotation_speed)

func get_dps() -> float:
	return damage * attack_speed * num_blades

func attack(target: CharacterBody2D):
	pass

func find_closest_enemy() -> CharacterBody2D:
	return null
