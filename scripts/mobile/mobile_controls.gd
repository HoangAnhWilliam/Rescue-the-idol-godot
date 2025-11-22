extends CanvasLayer
class_name MobileControls

## Mobile Controls - Only Virtual Joystick
## Simplified for touch-only movement control

# References to control components
@onready var joystick: VirtualJoystick = $JoystickContainer/VirtualJoystick

# Game references
var player: CharacterBody2D = null

# Configuration
@export var enabled: bool = true
@export var safe_area_margin: float = 20.0

# Screen info
var screen_size: Vector2 = Vector2.ZERO
var scale_factor: float = 1.0
var safe_area: Rect2 = Rect2()

# State
var is_mobile_device: bool = false
var debug_enabled: bool = true

# Signals
signal mobile_input_direction(direction: Vector2)


func _ready() -> void:
	# Determine if running on mobile
	is_mobile_device = _detect_mobile_platform()

	# Get screen info
	_update_screen_info()

	# Connect to viewport resize
	get_viewport().size_changed.connect(_on_viewport_resized)

	# Wait for tree to be ready
	await get_tree().process_frame

	# Find game references
	player = get_tree().get_first_node_in_group("player")

	# Setup controls
	_setup_controls()

	# Apply safe areas
	_apply_safe_areas()

	_print_debug_info()


func _detect_mobile_platform() -> bool:
	var os_name = OS.get_name()
	return os_name == "Android" or os_name == "iOS"


func _update_screen_info() -> void:
	screen_size = get_viewport().get_visible_rect().size

	# Calculate scale factor based on base resolution (1280x720)
	var base_height = 720.0
	scale_factor = screen_size.y / base_height

	# Clamp scale factor
	scale_factor = clamp(scale_factor, 0.75, 2.0)

	# Get safe area (for notches/cutouts)
	if is_mobile_device:
		safe_area = DisplayServer.get_display_safe_area()
	else:
		safe_area = Rect2(Vector2.ZERO, screen_size)


func _setup_controls() -> void:
	if not joystick:
		push_error("MobileControls: Joystick not found!")
		return

	# Connect joystick signals
	joystick.joystick_input.connect(_on_joystick_input)
	joystick.joystick_released.connect(_on_joystick_released)

	# Apply scale
	_apply_scale()


func _apply_scale() -> void:
	# Scale joystick based on screen size
	if joystick:
		joystick.scale = Vector2(scale_factor, scale_factor)


func _apply_safe_areas() -> void:
	# Get the joystick container
	var joystick_container = get_node_or_null("JoystickContainer")
	if not joystick_container:
		return

	# Apply margins based on safe area
	var left_margin = max(safe_area.position.x, safe_area_margin)
	var bottom_margin = max(screen_size.y - (safe_area.position.y + safe_area.size.y), safe_area_margin)

	# Position joystick on left side, above hotbar
	joystick_container.offset_left = left_margin + 20
	joystick_container.offset_bottom = -bottom_margin - 120  # Above hotbar


func _on_viewport_resized() -> void:
	_update_screen_info()
	_apply_scale()
	_apply_safe_areas()


func _physics_process(_delta: float) -> void:
	if not enabled or not player:
		return

	# Send joystick input to player
	if joystick and joystick.is_active():
		var direction = joystick.get_output()
		mobile_input_direction.emit(direction)

		# Directly set player input
		if player.has_method("set_mobile_input"):
			player.set_mobile_input(direction)
		elif "mobile_input_vector" in player:
			player.mobile_input_vector = direction


# === JOYSTICK CALLBACKS ===

func _on_joystick_input(direction: Vector2) -> void:
	pass  # Continuous logging is too verbose


func _on_joystick_released() -> void:
	if debug_enabled:
		print("[MobileControls] Joystick released")

	# Clear player input
	if player:
		if player.has_method("set_mobile_input"):
			player.set_mobile_input(Vector2.ZERO)
		elif "mobile_input_vector" in player:
			player.mobile_input_vector = Vector2.ZERO


# === PUBLIC API ===

func get_movement_input() -> Vector2:
	"""Get current movement input from joystick"""
	if joystick and enabled:
		return joystick.get_output()
	return Vector2.ZERO


func set_enabled(value: bool) -> void:
	"""Enable or disable mobile controls"""
	enabled = value
	visible = value


func set_debug(value: bool) -> void:
	"""Enable or disable debug logging"""
	debug_enabled = value
	if joystick:
		joystick.set_debug(value)


func _print_debug_info() -> void:
	if not debug_enabled:
		return

	print("")
	print("=== Mobile Controls Initialized ===")
	print("Screen Size: ", screen_size)
	print("Scale Factor: ", scale_factor)
	print("Touch Available: ", is_mobile_device or DisplayServer.is_touchscreen_available())
	print("Safe Area: ", safe_area)
	print("Virtual Joystick ready")
	print("=====================================")
	print("")
