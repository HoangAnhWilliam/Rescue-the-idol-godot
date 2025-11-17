extends PanelContainer
class_name ChatBox

## Roblox-style chat box for boss dialogue, system messages, and player chat
## Displays color-coded messages with sender names

@onready var scroll_container: ScrollContainer = $VBoxContainer/ScrollContainer
@onready var message_log: VBoxContainer = $VBoxContainer/ScrollContainer/MessageLog
@onready var chat_input: LineEdit = $VBoxContainer/ChatInput

const MAX_MESSAGES: int = 50

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

	# Setup chat input
	if chat_input:
		chat_input.placeholder_text = "Type here..."
		chat_input.text_submitted.connect(_on_chat_submitted)

	# Welcome message
	add_message("System", "Game started! Press ENTER to chat.", "System")

	print("=== Chat Box Initialized ===")


func add_message(sender: String, text: String, sender_type: String = "System") -> void:
	"""Add a new message to the chat log with color-coded sender"""

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
		return

	# Check if command (starts with /)
	if text.begins_with("/"):
		process_command(text)
	else:
		# Normal player message
		add_message("Player", text, "Player")

	# Clear input
	if chat_input:
		chat_input.text = ""
		chat_input.release_focus()


func process_command(text: String) -> void:
	"""Process slash commands"""

	# Parse command
	var parts := text.substr(1).split(" ", false)
	if parts.is_empty():
		return

	var command := parts[0].to_lower()

	match command:
		"help":
			add_message("System", "Available commands:", "System")
			add_message("System", "/help - Show this message", "System")
			add_message("System", "/clear - Clear chat", "System")

		"clear":
			clear_chat()

		_:
			add_message("System", "Unknown command: " + command, "System")


func clear_chat() -> void:
	"""Clear all chat messages"""

	if message_log:
		for child in message_log.get_children():
			child.queue_free()
		add_message("System", "Chat cleared", "System")


func _input(event: InputEvent) -> void:
	"""Handle input for chat focus"""

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ENTER:
				# Focus chat input
				if chat_input and not chat_input.has_focus():
					chat_input.grab_focus()
					get_viewport().set_input_as_handled()

			KEY_ESCAPE:
				# Unfocus chat input
				if chat_input and chat_input.has_focus():
					chat_input.release_focus()
					get_viewport().set_input_as_handled()


# Global helper function for any script to send messages
static func send_chat_message(sender: String, text: String, sender_type: String, tree: SceneTree) -> void:
	"""Static helper to send chat messages from any script"""

	var chat_box := tree.get_first_node_in_group("chat_box") as ChatBox
	if chat_box:
		chat_box.add_message(sender, text, sender_type)
