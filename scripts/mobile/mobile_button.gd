extends Control
class_name MobileButton

## Touch-enabled button for mobile controls
## Supports tap, hold, and cooldown states

enum ButtonType {
	SKILL,      # Main skill button with cooldown
	PAUSE,      # Pause game
	INTERACT    # Context-sensitive interaction
}

# Configuration
@export var button_type: ButtonType = ButtonType.SKILL
@export var button_size: Vector2 = Vector2(80, 80)
@export var icon_text: String = ""  # Text displayed on button
@export var cooldown_duration: float = 0.0  # 0 = no cooldown

# Visual properties
@export var normal_color: Color = Color(0, 0.85, 1, 0.8)  # Cyan for skill
@export var pressed_color: Color = Color(0, 0.6, 0.8, 0.9)
@export var disabled_color: Color = Color(0.5, 0.5, 0.5, 0.6)
@export var border_color: Color = Color(1, 1, 1, 0.6)
@export var border_width: float = 2.0

# State
var is_pressed: bool = false
var is_on_cooldown: bool = false
var current_cooldown: float = 0.0
var is_visible_button: bool = true  # For interact button visibility
var touch_index: int = -1

# Debug
var debug_enabled: bool = true

signal button_pressed
signal button_released
signal cooldown_finished


func _ready() -> void:
	custom_minimum_size = button_size
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Set default colors based on button type
	_apply_button_style()

	if debug_enabled:
		print("=== Mobile Button Initialized ===")
		print("Type: ", ButtonType.keys()[button_type])
		print("Size: ", button_size)
		print("Cooldown: ", cooldown_duration, "s")
		print("=================================")


func _apply_button_style() -> void:
	match button_type:
		ButtonType.SKILL:
			normal_color = Color(0, 0.85, 1, 0.8)  # Cyan
			icon_text = "SKILL"
		ButtonType.PAUSE:
			normal_color = Color(0.8, 0.8, 0.8, 0.8)  # Light gray
			button_size = Vector2(60, 60)
			icon_text = "||"
		ButtonType.INTERACT:
			normal_color = Color(1, 0.9, 0.2, 0.8)  # Yellow
			button_size = Vector2(70, 70)
			icon_text = "E"
			is_visible_button = false  # Hidden by default


func _draw() -> void:
	if not is_visible_button:
		return

	var center = size / 2
	var radius = min(size.x, size.y) / 2 - border_width

	# Determine current color
	var current_color: Color
	if is_on_cooldown:
		current_color = disabled_color
	elif is_pressed:
		current_color = pressed_color
	else:
		current_color = normal_color

	# Draw button background (circle)
	draw_circle(center, radius, current_color)

	# Draw border
	draw_arc(center, radius, 0, TAU, 64, border_color, border_width, true)

	# Draw cooldown overlay
	if is_on_cooldown and cooldown_duration > 0:
		var cooldown_progress = current_cooldown / cooldown_duration
		var cooldown_angle = TAU * cooldown_progress
		draw_arc(center, radius - 5, -PI/2, -PI/2 + cooldown_angle, 32, Color(0, 0, 0, 0.5), radius - 10, false)

	# Draw icon/text
	_draw_icon(center)


func _draw_icon(center: Vector2) -> void:
	# Create a simple text label for the icon
	var font = ThemeDB.fallback_font
	var font_size = 16

	if button_type == ButtonType.PAUSE:
		font_size = 24
	elif button_type == ButtonType.INTERACT:
		font_size = 28

	var text_size = font.get_string_size(icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center - text_size / 2 + Vector2(0, font_size / 3)

	var text_color = Color.WHITE
	if is_on_cooldown:
		text_color = Color(0.8, 0.8, 0.8)

	draw_string(font, text_pos, icon_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

	# Draw cooldown time remaining
	if is_on_cooldown and cooldown_duration > 0:
		var time_text = "%.0f" % ceil(current_cooldown)
		var time_size = font.get_string_size(time_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20)
		var time_pos = center - time_size / 2 + Vector2(0, 25)
		draw_string(font, time_pos, time_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color.WHITE)


func _process(delta: float) -> void:
	# Update cooldown
	if is_on_cooldown:
		current_cooldown -= delta
		if current_cooldown <= 0:
			current_cooldown = 0
			is_on_cooldown = false
			cooldown_finished.emit()

			if debug_enabled:
				print("[", ButtonType.keys()[button_type], "] Cooldown finished!")

		queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not is_visible_button:
		return

	# Handle touch events
	if event is InputEventScreenTouch:
		if event.pressed:
			_on_press_start(event.index)
		else:
			_on_press_end(event.index)

	# Handle mouse events (for PC testing)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_on_press_start(-1)
			else:
				_on_press_end(-1)


func _on_press_start(index: int) -> void:
	if is_on_cooldown:
		if debug_enabled:
			print("[", ButtonType.keys()[button_type], "] On cooldown: ", ceil(current_cooldown), "s remaining")
		return

	if touch_index != -1 and index != -1:
		return  # Already tracking a touch

	touch_index = index
	is_pressed = true
	button_pressed.emit()
	queue_redraw()

	if debug_enabled:
		print("[", ButtonType.keys()[button_type], "] Button pressed!")


func _on_press_end(index: int) -> void:
	if index != touch_index and touch_index != -1:
		return

	is_pressed = false
	touch_index = -1
	button_released.emit()
	queue_redraw()


func start_cooldown(duration: float = -1.0) -> void:
	"""Start cooldown timer"""
	var cd = duration if duration > 0 else cooldown_duration

	if cd > 0:
		is_on_cooldown = true
		current_cooldown = cd
		cooldown_duration = cd  # Update stored duration

		if debug_enabled:
			print("[", ButtonType.keys()[button_type], "] Cooldown started: ", cd, "s")

		queue_redraw()


func set_cooldown_duration(duration: float) -> void:
	cooldown_duration = duration


func get_cooldown_remaining() -> float:
	return current_cooldown


func is_available() -> bool:
	"""Check if button can be pressed"""
	return not is_on_cooldown and is_visible_button


func show_button() -> void:
	"""Show the button (for interact button)"""
	is_visible_button = true
	queue_redraw()


func hide_button() -> void:
	"""Hide the button (for interact button)"""
	is_visible_button = false
	is_pressed = false
	touch_index = -1
	queue_redraw()


func set_icon(text: String) -> void:
	"""Change button icon text"""
	icon_text = text
	queue_redraw()


func set_normal_color(color: Color) -> void:
	normal_color = color
	queue_redraw()


func set_debug(enabled: bool) -> void:
	debug_enabled = enabled


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
