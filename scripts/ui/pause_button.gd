extends Button
## Pause Button
##
## BUG FIX #3: Simple pause button that opens pause menu
## Positioned at top-center of screen

func _ready():
	# BUG FIX #3: Ensure button is clickable
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 100  # Make sure it's above other UI elements

	# Make sure button works even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Connect button press
	pressed.connect(_on_pressed)

	print("✅ Pause button ready at position:", global_position)

func _on_pressed():
	print("⏸️ PAUSE button clicked!")

	# Load and show pause menu
	var pause_menu_scene = load("res://scenes/ui/pause_menu.tscn")

	if pause_menu_scene:
		var pause_menu = pause_menu_scene.instantiate()

		# Make sure pause menu can process when paused
		pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS

		# Add to root
		get_tree().root.add_child(pause_menu)

		# Hide this button while paused
		visible = false

		# Show button again when pause menu is closed
		pause_menu.tree_exited.connect(func():
			visible = true
			print("Pause menu closed, button visible again")
		)
	else:
		print("❌ ERROR: Could not load pause menu scene!")
