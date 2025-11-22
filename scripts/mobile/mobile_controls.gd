extends CanvasLayer
class_name MobileControls

## Mobile Controls - Virtual Joystick only
## Simple touch-based movement control

# References
@onready var joystick: VirtualJoystick = $JoystickContainer/VirtualJoystick

# Game references
var player: CharacterBody2D = null

# Configuration
@export var enabled: bool = true

# Debug
var debug_enabled: bool = true


func _ready() -> void:
	print("=== Mobile Controls Initializing ===")

	# Wait for tree to be ready
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("✓ Found player")
	else:
		print("⚠ Player not found")

	# Setup joystick
	if joystick:
		joystick.joystick_released.connect(_on_joystick_released)
		print("✓ Virtual Joystick ready")
		print("  Position: ", joystick.global_position)
		print("  Size: ", joystick.size)
	else:
		print("⚠ Joystick not found!")

	print("=== Mobile Controls Ready ===")


func _physics_process(_delta: float) -> void:
	if not enabled or not player:
		return

	# Get joystick input and send to player
	if joystick and joystick.is_active():
		var direction = joystick.get_output()

		# Set player mobile input
		if "mobile_input_vector" in player:
			player.mobile_input_vector = direction


func _on_joystick_released() -> void:
	# Clear player mobile input when joystick released
	if player and "mobile_input_vector" in player:
		player.mobile_input_vector = Vector2.ZERO

	if debug_enabled:
		print("[MobileControls] Joystick released, input cleared")


func get_movement_input() -> Vector2:
	"""Get current movement input from joystick"""
	if joystick and enabled:
		return joystick.get_output()
	return Vector2.ZERO


func set_enabled(value: bool) -> void:
	"""Enable or disable mobile controls"""
	enabled = value
	visible = value
