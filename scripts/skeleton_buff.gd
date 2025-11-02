extends CharacterBody2D
class_name SkeletonBuff

# Not an enemy! Friendly unit
# Does NOT extend Enemy class

# Stats
@export var max_hp: float = 50.0
@export var move_speed: float = 40.0
@export var wander_range: float = 100.0

var current_hp: float
var player: CharacterBody2D = null

# State
enum State { WANDER, FLEE, PURCHASED }
var current_state: State = State.WANDER

# Wander
var wander_timer: float = 0.0
var wander_interval: float = 3.0
var wander_direction: Vector2 = Vector2.ZERO
var spawn_position: Vector2

# Shooting buffs
var shoot_timer: float = 0.0
var shoot_interval: float = 5.0  # Shoot every 5 seconds
var arrow_scene = preload("res://scenes/projectiles/arrow.tscn")

# Purchase
const PURCHASE_COST: int = 1000000
var can_be_purchased: bool = true
var player_nearby: bool = false
var interaction_range: float = 80.0

# Visual
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var purchase_label: Label = null

# Signals
signal purchased(skeleton)

func _ready():
	current_hp = max_hp
	spawn_position = global_position
	add_to_group("buff_skeletons")

	# Green/bright color
	if sprite:
		sprite.color = Color.GREEN_YELLOW

	# Create purchase indicator label
	create_purchase_indicator()

	# Find player
	player = get_tree().get_first_node_in_group("player")

	print("Buff Skeleton spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.PURCHASED:
		return  # Will be removed/converted

	# Update timers
	shoot_timer -= delta
	wander_timer -= delta

	# Check player proximity
	check_player_proximity()

	match current_state:
		State.WANDER:
			wander(delta)
			shoot_buff_arrow()
		State.FLEE:
			flee(delta)

func wander(delta):
	# Change direction periodically
	if wander_timer <= 0:
		# Random direction
		var angle = randf() * TAU
		wander_direction = Vector2(cos(angle), sin(angle))
		wander_timer = wander_interval

	# Don't wander too far from spawn
	var distance_from_spawn = global_position.distance_to(spawn_position)
	if distance_from_spawn > wander_range:
		wander_direction = (spawn_position - global_position).normalized()

	# Move
	velocity = wander_direction * move_speed
	move_and_slide()

	# Update sprite
	update_sprite()

func flee(delta):
	if not player:
		current_state = State.WANDER
		return

	# Run away from player
	var direction = (global_position - player.global_position).normalized()
	velocity = direction * move_speed * 1.5  # Faster when fleeing
	move_and_slide()

	# Update sprite
	update_sprite()

	# Stop fleeing if far enough
	var distance = global_position.distance_to(player.global_position)
	if distance > interaction_range * 2:
		current_state = State.WANDER

func shoot_buff_arrow():
	if shoot_timer > 0:
		return

	if not arrow_scene:
		print("ERROR: Arrow scene not loaded!")
		return

	if not player:
		return

	# Random buff type (25% each)
	var buff_types = [1, 2, 3, 4]  # HP_REGEN, SPEED_BOOST, DAMAGE_BOOST, INVISIBILITY
	var buff_type = buff_types[randi() % buff_types.size()]

	# Create arrow
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position

	# Shoot towards player
	var direction = (player.global_position - global_position).normalized()
	arrow.direction = direction

	# Set as buff arrow
	if "arrow_type" in arrow:
		arrow.arrow_type = buff_type

	# Set speed slower
	if "speed" in arrow:
		arrow.speed = 150.0  # Slower so player can see it coming

	# Add to scene
	get_tree().root.add_child(arrow)

	# Reset timer
	shoot_timer = shoot_interval

	var buff_names = ["❤️ HP", "⚡ Speed", "🗡️ Damage", "👻 Invis"]
	print("💚 Buff Skeleton shot ", buff_names[buff_type - 1], " arrow!")

func check_player_proximity():
	if not player or not can_be_purchased:
		if purchase_label:
			purchase_label.visible = false
		return

	var distance = global_position.distance_to(player.global_position)
	player_nearby = distance <= interaction_range

	# Show/hide purchase indicator
	if purchase_label:
		purchase_label.visible = player_nearby

	# Handle purchase input
	if player_nearby and Input.is_action_just_pressed("interact"):  # E key
		attempt_purchase()

func attempt_purchase():
	if not can_be_purchased or not player:
		return

	# Check if player has enough gold
	if not player.has_method("has_gold") or not player.has_method("remove_gold"):
		print("ERROR: Player doesn't have gold methods!")
		return

	if not player.has_gold(PURCHASE_COST):
		print("❌ Not enough gold! Need ", PURCHASE_COST)
		flash_red()
		return

	# Deduct gold
	if player.remove_gold(PURCHASE_COST):
		print("✅ Purchased Buff Skeleton for ", PURCHASE_COST, " gold!")
		convert_to_ally()

func convert_to_ally():
	can_be_purchased = false
	current_state = State.PURCHASED

	# Emit signal
	purchased.emit(self)

	# Spawn ally skeleton
	var ally_scene = load("res://scenes/enemies/skeleton_ally.tscn")
	if ally_scene:
		var ally = ally_scene.instantiate()
		ally.global_position = global_position
		get_parent().add_child(ally)
		print("✨ Converted to Ally Skeleton!")

	# Remove self
	queue_free()

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	# Don't die, just flee
	print("Buff Skeleton was attacked! Fleeing...")
	current_state = State.FLEE

	# Visual feedback
	if sprite:
		sprite.modulate = Color.YELLOW
		await get_tree().create_timer(0.2).timeout
		if sprite:
			sprite.modulate = Color.WHITE

func flash_red():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		if sprite:
			sprite.modulate = Color.WHITE

func create_purchase_indicator():
	purchase_label = Label.new()
	purchase_label.text = "[E] Buy: 1M 💰"
	purchase_label.position = Vector2(-40, -50)
	purchase_label.add_theme_color_override("font_color", Color.YELLOW)
	purchase_label.visible = false
	add_child(purchase_label)

func update_sprite():
	if not sprite:
		return

	if velocity.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = velocity.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if velocity.x > 0 else 1
