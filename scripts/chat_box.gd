extends PanelContainer
class_name ChatBox

## Toggleable chat box for boss dialogue, system messages, and player chat
## Press ENTER to show/hide. Boss messages show as floating popups

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var message_log: VBoxContainer = $VBoxContainer/ScrollContainer/MessageLog
@onready var chat_input: LineEdit = $VBoxContainer/ChatInput

const MAX_MESSAGES: int = 50

# Toggle state
var is_chat_open: bool = false
var original_position: Vector2
var hidden_offset: Vector2 = Vector2(350, 0)  # Slide off-screen to the right

# Color coding by sender type
var sender_colors := {
	"System": Color(1.0, 0.84, 0.0),         # Gold
	"Player": Color(0.2, 1.0, 0.2),          # Green
	"DarkMiku": Color(0.6, 0.2, 0.8),        # Purple
	"FireDragon": Color(1.0, 0.3, 0.0),      # Orange
	"DespairMiku": Color(0.0, 0.85, 1.0),    # Cyan
	"VampireLord": Color(0.8, 0.0, 0.0),     # Red
	"Miku": Color(0.0, 0.85, 1.0),           # Cyan
	"Enemy": Color(0.8, 0.8, 0.8),           # White
}

func _ready() -> void:
	add_to_group("chat_box")

	# IMPORTANT: ChatBox must work even when game is paused (for /pause and /continue commands)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Setup chat input
	if chat_input:
		chat_input.placeholder_text = "Type here..."
		chat_input.text_submitted.connect(_on_chat_submitted)

	# Enable mouse scroll for chat messages
	if scroll_container:
		scroll_container.mouse_filter = Control.MOUSE_FILTER_PASS
		scroll_container.follow_focus = false

	if message_log:
		message_log.mouse_filter = Control.MOUSE_FILTER_PASS

	# Store original position
	original_position = position

	# Start hidden (off-screen to the right)
	position = original_position + hidden_offset
	modulate.a = 0.0
	is_chat_open = false

	# Welcome message (will be added but not shown until opened)
	add_message("System", "Press T to open chat", "System")

	print("=== Chat Box Initialized (Toggle Mode) ===")


func toggle_chat() -> void:
	"""Toggle chat visibility with slide animation"""

	if is_chat_open:
		close_chat()
	else:
		open_chat()


func open_chat() -> void:
	"""Open chat with slide-in animation"""

	if is_chat_open:
		return

	is_chat_open = true

	# Slide in from right
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_BACK)

	tween.tween_property(self, "position", original_position, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)

	await tween.finished

	# Focus input
	if chat_input:
		chat_input.grab_focus()


func close_chat() -> void:
	"""Close chat with slide-out animation"""

	if not is_chat_open:
		return

	# Release focus first
	if chat_input and chat_input.has_focus():
		chat_input.release_focus()

	is_chat_open = false

	# Slide out to right
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	tween.tween_property(self, "position", original_position + hidden_offset, 0.25)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)


func add_message(sender: String, text: String, sender_type: String = "System") -> void:
	"""Add a new message to the chat log with color-coded sender"""

	# Auto-open chat for boss/system messages (not player messages)
	if sender_type in ["System", "DarkMiku", "DespairMiku", "FireDragon", "VampireLord"] and sender_type != "Player":
		if not is_chat_open:
			open_chat()

	# Create rich text label for message
	var message_label := RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.scroll_active = false
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_label.custom_minimum_size.x = 260  # Fit within chat box width

	# Get sender color
	var color: Color = sender_colors.get(sender_type, Color.WHITE)
	var color_hex: String = color.to_html(false)

	# Format: [Sender]: Message
	var formatted_text := "[color=#%s][%s][/color]: %s" % [
		color_hex,
		sender,
		text
	]

	message_label.text = formatted_text

	# Add to message log
	if message_log:
		message_log.add_child(message_label)

		# Auto-scroll to bottom
		await get_tree().process_frame
		if scroll_container:
			scroll_container.scroll_vertical = int(scroll_container.get_v_scroll_bar().max_value)

		# Limit total messages (prevent memory issues)
		while message_log.get_child_count() > MAX_MESSAGES:
			var oldest := message_log.get_child(0)
			oldest.queue_free()


