extends Enemy
class_name SkeletonBad

# Ranged attack settings
@export var shoot_range: float = 250.0  # Distance to start shooting
@export var shoot_cooldown: float = 2.0  # Time between shots
@export var arrow_damage: float = 8.0
@export var keep_distance: float = 200.0  # Try to maintain this distance

var shoot_timer: float = 0.0
var arrow_scene = preload("res://scenes/projectiles/arrow.tscn")

func _ready():
	super._ready()

	# Override stats for ranged enemy
	max_hp = 20.0  # Lower HP than zombie
	current_hp = max_hp
	move_speed = 60.0  # Slightly faster
	damage = 0.0  # No melee damage
	xp_reward = 15.0  # More XP
	gold_drop_min = 15
	gold_drop_max = 75

	# Adjust ranges
	detection_range = 350.0
	attack_range = shoot_range

	# Color - black skeleton
	if sprite:
		sprite.color = Color.BLACK

	print("Bad Skeleton ready: ", name)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update shoot timer
	if shoot_timer > 0:
		shoot_timer -= delta

	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta

	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player_ranged(delta)
		State.ATTACK:
			perform_ranged_attack(delta)

func chase_player_ranged(delta):
	if not player:
		current_state = State.IDLE
		return

	# Stop chasing if player becomes invisible
	if "is_invisible" in player and player.is_invisible:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	# Too far - give up
	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	# In shooting range - switch to attack
	if distance <= shoot_range:
		current_state = State.ATTACK
		return

	# Move towards player (but not too close)
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update sprite direction
	update_sprite()

func perform_ranged_attack(delta):
	if not player:
		current_state = State.IDLE
		return

	# Stop attacking if player becomes invisible
	if "is_invisible" in player and player.is_invisible:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	# Too close - back away
	if distance < keep_distance:
		var direction = (global_position - player.global_position).normalized()
		velocity = direction * move_speed * 0.8
		move_and_slide()
		update_sprite()
		return

	# Too far - chase
	if distance > shoot_range * 1.2:
		current_state = State.CHASE
		return

	# In range - stop and shoot
	velocity = Vector2.ZERO

	# Shoot
	if shoot_timer <= 0:
		shoot_arrow()
		shoot_timer = shoot_cooldown

func shoot_arrow():
	if not arrow_scene:
		print("ERROR: Arrow scene not loaded!")
		return

	if not player:
		return

	# Create arrow
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position

	# Set direction towards player
	var direction = (player.global_position - global_position).normalized()
	arrow.direction = direction

	# Set damage
	if arrow.has("damage"):
		arrow.damage = arrow_damage

	# Set type to damage arrow
	if arrow.has("arrow_type"):
		arrow.arrow_type = 0  # ArrowType.DAMAGE

	# Add to scene
	get_tree().root.add_child(arrow)

	print("🏹 Bad Skeleton shot arrow!")

# Override perform_attack to prevent melee
func perform_attack(delta):
	perform_ranged_attack(delta)
