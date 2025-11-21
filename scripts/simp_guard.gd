extends Enemy
class_name SimpGuard

# ========== SIMP GUARD ==========
# Basic melee enemy in Otaku Fortress
# Wields body pillow as weapon

func _ready():
	# Override base stats
	max_hp = 100.0
	current_hp = max_hp
	damage = 5.0
	move_speed = 60.0  # Slow
	xp_reward = 30.0
	detection_range = 350.0
	attack_range = 50.0
	attack_cooldown = 1.5
	gold_drop_min = 50
	gold_drop_max = 100

	print("Simp Guard spawned!")

	# Add to groups
	add_to_group("enemies")
	add_to_group("simp_guards")

	# Set visual
	if sprite and sprite is ColorRect:
		sprite.scale = Vector2(1.0, 1.0)
		sprite.color = Color(0.7, 0.6, 0.5)  # Brown (body pillow)
		print("✓ Simp Guard visual set")

	# Connect hitbox
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Simp Guard hitbox connected")

	# Initialize state
	current_state = State.IDLE
	attack_timer = 0.0

	# Find player
	player = get_tree().get_first_node_in_group("player")

func die():
	print("Simp Guard defeated!")
	super.die()
