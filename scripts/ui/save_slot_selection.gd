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
@onready var slot1 = $Panel/VBoxContainer/SlotContainer/Slot1Container/Slot1Button
@onready var slot2 = $Panel/VBoxContainer/SlotContainer/Slot2Container/Slot2Button
@onready var slot3 = $Panel/VBoxContainer/SlotContainer/Slot3Container/Slot3Button
@onready var edit1 = $Panel/VBoxContainer/SlotContainer/Slot1Container/EditButton1
@onready var edit2 = $Panel/VBoxContainer/SlotContainer/Slot2Container/EditButton2
@onready var edit3 = $Panel/VBoxContainer/SlotContainer/Slot3Container/EditButton3
@onready var delete1 = $Panel/VBoxContainer/SlotContainer/Slot1Container/DeleteButton1
@onready var delete2 = $Panel/VBoxContainer/SlotContainer/Slot2Container/DeleteButton2
@onready var delete3 = $Panel/VBoxContainer/SlotContainer/Slot3Container/DeleteButton3
@onready var back_btn = $Panel/VBoxContainer/BackButton

func _ready():
	# Update title
	if is_new_game:
		title.text = "SELECT SAVE SLOT - NEW GAME"
	else:
		title.text = "SELECT SAVE SLOT - CONTINUE"

	# Load and display save slot info
	update_slot_displays()

	# Connect slot select buttons
	slot1.pressed.connect(func(): select_slot(1))
	slot2.pressed.connect(func(): select_slot(2))
	slot3.pressed.connect(func(): select_slot(3))

	# Connect edit buttons
	edit1.pressed.connect(func(): edit_slot(1))
	edit2.pressed.connect(func(): edit_slot(2))
	edit3.pressed.connect(func(): edit_slot(3))

	# Connect delete buttons
	delete1.pressed.connect(func(): delete_slot(1))
	delete2.pressed.connect(func(): delete_slot(2))
	delete3.pressed.connect(func(): delete_slot(3))

	back_btn.pressed.connect(_on_back_pressed)

	print("Save Slot Selection ready, is_new_game: ", is_new_game)

func update_slot_displays():
	# Update each slot button with save data
	for i in range(3):
		var slot_number = i + 1
		var button = get_slot_button(slot_number)
		var edit_btn = get_edit_button(slot_number)
		var delete_btn = get_delete_button(slot_number)

		if not button:
			continue

		# Try to load save data for this slot
		var save_data = SaveSystem.load_slot(slot_number) if SaveSystem else {}

		if save_data.is_empty():
			# Empty slot
			button.text = "SLOT %d\n[EMPTY]" % slot_number

			# Hide edit/delete buttons for empty slots
			if edit_btn:
				edit_btn.visible = false
			if delete_btn:
				delete_btn.visible = false
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

			# Show edit/delete buttons for slots with data
			if edit_btn:
				edit_btn.visible = true
			if delete_btn:
				delete_btn.visible = true

func get_slot_button(slot: int) -> Button:
	match slot:
		1: return slot1
		2: return slot2
		3: return slot3
	return null

func get_edit_button(slot: int) -> Button:
	match slot:
		1: return edit1
		2: return edit2
		3: return edit3
	return null

func get_delete_button(slot: int) -> Button:
	match slot:
		1: return delete1
		2: return delete2
		3: return delete3
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

func delete_slot(slot_number: int):
	print("🗑️ Delete slot ", slot_number, " requested")

	# Confirm deletion with user
	var confirmation = create_confirmation_dialog(
		"Delete Save Slot %d?" % slot_number,
		"This action cannot be undone!\nAll progress in this slot will be permanently deleted.",
		func(): _confirm_delete(slot_number)
	)
	add_child(confirmation)

func _confirm_delete(slot_number: int):
	if SaveSystem:
		if SaveSystem.delete_slot(slot_number):
			print("✅ Slot ", slot_number, " deleted successfully")
		else:
			print("❌ Failed to delete slot ", slot_number)

	# Refresh display
	update_slot_displays()

func edit_slot(slot_number: int):
	print("✏️ Edit slot ", slot_number, " requested")

	# Load the save data for this slot
	if SaveSystem:
		var save_data = SaveSystem.load_slot(slot_number)

		if save_data.is_empty():
			print("❌ Cannot edit empty slot")
			return

		# Open Edit World Settings dialog (FEATURE #4)
		# TODO: Implement edit world settings dialog
		print("📝 Opening Edit World Settings for slot ", slot_number)
		print("   World data: ", save_data.get("world_settings", {}))

		# For now, show a placeholder message
		var placeholder = create_info_dialog(
			"Edit World Settings",
			"This feature will allow you to edit:\n• Game Mode\n• Difficulty\n• Starting Biome\n• World Modifiers\n\n(Coming in FEATURE #4)"
		)
		add_child(placeholder)

func create_confirmation_dialog(title: String, message: String, on_confirm: Callable) -> CanvasLayer:
	var dialog = CanvasLayer.new()

	# Semi-transparent background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	dialog.add_child(bg)

	# Dialog panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -150
	panel.offset_right = 250
	panel.offset_bottom = 150
	dialog.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0, 0.25))
	vbox.add_child(title_label)

	# Message
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.custom_minimum_size = Vector2(400, 0)
	vbox.add_child(msg_label)

	# Buttons
	var button_box = HBoxContainer.new()
	button_box.alignment = BoxContainer.ALIGNMENT_CENTER
	button_box.add_theme_constant_override("separation", 20)
	vbox.add_child(button_box)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(180, 50)
	cancel_btn.add_theme_font_size_override("font_size", 20)
	cancel_btn.pressed.connect(func(): dialog.queue_free())
	button_box.add_child(cancel_btn)

	var confirm_btn = Button.new()
	confirm_btn.text = "DELETE"
	confirm_btn.custom_minimum_size = Vector2(180, 50)
	confirm_btn.add_theme_font_size_override("font_size", 20)
	confirm_btn.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	confirm_btn.pressed.connect(func():
		on_confirm.call()
		dialog.queue_free()
	)
	button_box.add_child(confirm_btn)

	return dialog

func create_info_dialog(title: String, message: String) -> CanvasLayer:
	var dialog = CanvasLayer.new()

	# Semi-transparent background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	dialog.add_child(bg)

	# Dialog panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -250
	panel.offset_top = -150
	panel.offset_right = 250
	panel.offset_bottom = 150
	dialog.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	panel.add_child(vbox)

	# Title
	var title_label = Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0, 0.25))
	vbox.add_child(title_label)

	# Message
	var msg_label = Label.new()
	msg_label.text = message
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 18)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.custom_minimum_size = Vector2(400, 0)
	vbox.add_child(msg_label)

	# OK button
	var ok_btn = Button.new()
	ok_btn.text = "OK"
	ok_btn.custom_minimum_size = Vector2(200, 50)
	ok_btn.add_theme_font_size_override("font_size", 20)
	ok_btn.pressed.connect(func(): dialog.queue_free())
	vbox.add_child(ok_btn)

	return dialog
