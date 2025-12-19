extends CanvasLayer
## Save Slot Selection Menu
##
## Features:
## - 3 save slots
## - Shows level, time, and biome for each slot
## - Different behavior for new game vs continue

# State
var is_new_game: bool = true

# Node references
@onready var title = $Panel/VBoxContainer/Title
@onready var slot1 = $Panel/VBoxContainer/SlotContainer/Slot1Button
@onready var slot2 = $Panel/VBoxContainer/SlotContainer/Slot2Button
@onready var slot3 = $Panel/VBoxContainer/SlotContainer/Slot3Button
@onready var back_btn = $Panel/VBoxContainer/BackButton

func _ready():
	# Update title
	if is_new_game:
		title.text = "SELECT SAVE SLOT - NEW GAME"
	else:
		title.text = "SELECT SAVE SLOT - CONTINUE"

	# Load and display save slot info
	update_slot_displays()

	# Connect buttons
	slot1.pressed.connect(func(): select_slot(1))
	slot2.pressed.connect(func(): select_slot(2))
	slot3.pressed.connect(func(): select_slot(3))
	back_btn.pressed.connect(_on_back_pressed)

	print("Save Slot Selection ready, is_new_game: ", is_new_game)

func update_slot_displays():
	# Update each slot button with save data
	for i in range(3):
		var slot_number = i + 1
		var button = get_slot_button(slot_number)

		if not button:
			continue

		# Try to load save data for this slot
		var save_data = SaveSystem.load_slot(slot_number) if SaveSystem else {}

		if save_data.is_empty():
			# Empty slot
			button.text = "SLOT %d\n[EMPTY]" % slot_number
		else:
			# Has data - show info
			var level = save_data.get("level", 1)
			var playtime = save_data.get("playtime", 0.0)
			var biome = save_data.get("current_biome", "Starting Forest")

			button.text = "SLOT %d\nLevel: %d\nTime: %s\nBiome: %s" % [
				slot_number,
				level,
				format_time(playtime),
				biome
			]

func get_slot_button(slot: int) -> Button:
	match slot:
		1: return slot1
		2: return slot2
		3: return slot3
	return null

func format_time(seconds: float) -> String:
	var hours = int(seconds / 3600)
	var minutes = int((seconds - hours * 3600) / 60)
	return "%dh %dm" % [hours, minutes]

func select_slot(slot_number: int):
	if is_new_game:
		# Create new save in this slot
		if SaveSystem:
			SaveSystem.current_slot = slot_number
			SaveSystem.create_new_save()
			print("Created new save in slot ", slot_number)

		# Start new game
		start_game()
	else:
		# Load existing save
		if SaveSystem:
			var save_data = SaveSystem.load_slot(slot_number)

			if save_data.is_empty():
				print("ERROR: No save in slot ", slot_number)
				return

			SaveSystem.current_slot = slot_number
			SaveSystem.save_data = save_data
			print("Loaded save from slot ", slot_number)

		# Resume game
		start_game()

func start_game():
	# Show loading screen then change to main game scene
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_back_pressed():
	# Return to main menu
	queue_free()
