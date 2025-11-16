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
const PURCHASE_COST: int = 500
var can_be_purchased: bool = true
var player_nearby: bool = false
var interaction_range: float = 80.0
var debug_cooldown: float = 0.0  # Prevent debug spam

# Visual
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hurtbox = $HurtboxArea if has_node("HurtboxArea") else null
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

	# Connect hurtbox for taking damage from enemies
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_entered)
		hurtbox.area_entered.connect(_on_area_entered)
		print("✓ Buff Skeleton hurtbox connected")

	# Create purchase indicator label
	create_purchase_indicator()

	# Find player
	player = get_tree().get_first_node_in_group("player")

	print("💚 Buff Skeleton spawned at ", global_position)

func _physics_process(delta):
	if current_state == State.PURCHASED:
		return  # Will be removed/converted

	# Update timers
	shoot_timer -= delta
	wander_timer -= delta
	debug_cooldown -= delta

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
	var was_nearby = player_nearby
	player_nearby = distance <= interaction_range

	# Debug: Show distance when player is close (with cooldown to prevent spam)
	if distance < interaction_range * 1.5 and debug_cooldown <= 0:
		print("📏 Distance to player: ", snapped(distance, 0.1), " / ", interaction_range, " | Nearby: ", player_nearby)
		debug_cooldown = 1.0  # Print every 1 second

	# Show/hide purchase indicator
	if purchase_label:
		purchase_label.visible = player_nearby

		# Debug when label visibility changes
		if player_nearby and not was_nearby:
			print("✅ Player entered purchase range! Label shown. Press E to buy!")
		elif not player_nearby and was_nearby:
			print("❌ Player left purchase range")

func _unhandled_input(event):
	# Handle E key press for purchase
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		if player_nearby and can_be_purchased:
			print("⌨️ E key pressed! Player nearby: ", player_nearby, " Can purchase: ", can_be_purchased)
			attempt_purchase()
			get_viewport().set_input_as_handled()
		elif not player_nearby:
			print("⌨️ E pressed but player not nearby (distance > ", interaction_range, ")")
		elif not can_be_purchased:
			print("⌨️ E pressed but cannot purchase (already purchased)")

func attempt_purchase():
	if not can_be_purchased or not player:
		print("❌ Cannot purchase: can_be_purchased=", can_be_purchased, " player=", player != null)
		return

	print("🔍 Attempting purchase...")
	print("  Player has has_gold method: ", player.has_method("has_gold"))
	print("  Player has remove_gold method: ", player.has_method("remove_gold"))

	# Check if player has enough gold
	if not player.has_method("has_gold") or not player.has_method("remove_gold"):
		print("ERROR: Player doesn't have gold methods!")

		# Try alternative method names
		if player.has_method("get_total_gold") and player.has_method("spend_gold"):
			print("✓ Found alternative methods: get_total_gold and spend_gold")
			var player_gold = player.get_total_gold()
			print("  Player has ", player_gold, " gold, needs ", PURCHASE_COST)

			if player_gold >= PURCHASE_COST:
				if player.spend_gold(PURCHASE_COST):
					print("✅ Purchased Buff Skeleton for ", PURCHASE_COST, " gold!")
					convert_to_ally()
					return
			else:
				print("❌ Not enough gold! Need ", PURCHASE_COST)
				flash_red()
				return
		else:
			print("❌ No gold methods found at all!")
			return

	var player_gold = player.has_gold(PURCHASE_COST)
	print("  Player has enough gold: ", player_gold)

	if not player_gold:
		print("❌ Not enough gold! Need ", PURCHASE_COST)
		flash_red()
		return

	# Deduct gold
	if player.remove_gold(PURCHASE_COST):
		print("✅ Purchased Buff Skeleton for ", PURCHASE_COST, " gold!")
		convert_to_ally()
	else:
		print("❌ Failed to remove gold!")

func convert_to_ally():
	print("🔄 Starting conversion to ally...")
	can_be_purchased = false
	current_state = State.PURCHASED

	# Emit signal
	purchased.emit(self)
	print("  ✓ Emitted purchased signal")

	# Hide purchase label
	if purchase_label:
		purchase_label.visible = false
		print("  ✓ Hidden purchase label")

	# Spawn ally skeleton
	print("  🔍 Loading skeleton_ally.tscn...")
	var ally_scene = load("res://scenes/enemies/skeleton_ally.tscn")
	if ally_scene:
		print("  ✓ Scene loaded successfully!")
		var ally = ally_scene.instantiate()
		print("  ✓ Ally instantiated!")
		ally.global_position = global_position
		print("  ✓ Position set to: ", global_position)

		var parent = get_parent()
		if parent:
			parent.add_child(ally)
			print("  ✓ Ally added to parent: ", parent.name)
			print("✨ Converted to Ally Skeleton successfully!")
		else:
			print("  ❌ ERROR: No parent found!")
	else:
		print("  ❌ ERROR: Failed to load skeleton_ally.tscn!")

	# Visual effect before removal
	if sprite:
		sprite.modulate = Color.YELLOW
		print("  ✓ Changed color to yellow")

	# Remove self after short delay
	print("  🗑️ Removing Buff Skeleton...")
	await get_tree().create_timer(0.2).timeout
	queue_free()
	print("  ✓ Buff Skeleton removed")

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	# Take actual damage
	current_hp -= amount
	print("💔 Buff Skeleton took ", amount, " damage! HP: ", current_hp, "/", max_hp)

	# Flee when attacked
	current_state = State.FLEE

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		if sprite:
			sprite.modulate = Color.WHITE

	# Die if HP reaches 0
	if current_hp <= 0:
		die()

func die():
	print("💀 Buff Skeleton was killed!")
	can_be_purchased = false

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func flash_red():
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.3).timeout
		if sprite:
			sprite.modulate = Color.WHITE

func create_purchase_indicator():
	purchase_label = Label.new()
	purchase_label.text = "[E] Buy: 500 💰"
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

# Collision callbacks for taking damage
func _on_hurtbox_entered(body: Node2D):
	# Get damage from enemies
	if body.is_in_group("enemies"):
		# Get damage from enemy
		var damage = body.damage if "damage" in body else 5.0
		take_damage(damage, body.global_position)
		print("⚔️ Buff Skeleton hit by enemy melee!")

func _on_area_entered(area: Area2D):
	# Get hit by arrows
	if area.name.contains("Arrow") or area.is_class("Arrow"):
		# Check if it's a damage arrow (not buff arrow)
		if "arrow_type" in area and area.arrow_type == 0:  # DAMAGE type
			var damage = area.damage if "damage" in area else 5.0
			take_damage(damage, area.global_position)
			print("🏹 Buff Skeleton hit by arrow!")
