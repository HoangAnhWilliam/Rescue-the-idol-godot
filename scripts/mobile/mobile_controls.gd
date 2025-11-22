extends CanvasLayer
class_name MobileControls

## Main Mobile Controls Manager
## Coordinates joystick, buttons, and integrates with game systems

# References to control components
@onready var joystick: VirtualJoystick = $ControlsContainer/LeftSide/VirtualJoystick
@onready var skill_button: MobileButton = $ControlsContainer/RightSide/ButtonsContainer/SkillButton
@onready var pause_button: MobileButton = $ControlsContainer/RightSide/ButtonsContainer/TopRow/PauseButton
@onready var interact_button: MobileButton = $ControlsContainer/RightSide/ButtonsContainer/TopRow/InteractButton

# Game references
var player: CharacterBody2D = null
var inventory_system: Node = null

# Configuration
@export var enabled: bool = true
@export var skill_cooldown: float = 60.0  # Miku's Blessing cooldown
@export var auto_hide_interact: bool = true
@export var safe_area_margin: float = 20.0

# Screen info
var screen_size: Vector2 = Vector2.ZERO
var scale_factor: float = 1.0
var safe_area: Rect2 = Rect2()

# State
var nearest_interactable: Node = null
var is_mobile_device: bool = false
var debug_enabled: bool = true

# Signals
signal mobile_input_direction(direction: Vector2)
signal skill_activated
signal pause_requested
signal interaction_triggered


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
	inventory_system = get_tree().get_first_node_in_group("inventory")

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
	if not joystick or not skill_button or not pause_button or not interact_button:
		push_error("MobileControls: Missing control references!")
		return

	# Connect joystick signals
	joystick.joystick_input.connect(_on_joystick_input)
	joystick.joystick_pressed.connect(_on_joystick_pressed)
	joystick.joystick_released.connect(_on_joystick_released)

	# Connect button signals
	skill_button.button_pressed.connect(_on_skill_pressed)
	skill_button.cooldown_finished.connect(_on_skill_cooldown_finished)
	skill_button.set_cooldown_duration(skill_cooldown)

	pause_button.button_pressed.connect(_on_pause_pressed)

	interact_button.button_pressed.connect(_on_interact_pressed)
	interact_button.hide_button()  # Hidden by default

	# Apply scale
	_apply_scale()


func _apply_scale() -> void:
	# Scale all controls based on screen size
	if joystick:
		joystick.scale = Vector2(scale_factor, scale_factor)

	if skill_button:
		skill_button.scale = Vector2(scale_factor, scale_factor)

	if pause_button:
		pause_button.scale = Vector2(scale_factor, scale_factor)

	if interact_button:
		interact_button.scale = Vector2(scale_factor, scale_factor)


func _apply_safe_areas() -> void:
	# Get the controls container
	var controls_container = get_node_or_null("ControlsContainer")
	if not controls_container:
		return

	# Apply margins based on safe area
	var left_margin = max(safe_area.position.x, safe_area_margin)
	var right_margin = max(screen_size.x - (safe_area.position.x + safe_area.size.x), safe_area_margin)
	var bottom_margin = max(screen_size.y - (safe_area.position.y + safe_area.size.y), safe_area_margin)
	var top_margin = max(safe_area.position.y, safe_area_margin)

	# Apply to left side (joystick)
	var left_side = get_node_or_null("ControlsContainer/LeftSide")
	if left_side:
		left_side.offset_left = left_margin
		left_side.offset_bottom = -bottom_margin - 20

	# Apply to right side (buttons)
	var right_side = get_node_or_null("ControlsContainer/RightSide")
	if right_side:
		right_side.offset_right = -right_margin
		right_side.offset_bottom = -bottom_margin - 20


func _on_viewport_resized() -> void:
	_update_screen_info()
	_apply_scale()
	_apply_safe_areas()


func _process(delta: float) -> void:
	if not enabled:
		return

	# Check for nearby interactables
	_check_interactables()


func _physics_process(_delta: float) -> void:
	if not enabled or not player:
		return

	# Send joystick input to player
	if joystick and joystick.is_active():
		var direction = joystick.get_output()
		mobile_input_direction.emit(direction)

		# Directly set player input (if player has mobile_input property)
		if player.has_method("set_mobile_input"):
			player.set_mobile_input(direction)
		elif "mobile_input_vector" in player:
			player.mobile_input_vector = direction


# === JOYSTICK CALLBACKS ===

func _on_joystick_input(direction: Vector2) -> void:
	if debug_enabled:
		pass  # Continuous logging is too verbose


func _on_joystick_pressed() -> void:
	if debug_enabled:
		print("[MobileControls] Joystick pressed")


