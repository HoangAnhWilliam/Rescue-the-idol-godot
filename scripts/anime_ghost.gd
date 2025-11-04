extends CharacterBody2D
class_name AnimeGhost

# Stats
@export var max_hp: float = 20.0
@export var damage: float = 8.0
@export var move_speed: float = 70.0
@export var xp_reward: float = 15.0
@export var detection_range: float = 500.0
@export var preferred_distance_min: float = 150.0  # Khoảng cách ưa thích
@export var preferred_distance_max: float = 250.0
@export var shoot_cooldown: float = 2.0  # Bắn mỗi 2 giây

var current_hp: float
var shoot_timer: float = 0.0
var player: CharacterBody2D = null

# State machine
enum State { IDLE, MAINTAIN_DISTANCE, SHOOT, DEAD }
var current_state: State = State.IDLE

# References
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hitbox = $HitboxArea if has_node("HitboxArea") else null

# Preload scenes
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")
var projectile_scene = preload("res://scenes/enemies/ghost_projectile.tscn")

func _ready():
	print("Anime Ghost ready: ", name)
	
	current_hp = max_hp
	add_to_group("enemies")
	
	# Connect hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Hitbox connected for ", name)

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	# Update shoot timer
	if shoot_timer > 0:
		shoot_timer -= delta
	
	match current_state:
		State.IDLE:
			search_for_player()
		State.MAINTAIN_DISTANCE:
			maintain_distance(delta)
		State.SHOOT:
			perform_shoot(delta)

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.MAINTAIN_DISTANCE
		print(name, " detected player")

func maintain_distance(delta):
	if not player:
		current_state = State.IDLE
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Nếu quá xa → lost player
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return
	
	# Calculate movement direction
	var direction = (player.global_position - global_position).normalized()
	
	if distance < preferred_distance_min:
		# Quá gần → lùi ra (flee)
		velocity = -direction * move_speed
	elif distance > preferred_distance_max:
		# Quá xa → tiến lại gần
		velocity = direction * move_speed
	else:
		# Trong khoảng ưa thích → strafe (di chuyển ngang)
		var perpendicular = Vector2(-direction.y, direction.x)
		velocity = perpendicular * move_speed * 0.5
	
	move_and_slide()
	update_sprite()
	
	# Try to shoot
	if shoot_timer <= 0:
		current_state = State.SHOOT

func perform_shoot(delta):
	if not player:
		current_state = State.IDLE
		return
	
	# Stop moving
	velocity = Vector2.ZERO
	
	# Shoot projectile
	shoot_projectile()
	
	# Reset timer
	shoot_timer = shoot_cooldown
	
	# Back to maintaining distance
	current_state = State.MAINTAIN_DISTANCE

func shoot_projectile():
	if not projectile_scene:
		print("ERROR: Ghost projectile scene not loaded!")
		return
	
	if not player:
		return
	
	# Create projectile
	var projectile = projectile_scene.instantiate()
	projectile.global_position = global_position
	
	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()
	
	# Setup projectile
	if projectile.has_method("setup"):
		projectile.setup(direction, damage)
	
	# Add to scene
	get_tree().root.add_child(projectile)
	
	print(name, " shot projectile at player!")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount
	
	print(name, " took ", amount, " damage. HP: ", current_hp, "/", max_hp)
	
	# Spawn effects
	spawn_damage_number(amount, is_crit)
	spawn_hit_particle(is_crit)
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color.WHITE
	
	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 150  # Lighter knockback than other enemies
	
	if current_hp <= 0:
		die()

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		return
	
	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -20)
	get_tree().root.add_child(damage_num)
	
	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

func spawn_hit_particle(is_crit: bool = false):
	if not hit_particle_scene:
		return
	
	var particle = hit_particle_scene.instantiate()
	particle.global_position = global_position
	get_tree().root.add_child(particle)
	
	if particle.has_method("set_color_from_damage"):
		particle.set_color_from_damage(is_crit)

func spawn_death_particle():
	if not death_particle_scene:
		return
	
	var particle = death_particle_scene.instantiate()
	particle.global_position = global_position
	get_tree().root.add_child(particle)
	
	if particle.has_method("set_color_for_enemy"):
		particle.set_color_for_enemy(name)

func die():
	current_state = State.DEAD
	set_physics_process(false)
	
	print(name, " died!")
	
	# Effects
	spawn_death_particle()
	
	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
		print("Dropped ", xp_reward, " XP")
	
	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()
	
	attempt_drop_items()

func attempt_drop_items():
	var gold_chance = 0.1 * get_player_lucky()
	if randf() < gold_chance:
		spawn_gold(randi_range(5, 15))
	
	var rare_chance = 0.01 * get_player_lucky()
	if randf() < rare_chance:
		spawn_rare_item()

func get_player_lucky() -> float:
	if not player:
		return 1.0
	
	if "lucky" in player:
		return player.lucky
	
	return 1.0

func spawn_gold(amount: int):
	print("Would drop ", amount, " gold")

func spawn_rare_item():
	print("Would drop rare item")

func _on_hitbox_entered(body):
	# Ghost doesn't do melee damage (ranged only)
	# But we can add a small touch damage if needed
	pass

func update_sprite():
	if not sprite:
		return
	
	if velocity.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = velocity.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if velocity.x > 0 else 1
