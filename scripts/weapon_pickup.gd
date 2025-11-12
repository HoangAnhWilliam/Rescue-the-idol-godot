extends Area2D
class_name WeaponPickup

## Weapon Pickup - Collectible weapon that adds to inventory

@export var weapon_id: String = "miku_sword"
@export var weapon_name: String = "Miku Sword"

# Magnet system
const MAGNET_RANGE: float = 100.0
const MAGNET_SPEED: float = 250.0
const INITIAL_BOUNCE_SPEED: float = 120.0
const BOUNCE_DECAY: float = 0.93

# Despawn
const DESPAWN_TIME: float = 30.0

var player: CharacterBody2D = null
var is_attracted: bool = false
var velocity: Vector2 = Vector2.ZERO
var time_alive: float = 0.0

@onready var sprite: ColorRect = $ColorRect if has_node("ColorRect") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

func _ready():
	add_to_group("pickups")
	add_to_group("weapon_pickups")

	player = get_tree().get_first_node_in_group("player")

	# Start rotation animation
	start_rotation_animation()

	# Initial bounce
	var angle = randf() * TAU
	velocity = Vector2(cos(angle), sin(angle)) * INITIAL_BOUNCE_SPEED

	# Connect collision
	body_entered.connect(_on_body_entered)

	print("⚔️ Weapon pickup spawned: %s (%s)" % [weapon_name, weapon_id])

func start_rotation_animation():
	if not sprite:
		return

	# Continuous rotation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(sprite, "rotation", TAU, 3.0)
	tween.tween_property(sprite, "rotation", 0.0, 0.0)

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
	# Add to inventory
	var inventory = get_tree().get_first_node_in_group("inventory")

	if inventory and inventory.has_method("add_item"):
		# Get weapon stats (default values for now)
		var weapon_data = {
			"weapon_name": weapon_name,
			"weapon_id": weapon_id,
			"damage": 10.0,
			"attack_speed": 1.0
		}

		var success = inventory.add_item(
			inventory.ItemType.WEAPON,
			weapon_id,
			1,
			weapon_data
		)

		if success:
			ParticleManager.create_hit_effect(global_position, Color(0.8, 0.8, 0.8))
			print("✅ Added weapon to inventory: %s" % weapon_name)
			queue_free()
			return

	# Fallback: Direct equip if no inventory
	print("⚠️ No inventory found - weapon pickup failed")
	queue_free()

func despawn():
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()