func _on_chat_submitted(text: String) -> void:
	"""Handle chat input submission"""

	if text.strip_edges().is_empty():
		# Empty submit = just clear input, don't close chat
		return

	# Check if command (starts with /)
	if text.begins_with("/"):
		process_command(text)
	else:
		# Normal player message
		add_message("Player", text, "Player")

	# Clear input and keep focus
	if chat_input:
		chat_input.text = ""
		chat_input.grab_focus()

	# NOTE: Chat stays open after sending message (changed from auto-close)


func process_command(text: String) -> void:
	"""Process slash commands - Routes to CheatCommands system"""

	# Special local commands
	if text.begins_with("/clear"):
		clear_chat()
		return

	# Route all other commands to CheatCommands singleton
	var cheat_commands = get_node_or_null("/root/CheatCommands")
	if cheat_commands:
		cheat_commands.process_command(text)
	else:
		add_message("System", "ERROR: CheatCommands not set up. Add to Autoload in Project Settings", "System")
		print("❌ ChatBox: CheatCommands singleton not available - add to Autoload!")


func clear_chat() -> void:
	"""Clear all chat messages"""

	if message_log:
		for child in message_log.get_children():
			child.queue_free()
		add_message("System", "Chat cleared", "System")


func _input(event: InputEvent) -> void:
	"""Handle input for chat toggle and mouse wheel scroll"""

	# Handle mouse wheel scrolling when chat is open
	if is_chat_open and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if scroll_container:
				scroll_container.scroll_vertical -= 30
				get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if scroll_container:
				scroll_container.scroll_vertical += 30
				get_viewport().set_input_as_handled()

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				# Only toggle chat if NOT typing in chat input
				if chat_input and chat_input.has_focus():
					# Player is typing, don't toggle chat
					return

				# Toggle chat open/close with T key
				if not is_chat_open:
					open_chat()
					get_viewport().set_input_as_handled()
				else:
					close_chat()
					get_viewport().set_input_as_handled()

			KEY_ESCAPE:
				# Close chat with ESC
				if is_chat_open:
					close_chat()
					get_viewport().set_input_as_handled()


# Global helper function for any script to send messages
static func send_chat_message(sender: String, text: String, sender_type: String, tree: SceneTree) -> void:
	"""Static helper to send chat messages from any script"""

	var chat_box := tree.get_first_node_in_group("chat_box") as ChatBox
	if chat_box:
		chat_box.add_message(sender, text, sender_type)

		# Show boss dialogue as floating popup
		if sender_type in ["DarkMiku", "DespairMiku", "FireDragon", "VampireLord"]:
			chat_box.show_floating_message(sender, text, sender_type)


func show_floating_message(sender: String, text: String, sender_type: String) -> void:
	"""Show important message as floating popup (for boss dialogue)"""

	# Create floating label
	var popup := Label.new()
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup.add_theme_font_size_override("font_size", 24)

	# Get color
	var color: Color = sender_colors.get(sender_type, Color.WHITE)
	popup.add_theme_color_override("font_color", color)

	# Format text
	popup.text = "[%s]: %s" % [sender, text]

	# Add outline for better visibility
	popup.add_theme_color_override("font_outline_color", Color.BLACK)
	popup.add_theme_constant_override("outline_size", 2)

	# Position at center-top
	popup.z_index = 1000
	popup.set_anchors_preset(Control.PRESET_CENTER_TOP)
	popup.offset_top = 150
	popup.custom_minimum_size = Vector2(600, 60)

	# Add to scene
	get_tree().root.add_child(popup)

	# Fade in
	popup.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.3)

	# Wait
	await get_tree().create_timer(3.5).timeout

	# Fade out
	tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 0.5)
	await tween.finished

	popup.queue_free()
