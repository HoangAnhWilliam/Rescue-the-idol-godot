extends Enemy
class_name WhiteKnight

# ========== WHITE KNIGHT ==========
# Tank enemy in Otaku Fortress
# Has high HP and blocks attacks with cardboard shield

var is_blocking: bool = false
var block_cooldown: float = 0.0
const BLOCK_CD: float = 5.0
const BLOCK_DURATION: float = 2.0

func _ready():
	# Override base stats
	max_hp = 200.0  # Tank
	current_hp = max_hp
	damage = 10.0
	move_speed = 50.0  # Very slow
	xp_reward = 60.0
	detection_range = 350.0
	attack_range = 50.0
	attack_cooldown = 2.0
	gold_drop_min = 100
	gold_drop_max = 200

	print("White Knight spawned!")

	# Add to groups
	add_to_group("enemies")
	add_to_group("white_knights")

	# Set visual
	if sprite and sprite is ColorRect:
		sprite.scale = Vector2(1.3, 1.3)  # Bigger (tank)
		sprite.color = Color(0.8, 0.8, 0.9)  # Silver (cardboard armor)
		print("✓ White Knight visual set")

	# Connect hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ White Knight hitbox connected")

	# Initialize state
	current_state = State.IDLE
	attack_timer = 0.0

	# Find player
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update timers
	if attack_timer > 0:
		attack_timer -= delta
	if block_cooldown > 0:
		block_cooldown -= delta

	# Random blocking
	if not is_blocking and block_cooldown <= 0 and randf() < 0.01:
		activate_block()

	# Use base Enemy logic
	super._physics_process(delta)

func activate_block():
	"""Activate defensive block"""
	print("🛡️ White Knight: M'LADY! (blocking)")

	is_blocking = true
	block_cooldown = BLOCK_CD

	# Visual: Brighter (shield up)
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 1.5)

	# Duration
	await get_tree().create_timer(BLOCK_DURATION).timeout

	is_blocking = false

	if sprite:
		sprite.modulate = Color.WHITE

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	"""Override to block damage"""

	# Block reduces damage by 75%
	if is_blocking:
		amount *= 0.25
		print("🛡️ White Knight blocked! Damage reduced to %.1f" % amount)

	# Call parent take_damage
	super.take_damage(amount, from_position, is_crit)

func die():
	print("White Knight defeated!")

	# Chance to drop Energy Drink (heal item)
	if randf() < 0.3:
		print("💊 Dropped Energy Drink!")
		# TODO: Spawn health pickup

	super.die()
