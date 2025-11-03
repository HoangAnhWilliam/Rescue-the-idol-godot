extends Area2D
class_name Arrow

# Arrow properties
@export var speed: float = 300.0
@export var damage: float = 10.0
@export var lifetime: float = 5.0
@export var pierce_count: int = 0  # How many enemies it can pierce (0 = destroy on first hit)

# Movement
var direction: Vector2 = Vector2.RIGHT
var traveled_time: float = 0.0
var hit_targets: Array = []

# Arrow type
enum ArrowType {
	DAMAGE,      # Normal damage arrow
	BUFF_HP,     # HP Regen buff
	BUFF_SPEED,  # Speed boost buff
	BUFF_DAMAGE, # Damage boost buff
	BUFF_INVIS   # Invisibility buff
}

@export var arrow_type: ArrowType = ArrowType.DAMAGE

# Visual
@onready var sprite = null

# Buff type mapping
var buff_type_map = {
	ArrowType.BUFF_HP: 0,      # BuffManager.BuffType.HP_REGEN
	ArrowType.BUFF_SPEED: 1,   # BuffManager.BuffType.SPEED_BOOST
	ArrowType.BUFF_DAMAGE: 2,  # BuffManager.BuffType.DAMAGE_BOOST
	ArrowType.BUFF_INVIS: 3    # BuffManager.BuffType.INVISIBILITY
}

func _ready():
	# Setup collision
	body_entered.connect(_on_body_entered)

	# Create visual if doesn't exist
	if not sprite:
		create_default_sprite()

	# Rotate arrow to face direction
	rotation = direction.angle()

	print("Arrow spawned: ", ArrowType.keys()[arrow_type])

func _process(delta):
	# Move arrow
	position += direction * speed * delta

	# Track lifetime
	traveled_time += delta
	if traveled_time >= lifetime:
		queue_free()

func create_default_sprite():
	# Create a simple rectangle to represent arrow
	var rect = ColorRect.new()
	rect.size = Vector2(20, 4)
	rect.position = Vector2(-10, -2)

	# Color based on arrow type
	match arrow_type:
		ArrowType.DAMAGE:
			rect.color = Color.RED
		ArrowType.BUFF_HP:
			rect.color = Color.GREEN
		ArrowType.BUFF_SPEED:
			rect.color = Color.YELLOW
		ArrowType.BUFF_DAMAGE:
			rect.color = Color.ORANGE
		ArrowType.BUFF_INVIS:
			rect.color = Color(0.5, 0.5, 1.0, 0.5)  # Light blue transparent

	add_child(rect)
	sprite = rect

func set_direction(new_direction: Vector2):
	direction = new_direction.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D):
	# Ignore if already hit this target
	if body in hit_targets:
		return

	# Mark as hit
	hit_targets.append(body)

	# Handle based on arrow type
	if arrow_type == ArrowType.DAMAGE:
		handle_damage_arrow(body)
	else:
		handle_buff_arrow(body)

	# Destroy arrow if pierce limit reached
	if hit_targets.size() > pierce_count:
		queue_free()

func handle_damage_arrow(body: Node2D):
	# Damage enemies
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		print("Arrow hit enemy for ", damage, " damage")

	# Damage player
	elif body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		print("Arrow hit player for ", damage, " damage")

	# Damage buff skeletons (they can be hit by bad skeleton arrows)
	elif body.is_in_group("buff_skeletons") and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		print("Arrow hit buff skeleton for ", damage, " damage")

func handle_buff_arrow(body: Node2D):
	# Only apply buff to player
	if not body.is_in_group("player"):
		return

	# Get buff manager
	var buff_manager = body.get_node_or_null("BuffManager")
	if not buff_manager:
		print("ERROR: No BuffManager on player!")
		return

	# Get buff type
	var buff_type = buff_type_map.get(arrow_type, -1)
	if buff_type == -1:
		print("ERROR: Unknown buff type!")
		return

	# Apply buff
	if buff_manager.has_method("apply_buff"):
		buff_manager.apply_buff(buff_type)
		print("✓ Buff arrow applied buff type: ", buff_type)
