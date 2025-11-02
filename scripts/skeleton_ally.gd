extends CharacterBody2D
class_name SkeletonAlly

# Friendly ally - fights for player
# Not an enemy!

# Stats
@export var max_hp: float = 100.0
@export var move_speed: float = 80.0
@export var damage: float = 15.0

var current_hp: float
var player: CharacterBody2D = null

# Lifetime (10 minutes = 600 seconds)
const LIFETIME: float = 600.0
var time_alive: float = 0.0
var time_remaining: float = LIFETIME

# Combat
var shoot_timer: float = 0.0
var shoot_cooldown: float = 1.5
var shoot_range: float = 300.0
var target_enemy: Node2D = null
var arrow_scene = preload("res://scenes/projectiles/arrow.tscn")

# State
enum State { FOLLOW, ATTACK }
var current_state: State = State.FOLLOW

# Follow behavior
var follow_distance: float = 100.0  # Stay this far from player
var max_follow_distance: float = 400.0  # Teleport if too far

# Visual
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var timer_label: Label = null

func _ready():
	current_hp = max_hp
	add_to_group("allies")

	# Yellow/blue color
	if sprite:
		sprite.color = Color.CYAN

	# Create timer label
	create_timer_label()

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERROR: No player found for ally skeleton!")
		queue_free()
		return

	print("✨ Ally Skeleton spawned! Will fight for 10 minutes.")

func _physics_process(delta):
	# Update lifetime
	time_alive += delta
	time_remaining = LIFETIME - time_alive

	# Update timer display
	update_timer_display()

	# Check if lifetime expired
	if time_remaining <= 0:
		expire()
		return

	# Update shoot timer
	if shoot_timer > 0:
		shoot_timer -= delta

	# Check player distance
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance > max_follow_distance:
			# Teleport to player
			global_position = player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
			print("Ally skeleton teleported to player")

	# Find target
	find_target()

	# Behavior
	match current_state:
		State.FOLLOW:
			follow_player(delta)
		State.ATTACK:
			attack_enemy(delta)

func follow_player(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# If target found, switch to attack
	if target_enemy:
		current_state = State.ATTACK
		return

	# Too close - don't move
	if distance < follow_distance * 0.8:
		velocity = Vector2.ZERO
		return

	# Too far - move towards player
	if distance > follow_distance:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
		update_sprite()
	else:
		velocity = Vector2.ZERO

func attack_enemy(delta):
	# If no target, go back to follow
	if not target_enemy or not is_instance_valid(target_enemy):
		target_enemy = null
		current_state = State.FOLLOW
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(target_enemy.global_position)

	# Target too far, find new target or follow
	if distance > shoot_range * 1.5:
		target_enemy = null
		current_state = State.FOLLOW
		return

	# In range - stop and shoot
	velocity = Vector2.ZERO

	# Shoot
	if shoot_timer <= 0 and distance <= shoot_range:
		shoot_arrow()
		shoot_timer = shoot_cooldown

func find_target():
	# Find closest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		target_enemy = null
		return

	var closest: Node2D = null
	var min_distance: float = INF

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = global_position.distance_to(enemy.global_position)
		if distance < min_distance and distance <= shoot_range:
			closest = enemy
			min_distance = distance

	target_enemy = closest

func shoot_arrow():
	if not arrow_scene:
		print("ERROR: Arrow scene not loaded!")
		return

	if not target_enemy:
		return

	# Create arrow
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position

	# Set direction towards target
	var direction = (target_enemy.global_position - global_position).normalized()
	arrow.direction = direction

	# Set damage
	if "damage" in arrow:
		arrow.damage = damage

	# Set type to damage arrow (targets enemies)
	if "arrow_type" in arrow:
		arrow.arrow_type = 0  # ArrowType.DAMAGE

	# Add to scene
	get_tree().root.add_child(arrow)

	print("🏹 Ally Skeleton shot enemy!")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	print("Ally Skeleton took ", amount, " damage. HP: ", current_hp, "/", max_hp)

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			sprite.modulate = Color.WHITE

	if current_hp <= 0:
		die()

func die():
	print("💀 Ally Skeleton died!")

	# Visual effect
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func expire():
	print("⏰ Ally Skeleton's time expired!")

	# Different visual effect
	if sprite:
		sprite.modulate = Color.YELLOW
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func create_timer_label():
	timer_label = Label.new()
	timer_label.position = Vector2(-30, -60)
	timer_label.add_theme_color_override("font_color", Color.CYAN)
	add_child(timer_label)

func update_timer_display():
	if not timer_label:
		return

	var minutes = int(time_remaining / 60)
	var seconds = int(time_remaining) % 60
	timer_label.text = "%d:%02d ⏱️" % [minutes, seconds]

	# Flash when time is low
	if time_remaining < 30:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif time_remaining < 60:
		timer_label.add_theme_color_override("font_color", Color.YELLOW)

func update_sprite():
	if not sprite:
		return

	if velocity.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = velocity.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if velocity.x > 0 else 1