func _on_joystick_released() -> void:
	if debug_enabled:
		print("[MobileControls] Joystick released")

	# Clear player input
	if player:
		if player.has_method("set_mobile_input"):
			player.set_mobile_input(Vector2.ZERO)
		elif "mobile_input_vector" in player:
			player.mobile_input_vector = Vector2.ZERO


# === BUTTON CALLBACKS ===

func _on_skill_pressed() -> void:
	if debug_enabled:
		print("[MobileControls] Skill button pressed")

	skill_activated.emit()

	# Trigger Miku's Blessing if available
	_activate_miku_blessing()

	# Start cooldown
	skill_button.start_cooldown(skill_cooldown)


func _activate_miku_blessing() -> void:
	"""Activate Miku's Blessing special skill"""
	if not player:
		return

	# Check if player has the skill method
	if player.has_method("use_miku_blessing"):
		player.use_miku_blessing()
	elif player.has_method("apply_miku_buffs"):
		# Fallback to buff application
		player.apply_miku_buffs()

		if debug_enabled:
			print("Miku's Blessing activated!")
			print("Cooldown started: ", skill_cooldown, "s")
	else:
		# Generic skill activation
		if debug_enabled:
			print("Skill activated (no specific handler)")


func _on_skill_cooldown_finished() -> void:
	if debug_enabled:
		print("[MobileControls] Skill ready!")


func _on_pause_pressed() -> void:
	if debug_enabled:
		print("[MobileControls] Pause button pressed")

	pause_requested.emit()

	# Toggle pause
	get_tree().paused = not get_tree().paused


func _on_interact_pressed() -> void:
	if debug_enabled:
		print("[MobileControls] Interact button pressed")

	interaction_triggered.emit()

	# Trigger interaction with nearest interactable
	if nearest_interactable:
		if nearest_interactable.has_method("interact"):
			nearest_interactable.interact()

			if debug_enabled:
				print("Interaction executed with: ", nearest_interactable.name)
		elif nearest_interactable.has_method("_on_interact"):
			nearest_interactable._on_interact()


func _check_interactables() -> void:
	"""Check for nearby interactable objects and show/hide interact button"""
	if not player or not auto_hide_interact:
		return

	# Find nearest interactable
	var interactables = get_tree().get_nodes_in_group("interactables")
	nearest_interactable = null
	var min_distance = 100.0  # Interaction range

	for interactable in interactables:
		if not is_instance_valid(interactable):
			continue

		var distance = player.global_position.distance_to(interactable.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_interactable = interactable

	# Show/hide interact button
	if nearest_interactable:
		interact_button.show_button()

		# Update button icon based on interactable type
		if nearest_interactable.has_method("get_interact_prompt"):
			interact_button.set_icon(nearest_interactable.get_interact_prompt())
		elif "interact_prompt" in nearest_interactable:
			interact_button.set_icon(nearest_interactable.interact_prompt)
	else:
		interact_button.hide_button()


# === PUBLIC API ===

func get_movement_input() -> Vector2:
	"""Get current movement input from joystick"""
	if joystick and enabled:
		return joystick.get_output()
	return Vector2.ZERO


func is_skill_available() -> bool:
	"""Check if skill button is available (not on cooldown)"""
	if skill_button:
		return skill_button.is_available()
	return false


func get_skill_cooldown() -> float:
	"""Get remaining skill cooldown time"""
	if skill_button:
		return skill_button.get_cooldown_remaining()
	return 0.0


func show_interact_button(prompt: String = "E") -> void:
	"""Manually show interact button with custom prompt"""
	if interact_button:
		interact_button.set_icon(prompt)
		interact_button.show_button()


func hide_interact_button() -> void:
	"""Manually hide interact button"""
	if interact_button:
		interact_button.hide_button()


func set_enabled(value: bool) -> void:
	"""Enable or disable mobile controls"""
	enabled = value
	visible = value


func set_debug(value: bool) -> void:
	"""Enable or disable debug logging"""
	debug_enabled = value
	if joystick:
		joystick.set_debug(value)
	if skill_button:
		skill_button.set_debug(value)
	if pause_button:
		pause_button.set_debug(value)
	if interact_button:
		interact_button.set_debug(value)


func _print_debug_info() -> void:
	if not debug_enabled:
		return

	print("")
	print("=== Mobile Controls Initialized ===")
	print("Screen Size: ", screen_size)
	print("Scale Factor: ", scale_factor)
	print("Touch Available: ", is_mobile_device or DisplayServer.is_touchscreen_available())
	print("Safe Area: ", safe_area)
	print("Virtual Joystick ready at: ", joystick.global_position if joystick else "N/A")
	print("Mobile Buttons ready")
	print("Hotbar adapted for touch")
	print("Responsive UI active")
	print("=====================================")
	print("")
