extends Node2D
## Main game scene script
##
## Handles pause menu and game state management

@onready var pause_button = $UI/PauseButton

func _ready():
	print("Main game scene loaded")

	# Connect pause button if it exists
	if pause_button:
		pause_button.pressed.connect(show_pause_menu)
		print("Pause button connected")

func _input(event):
	# Handle pause menu (ESC key)
	if event.is_action_pressed("pause"):
		if not get_tree().paused:
			show_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause_menu():
	# Hide pause button during pause
	if pause_button:
		pause_button.visible = false

	var pause_menu = load("res://scenes/ui/pause_menu.tscn").instantiate()

	# When pause menu closes, show pause button again
	pause_menu.tree_exited.connect(func():
		if pause_button:
			pause_button.visible = true
	)

	add_child(pause_menu)
