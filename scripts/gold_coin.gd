extends Area2D
class_name GoldCoin

## Gold Coin Pickup - Adds gold to player or inventory

@export var gold_value: int = 10

# Magnet system
const MAGNET_RANGE: float = 120.0
const MAGNET_SPEED: float = 280.0
const INITIAL_BOUNCE_SPEED: float = 130.0
const BOUNCE_DECAY: float = 0.94

# Despawn
const DESPAWN_TIME: float = 25.0

var player: CharacterBody2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0

@onready var sprite: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready():
	add_to_group("pickups")
	add_to_group("gold_coins")

	player = get_tree().get_first_node_in_group("player")

	# Start spin animation
	start_spin_animation()

	# Initial bounce
	var angle = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * INITIAL_BOUNCE_SPEED

	# Connect collision
	body_entered.connect(_on_body_entered)

	print("💰 Gold coin spawned: %d gold" % gold_value)

func start_spin_animation():
	if not sprite:
		return

	# Continuous rotation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "rotation", TAU, 2.0)
	tween.tween_property(sprite, "rotation", 0.0, 0.0)  # Reset for loop

func _physics_process(delta):
	time_alive += delta

	if time_alive >= DESPAWN_TIME:
		despawn()
		return

	# Check magnet range
	if not is_attracted and player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance < MAGNET_RANGE:
			is_attracted = true
			velocity = Vector2.ZERO

	# Magnet movement
	if is_attracted and player and is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		global_position += direction * MAGNET_SPEED * delta
	elif not is_attracted:
		global_position += velocity * delta
		velocity *= BOUNCE_DECAY

func _on_body_entered(body: Node):
	if body.is_in_group("player"):
		collect(body)

func collect(player_body: CharacterBody2D):
	# Check if inventory system exists (Phase 5.5.4 integration)
	var inventory = get_tree().get_first_node_in_group("inventory")

	if inventory and inventory.has_method("add_item"):
		# Add to inventory
		var success = inventory.add_item(
			inventory.ItemType.GOLD,
			"gold",
			gold_value
		)

		if success:
			ParticleManager.create_hit_effect(global_position, Color(1, 0.84, 0))
			print("✅ Added %d gold to inventory" % gold_value)
			queue_free()
			return

	# Fallback: Direct gold add (if no inventory)
	if player_body.has_method("add_gold"):
		player_body.add_gold(gold_value)
		print("✅ Player gained %d gold!" % gold_value)
	elif "gold" in player_body:
		player_body.gold += gold_value
		if player_body.has_signal("gold_changed"):
			player_body.gold_changed.emit(player_body.gold)
		print("✅ Player gained %d gold!" % gold_value)

	ParticleManager.create_hit_effect(global_position, Color(1, 0.84, 0))
	queue_free()

func despawn():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
