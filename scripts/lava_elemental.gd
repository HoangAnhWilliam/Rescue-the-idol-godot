extends Enemy
class_name LavaElemental

# Lava Elemental specific mechanics
var burst_cooldown: float = 10.0
var burst_timer: float = 0.0
var burst_damage: float = 18.0
var burst_radius: float = 250.0

var spit_cooldown: float = 6.0
var spit_timer: float = 0.0
var spit_damage: float = 15.0
var spit_range: float = 300.0

var territorial_check_range: float = 200.0

# Lava pool scene
var lava_pool_scene: PackedScene

# Flash effect
var canvas_modulate: CanvasModulate = null

func _ready():
	# Override base stats
	max_hp = 70.0
	current_hp = max_hp
	damage = 15.0
	move_speed = 50.0
	xp_reward = 30.0
	detection_range = 400.0
	attack_range = 250.0
	attack_cooldown = 1.5

	add_to_group("enemies")
	add_to_group("volcanic_enemies")  # For territorial check
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Load lava pool scene
	lava_pool_scene = preload("res://scenes/projectiles/lava_pool.tscn")

	# Get or create canvas modulate for flash effect
	setup_canvas_modulate()

	print("Lava Elemental spawned at ", global_position)

func setup_canvas_modulate():
	# Check if CanvasModulate exists in scene
	var root = get_tree().root
	for child in root.get_children():
		if child is CanvasModulate:
			canvas_modulate = child
			return

	# Create if doesn't exist
	canvas_modulate = CanvasModulate.new()
	canvas_modulate.color = Color.WHITE
	root.add_child(canvas_modulate)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if burst_timer > 0:
		burst_timer -= delta
	if spit_timer > 0:
		spit_timer -= delta

	# Check for territorial aggression
	check_territorial_targets()

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func check_territorial_targets():
	# Check for enemies from other biomes nearby
	var enemies = get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue

		# Skip other volcanic enemies
		if enemy.is_in_group("volcanic_enemies"):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= territorial_check_range:
			# 50% chance to target enemy instead of player
			if randf() < 0.5 and spit_timer <= 0:
				print("Lava Elemental attacking intruder enemy!")
				shoot_lava_spit_at_target(enemy)
				return

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# Flame burst (close/mid range)
	if burst_timer <= 0 and distance <= burst_radius:
		flame_burst()
		return

	# Lava spit (ranged)
	if spit_timer <= 0 and distance <= spit_range:
		shoot_lava_spit_at_target(player)
		return

	# Move closer
	if distance > attack_range:
		current_state = State.CHASE
	else:
		velocity = Vector2.ZERO

func flame_burst():
	print("Lava Elemental FLAME BURST!")

	burst_timer = burst_cooldown

	# Screen flash effect
	flash_screen()

	# Create expanding circle area (visual)
	create_burst_visual()

	# Damage player if in range
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance <= burst_radius:
			if player.has_method("take_damage"):
				player.take_damage(burst_damage)
				print("Flame burst hit player: ", burst_damage, " damage!")

	# Damage other enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy == self or not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance <= burst_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(burst_damage * 0.5, global_position)

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.6, 0.4)

func flash_screen():
	if not canvas_modulate:
		return

	canvas_modulate.color = Color.WHITE
	var tween = create_tween()
	tween.tween_property(canvas_modulate, "color", Color.WHITE, 0.0)
	tween.tween_property(canvas_modulate, "color", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func create_burst_visual():
	# Create a temporary red circle that expands
	var circle = ColorRect.new()
	circle.color = Color(1.0, 0.2, 0.0, 0.5)
	circle.size = Vector2(10, 10)
	circle.position = global_position - circle.size / 2
	get_parent().add_child(circle)

	# Animate expansion
	var tween = create_tween()
	tween.tween_property(circle, "size", Vector2(burst_radius * 2, burst_radius * 2), 0.5)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.5)
	tween.tween_callback(circle.queue_free)

func shoot_lava_spit_at_target(target: Node2D):
	if not target or not lava_pool_scene:
		return

	# Create lava projectile (reuse snowball scene with different params)
	var projectile_scene = preload("res://scenes/projectiles/snowball.tscn")
	var projectile = projectile_scene.instantiate()

	projectile.global_position = global_position
	projectile.direction = (target.global_position - global_position).normalized()
	projectile.speed = 200.0
	projectile.damage = spit_damage
	projectile.is_lava = true  # Custom flag
	projectile.lava_pool_scene = lava_pool_scene

	get_parent().add_child(projectile)

	spit_timer = spit_cooldown
	print("Lava Elemental spit lava!")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.YELLOW
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color(1.0, 0.3, 0.0)

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 160

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	set_physics_process(false)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	# Death effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_death_effect(global_position)

	print("Lava Elemental died")
