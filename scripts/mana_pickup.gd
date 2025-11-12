extends Area2D
class_name ManaPickup

## Mana Pickup - Restores player mana or adds to inventory

@export var mana_amount: float = 15.0

# Magnet system
const MAGNET_RANGE: float = 100.0
const MAGNET_SPEED: float = 250.0
const INITIAL_BOUNCE_SPEED: float = 120.0
const BOUNCE_DECAY: float = 0.93

# Visual properties
const PULSE_SCALE_MIN: float = 1.0
const PULSE_SCALE_MAX: float = 1.3
const PULSE_DURATION: float = 0.4

# Despawn
const DESPAWN_TIME: float = 20.0

var player: CharacterBody2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0

@onready var sprite: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready():
	add_to_group("pickups")
	add_to_group("mana_pickups")

	player = get_tree().get_first_node_in_group("player")
	start_pulse_animation()

	var angle = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * INITIAL_BOUNCE_SPEED

	body_entered.connect(_on_body_entered)

	print("💧 Mana pickup spawned: +%.0f Mana" % mana_amount)

func start_pulse_animation():
	if not sprite:
		return

	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "scale", Vector2(PULSE_SCALE_MAX, PULSE_SCALE_MAX), PULSE_DURATION)
	tween.tween_property(sprite, "scale", Vector2(PULSE_SCALE_MIN, PULSE_SCALE_MIN), PULSE_DURATION)

func _physics_process(delta):
	time_alive += delta

	if time_alive >= DESPAWN_TIME:
		despawn()
		return

	if not is_attracted and player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		if distance < MAGNET_RANGE:
			is_attracted = true
			velocity = Vector2.ZERO

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
			inventory.ItemType.MANA_POTION,
			"mana_potion",
			1,
			{"mana_amount": mana_amount}
		)

		if success:
			ParticleManager.create_hit_effect(global_position, Color(0, 0.5, 1))
			print("✅ Added mana potion to inventory")
			queue_free()
			return

	# Fallback: Direct mana restore
	if "current_mana" in player_body and "stats" in player_body:
		player_body.current_mana = min(player_body.current_mana + mana_amount, player_body.stats.max_mana)
		if player_body.has_signal("mana_changed"):
			player_body.mana_changed.emit(player_body.current_mana, player_body.stats.max_mana)
		print("✅ Player restored: +%.0f Mana" % mana_amount)

	ParticleManager.create_hit_effect(global_position, Color(0, 0.5, 1))
	queue_free()

func despawn():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
