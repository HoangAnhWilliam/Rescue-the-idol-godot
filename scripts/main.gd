extends Node2D
## Main game scene script
##
## Handles pause menu and game state management

func _ready():
	print("Main game scene loaded")

func _input(event):
	# Handle pause menu
	if event.is_action_pressed("pause"):
		if not get_tree().paused:
			show_pause_menu()
		get_viewport().set_input_as_handled()

func show_pause_menu():
	var pause_menu = load("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(pause_menu)
