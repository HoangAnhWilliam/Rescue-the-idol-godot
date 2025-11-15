extends Enemy
class_name SkeletonCamel

# Skeleton Camel specific mechanics
enum ChargeState { IDLE, WINDUP, CHARGING, RECOVER }
var charge_state: ChargeState = ChargeState.IDLE
var charge_cooldown: float = 10.0
var charge_timer: float = 0.0
var charge_damage: float = 25.0
var charge_windup_time: float = 0.5
var charge_windup_timer: float = 0.0
var charge_speed: float = 300.0
var charge_direction: Vector2 = Vector2.ZERO

var spit_cooldown: float = 5.0
var spit_timer: float = 0.0
var spit_damage: float = 10.0
var spit_range: float = 300.0

var is_enraged: bool = false
var base_speed: float = 45.0
var enraged_speed: float = 67.5

# Projectile scene
var spit_projectile_scene: PackedScene

func _ready():
	# Override base stats
	max_hp = 80.0
	current_hp = max_hp
	damage = 15.0
	move_speed = base_speed
	xp_reward = 25.0
	detection_range = 450.0
	attack_range = 60.0
	attack_cooldown = 1.5

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Load projectile scene
	spit_projectile_scene = preload("res://scenes/projectiles/spit_projectile.tscn")

	print("Skeleton Camel spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if charge_timer > 0:
		charge_timer -= delta
	if spit_timer > 0:
		spit_timer -= delta

	# Check for enrage
	check_enrage()

	# Handle charge states
	match charge_state:
		ChargeState.WINDUP:
			handle_windup(delta)
			return
		ChargeState.CHARGING:
			handle_charging(delta)
			return
		ChargeState.RECOVER:
			handle_recover(delta)
			return

	# Normal AI
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)

func check_enrage():
	if not player:
		return

	# Enrage when player HP < 30%
	if player.has_method("get_current_hp") and player.has_method("get_max_hp"):
		var player_hp_percent = player.get_current_hp() / player.get_max_hp()
		if player_hp_percent < 0.3 and not is_enraged:
			enter_enrage()

func enter_enrage():
	is_enraged = true
	move_speed = enraged_speed
	charge_cooldown = 5.0

	# Visual: Red eyes
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)

	print("Skeleton Camel ENRAGED!")

func perform_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)
	if distance > detection_range:
		current_state = State.IDLE
		return

	# Try charge attack
	if charge_timer <= 0 and distance > attack_range:
		start_charge()
		return

	# Try spit attack
	if spit_timer <= 0 and distance > attack_range and distance <= spit_range:
		spit_attack()
		return

	# Melee attack
	if distance <= attack_range:
		velocity = Vector2.ZERO
		if attack_timer <= 0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				attack_timer = attack_cooldown
	else:
		current_state = State.CHASE

func start_charge():
	charge_state = ChargeState.WINDUP
	charge_windup_timer = charge_windup_time
	velocity = Vector2.ZERO

	# Calculate charge direction
	if player:
		charge_direction = (player.global_position - global_position).normalized()

	print("Skeleton Camel entered WINDUP state")

func handle_windup(delta):
	charge_windup_timer -= delta
	velocity = Vector2.ZERO

	# Visual: Flash or grow slightly
	if sprite and int(charge_windup_timer * 10) % 2 == 0:
		sprite.modulate = Color.WHITE
	elif sprite:
		sprite.modulate = Color(0.8, 0.7, 0.5) if not is_enraged else Color(1.5, 0.5, 0.5)

	if charge_windup_timer <= 0:
		charge_state = ChargeState.CHARGING
		print("Skeleton Camel CHARGING!")

func handle_charging(delta):
	velocity = charge_direction * charge_speed
	move_and_slide()

	# Check for player hit
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < 40.0:  # Hit radius
			hit_player_with_charge()

	# Stop charging after distance or time
	if velocity.length() < 10.0:  # Hit wall or stopped
		charge_state = ChargeState.RECOVER
		charge_timer = charge_cooldown

func hit_player_with_charge():
	if not player or not player.has_method("take_damage"):
		return

	player.take_damage(charge_damage)

	# Knockback
	var knockback_dir = charge_direction
	if player.has_method("apply_knockback"):
		player.apply_knockback(knockback_dir * 150.0)

	charge_state = ChargeState.RECOVER
	charge_timer = charge_cooldown

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.3, 0.3)

	print("Skeleton Camel hit player with charge: ", charge_damage, " damage!")

func handle_recover(delta):
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.3).timeout
	charge_state = ChargeState.IDLE
	current_state = State.CHASE

func spit_attack():
	if not player or not spit_projectile_scene:
		return

	var projectile = spit_projectile_scene.instantiate()
	projectile.global_position = global_position
	projectile.direction = (player.global_position - global_position).normalized()
	projectile.speed = 200.0
	projectile.damage = spit_damage
	projectile.apply_slow = true
	projectile.slow_amount = 0.3
	projectile.slow_duration = 3.0

	get_parent().add_child(projectile)

	spit_timer = spit_cooldown
	print("Skeleton Camel spit attack!")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			if is_enraged:
				sprite.modulate = Color(1.5, 0.5, 0.5)
			else:
				sprite.modulate = Color(0.8, 0.7, 0.5)

	# Knockback
	if from_position != Vector2.ZERO and charge_state == ChargeState.IDLE:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 150

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	charge_state = ChargeState.IDLE
	set_physics_process(false)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	print("Skeleton Camel died")
