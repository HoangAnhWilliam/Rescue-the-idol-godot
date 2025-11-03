extends CharacterBody2D
class_name Enemy

# Stats
@export var max_hp: float = 30.0
@export var damage: float = 5.0
@export var move_speed: float = 50.0
@export var xp_reward: float = 10.0
@export var detection_range: float = 400.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0  # ← THÊM
@export var gold_drop_min: int = 10
@export var gold_drop_max: int = 50

var current_hp: float
var attack_timer: float = 0.0  # ← THÊM
var player: CharacterBody2D = null  # ← ĐỔI từ Player

# State machine
enum State { IDLE, CHASE, ATTACK, DEAD }
var current_state: State = State.IDLE

# References - ĐÃ FIX ↓
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hitbox = $HitboxArea if has_node("HitboxArea") else null

#Preload damage number scene
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")

func _ready():
	print("Enemy ready: ", name)
	
	current_hp = max_hp
	add_to_group("enemies")
	
	# Connect hitbox với safety check
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Hitbox connected for ", name)
	else:
		print("WARNING: No hitbox for ", name)

func _physics_process(delta):
	if current_state == State.DEAD:
		return
	
	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta
	
	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)  # ← THÊM delta

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Don't detect invisible player
	if "is_invisible" in player and player.is_invisible:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.CHASE
		print(name, " started chasing player")

func chase_player(delta):
	if not player:
		current_state = State.IDLE
		return

	# Stop chasing if player becomes invisible
	if "is_invisible" in player and player.is_invisible:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	if distance < attack_range:
		current_state = State.ATTACK
		return

	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update sprite direction
	update_sprite()

func perform_attack(delta):  # ← THÊM delta parameter
	if not player:
		current_state = State.IDLE
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return
	
	# Stop moving
	velocity = Vector2.ZERO
	
	# Attack with cooldown
	if attack_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			print(name, " attacked player!")
			attack_timer = attack_cooldown

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount
	
	print(name, " took ", amount, " damage. HP: ", current_hp, "/", max_hp)
	
	# Spawn damage number
	spawn_damage_number(amount, is_crit)
	
	# Spawn hit particles
	spawn_hit_particle(is_crit)
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Check again after await
			sprite.modulate = Color.WHITE
	
	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 200
	
	if current_hp <= 0:
		die()

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		print("ERROR: Damage number scene not loaded!")
		return
	
	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -20)
	
	# Add to scene root để không bị ảnh hưởng khi enemy die
	get_tree().root.add_child(damage_num)
	
	# Setup damage number
	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

func spawn_hit_particle(is_crit: bool = false):
	if not hit_particle_scene:
		print("WARNING: Hit particle scene not loaded!")
		return
	
	var particle = hit_particle_scene.instantiate()
	particle.global_position = global_position
	
	# Add to scene root
	get_tree().root.add_child(particle)
	
	# Set color based on crit
	if particle.has_method("set_color_from_damage"):
		particle.set_color_from_damage(is_crit)

func spawn_death_particle():
	if not death_particle_scene:
		print("WARNING: Death particle scene not loaded!")
		return
	
	var particle = death_particle_scene.instantiate()
	particle.global_position = global_position
	
	# Add to scene root
	get_tree().root.add_child(particle)
	
	# Set color based on enemy type
	if particle.has_method("set_color_for_enemy"):
		particle.set_color_for_enemy(name)

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print(name, " died!")

	# Spawn death particle effect
	spawn_death_particle()

	# Increment player kill counter
	if player and "total_kills" in player:
		player.total_kills += 1
		print("💀 Kill count: ", player.total_kills)

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

	# Drop items
	attempt_drop_items()

func attempt_drop_items():
	# Gold drop (100% chance now, random amount)
	var gold_amount = randi_range(gold_drop_min, gold_drop_max)
	spawn_gold(gold_amount)

	# Rare drop (1% base, affected by lucky)
	var rare_chance = 0.01 * get_player_lucky()
	if randf() < rare_chance:
		spawn_rare_item()

func get_player_lucky() -> float:
	# Check if player exists and has lucky property
	if not player:
		return 1.0
	
	# Dùng "in" thay vì has()
	if "lucky" in player:
		return player.lucky
	
	# Default
	return 1.0

func spawn_gold(amount: int):
	# Give gold directly to player (can change to pickup item later)
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
	else:
		print("Would drop ", amount, " gold")

func spawn_rare_item():
	# TODO: Instantiate rare item pickup later
	print("Would drop rare item")

func _on_hitbox_entered(body):
	# Check if body is player
	if body.is_in_group("player"):
		# Damage player on collision
		if body.has_method("take_damage") and attack_timer <= 0:
			body.take_damage(damage)
			attack_timer = attack_cooldown  # Prevent spam damage
			print(name, " collided with player!")

	# Also damage buff skeletons if we collide with them
	elif body.is_in_group("buff_skeletons"):
		if body.has_method("take_damage") and attack_timer <= 0:
			body.take_damage(damage, global_position)
			attack_timer = attack_cooldown
			print(name, " collided with buff skeleton!")

func update_sprite():
	if not sprite:
		return
	
	if velocity.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = velocity.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if velocity.x > 0 else 1
