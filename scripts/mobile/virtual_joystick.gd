extends Control
class_name VirtualJoystick

## Virtual Joystick for mobile touch controls
## Provides 8-direction movement input with smooth analog values

# Joystick configuration
@export var outer_radius: float = 70.0  # Half of 140px
@export var inner_radius: float = 30.0  # Half of 60px
@export var deadzone: float = 0.2

# Visual properties
@export var outer_color: Color = Color(0.2, 0.2, 0.2, 0.4)
@export var outer_border_color: Color = Color(0.8, 0.8, 0.8, 0.6)
@export var outer_border_width: float = 3.0
@export var inner_color: Color = Color(1, 1, 1, 0.9)
@export var pressed_inner_color: Color = Color(0.8, 0.8, 0.8, 0.95)

# Output
var output: Vector2 = Vector2.ZERO
var is_pressed: bool = false

# Internal
var touch_index: int = -1
var stick_position: Vector2 = Vector2.ZERO
var center_position: Vector2 = Vector2.ZERO

# Debug
var debug_enabled: bool = true

signal joystick_input(direction: Vector2)
signal joystick_pressed
signal joystick_released


func _ready() -> void:
	# Set minimum size
	custom_minimum_size = Vector2(outer_radius * 2, outer_radius * 2)

	# Center position is always the center of this control
	center_position = size / 2
	stick_position = center_position

	# Make sure we receive input
	mouse_filter = Control.MOUSE_FILTER_STOP

	if debug_enabled:
		print("=== Virtual Joystick Initialized ===")
		print("Outer Radius: ", outer_radius)
		print("Inner Radius: ", inner_radius)
		print("Deadzone: ", deadzone)
		print("===================================")


func _draw() -> void:
	# Draw outer circle (background)
	draw_circle(center_position, outer_radius, outer_color)

	# Draw outer border
	draw_arc(center_position, outer_radius, 0, TAU, 64, outer_border_color, outer_border_width, true)

	# Draw inner stick
	var current_inner_color = pressed_inner_color if is_pressed else inner_color
	draw_circle(stick_position, inner_radius, current_inner_color)

	# Draw direction indicator lines (subtle)
	if is_pressed and output.length() > deadzone:
		var indicator_color = Color(1, 1, 1, 0.3)
		draw_line(center_position, stick_position, indicator_color, 2.0, true)


func _process(_delta: float) -> void:
	# Emit continuous input while pressed
	if is_pressed and output.length() > 0:
		joystick_input.emit(output)


func _gui_input(event: InputEvent) -> void:
	# Handle touch events
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_touch_start(event.index, event.position)
		else:
			_on_touch_end(event.index)
	elif event is InputEventScreenDrag:
		_on_touch_move(event.index, event.position)

	# Handle mouse events (for PC testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_mouse_start(event.position)
			else:
				_on_mouse_end()
	elif event is InputEventMouseMotion:
		if is_pressed and touch_index == -1:  # Mouse mode
			_on_mouse_move(event.position)


func _on_touch_start(index: int, pos: Vector2) -> void:
	if touch_index != -1:
		return  # Already tracking a touch

	touch_index = index
	is_pressed = true
	_update_stick_position(pos)
	joystick_pressed.emit()

	if debug_enabled:
		print("[Joystick] Touch started at ", pos)


func _on_touch_move(index: int, pos: Vector2) -> void:
	if index != touch_index:
		return

	_update_stick_position(pos)


func _on_touch_end(index: int) -> void:
	if index != touch_index:
		return

	_reset_joystick()

	if debug_enabled:
		print("[Joystick] Touch released")


func _on_mouse_start(pos: Vector2) -> void:
	is_pressed = true
	_update_stick_position(pos)
	joystick_pressed.emit()

	if debug_enabled:
		print("[Joystick] Mouse pressed at ", pos)


func _on_mouse_move(pos: Vector2) -> void:
	_update_stick_position(pos)


func _on_mouse_end() -> void:
	_reset_joystick()

	if debug_enabled:
		print("[Joystick] Mouse released")


func _update_stick_position(touch_pos: Vector2) -> void:
	# Calculate direction from center
	var direction = touch_pos - center_position
	var distance = direction.length()

	# Clamp to outer radius
	if distance > outer_radius:
		direction = direction.normalized() * outer_radius

	# Update stick visual position
	stick_position = center_position + direction

	# Calculate output (normalized to -1 to 1)
	output = direction / outer_radius

	# Apply deadzone
	if output.length() < deadzone:
		output = Vector2.ZERO
	else:
		# Smooth deadzone application
		var length = output.length()
		output = output.normalized() * ((length - deadzone) / (1.0 - deadzone))

	# Clamp output
	output = output.limit_length(1.0)

	queue_redraw()

	if debug_enabled and output.length() > 0:
		print("[Joystick] Direction: ", _round_vector(output, 2))


func _reset_joystick() -> void:
	is_pressed = false
	touch_index = -1
	stick_position = center_position
	output = Vector2.ZERO
	joystick_released.emit()
	queue_redraw()


func get_output() -> Vector2:
	"""Get current joystick output (normalized -1 to 1)"""
	return output


func get_direction_8way() -> Vector2:
	"""Get 8-directional snapped output"""
	if output.length() < deadzone:
		return Vector2.ZERO

	var angle = output.angle()
	var snapped_angle = snapped(angle, PI / 4)  # 45 degree increments
	return Vector2.from_angle(snapped_angle)


func is_active() -> bool:
	"""Check if joystick is currently being used"""
	return is_pressed and output.length() > deadzone


func set_debug(enabled: bool) -> void:
	debug_enabled = enabled


# Utility function for Vector2
func _round_vector(v: Vector2, decimals: int) -> Vector2:
	var mult = pow(10, decimals)
	return Vector2(
		round(v.x * mult) / mult,
		round(v.y * mult) / mult
	)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		center_position = size / 2
		if not is_pressed:
			stick_position = center_position
		queue_redraw()
