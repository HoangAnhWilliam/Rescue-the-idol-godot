extends Enemy
class_name VampireThrall

# ========== VAMPIRE THRALL ==========
# Minion summoned by Vampire Lord
# Weak but numerous

func _ready():
	# Override base stats
	max_hp = 500.0
	current_hp = max_hp
	damage = 10.0
	move_speed = 80.0
	xp_reward = 50.0
	detection_range = 400.0
	attack_range = 50.0
	attack_cooldown = 1.5
	gold_drop_min = 10
	gold_drop_max = 30

	print("Vampire Thrall spawned!")

	# Add to groups
	add_to_group("enemies")
	add_to_group("vampire_thralls")

	# Set visual if ColorRect exists
	if sprite and sprite is ColorRect:
		sprite.scale = Vector2(1.2, 1.2)
		sprite.color = Color(0.6, 0.5, 0.6)  # Pale purple
		print("✓ Vampire Thrall visual set")

	# Connect hitbox if exists
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Vampire Thrall hitbox connected")

	# Initialize state
	current_state = State.IDLE
	attack_timer = 0.0

	# Find player
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta):
	# Use base Enemy logic
	super._physics_process(delta)

func die():
	print("Vampire Thrall defeated!")

	# Use base Enemy death logic
	super.die()

	# Additional visual: Dark purple particles
	if sprite:
		ParticleManager.create_death_explosion(global_position, Color(0.4, 0.2, 0.4), 0.8)
