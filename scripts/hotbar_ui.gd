extends Control
class_name HotbarUI

## Minecraft-Style Hotbar UI
## Visual display of 9 inventory slots at bottom center
## Supports both mouse click and touch input for mobile
## Selected slot has bright border like Minecraft

const SLOT_SIZE: Vector2 = Vector2(64, 64)
const SLOT_SPACING: int = 4
const BORDER_WIDTH: float = 3.0

# Colors
const SLOT_BG_COLOR: Color = Color(0.15, 0.15, 0.15, 0.9)
const SLOT_BORDER_NORMAL: Color = Color(0.4, 0.4, 0.4, 0.8)
const SLOT_BORDER_SELECTED: Color = Color(1, 1, 1, 1.0)  # Bright white when selected

# References
var inventory: InventorySystem = null
var player: CharacterBody2D = null

# UI containers
var hotbar_container: HBoxContainer = null
var slots_container: HBoxContainer = null
var slot_panels: Array[PanelContainer] = []
var slot_borders: Array[ColorRect] = []  # Border for each slot

# Selection state
var selected_slot: int = 0  # Currently selected slot (Minecraft style)

# Mobile touch support
var is_mobile: bool = false
var touch_cooldowns: Array[float] = []  # Prevent double-tap
const TOUCH_COOLDOWN: float = 0.3  # seconds


func _ready():
	print("🎮 HotbarUI initializing...")

	# Detect mobile platform
	is_mobile = _detect_mobile()

	# Find systems
	inventory = get_tree().get_first_node_in_group("inventory")
	player = get_tree().get_first_node_in_group("player")

	if not inventory:
		push_warning("⚠️ HotbarUI: No inventory found!")
		return

	if not player:
		push_warning("⚠️ HotbarUI: No player found!")

	# Connect to inventory signals
	inventory.slot_changed.connect(_on_slot_changed)

	# Initialize touch cooldowns
	for i in range(9):
		touch_cooldowns.append(0.0)

	# Create UI
	create_hotbar_ui()

	# Initial update
	for i in range(9):
		update_slot_ui(i)

	# Set initial selection
	_update_selection_visual()

	print("✅ HotbarUI ready!")
	if is_mobile:
		print("📱 Mobile touch input enabled")


func _detect_mobile() -> bool:
	var os_name = OS.get_name()
	return os_name == "Android" or os_name == "iOS" or DisplayServer.is_touchscreen_available()


func _process(delta: float) -> void:
	# Update touch cooldowns
	for i in range(touch_cooldowns.size()):
		if touch_cooldowns[i] > 0:
			touch_cooldowns[i] -= delta


func create_hotbar_ui():
	# Main container
	hotbar_container = HBoxContainer.new()
	hotbar_container.name = "HotbarContainer"
	hotbar_container.anchor_left = 0.5
	hotbar_container.anchor_right = 0.5
	hotbar_container.anchor_top = 1.0
	hotbar_container.anchor_bottom = 1.0
	hotbar_container.offset_left = -300.0
	hotbar_container.offset_right = 300.0
	hotbar_container.offset_top = -90.0
	hotbar_container.offset_bottom = -15.0
	hotbar_container.grow_horizontal = 2
	hotbar_container.grow_vertical = 0
	add_child(hotbar_container)

	# Slots container
	slots_container = HBoxContainer.new()
	slots_container.name = "SlotsContainer"
	slots_container.set("theme_override_constants/separation", SLOT_SPACING)
	hotbar_container.add_child(slots_container)

	# Create 9 slots
	for i in range(9):
		var slot_panel = create_slot_panel(i)
		slots_container.add_child(slot_panel)
		slot_panels.append(slot_panel)


func create_slot_panel(slot_index: int) -> PanelContainer:
	# Panel container
	var panel = PanelContainer.new()
	panel.name = "Slot%d" % slot_index
	panel.custom_minimum_size = SLOT_SIZE

	# Border (for selection highlight)
	var border = ColorRect.new()
	border.name = "Border"
	border.color = SLOT_BORDER_NORMAL
	border.custom_minimum_size = SLOT_SIZE
	panel.add_child(border)
	slot_borders.append(border)

	# Background (inside border)
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = SLOT_BG_COLOR
	bg.position = Vector2(BORDER_WIDTH, BORDER_WIDTH)
	bg.size = SLOT_SIZE - Vector2(BORDER_WIDTH * 2, BORDER_WIDTH * 2)
	bg.custom_minimum_size = bg.size
	border.add_child(bg)

	# Icon (item visual)
	var icon = ColorRect.new()
	icon.name = "Icon"
	icon.size = Vector2(44, 44)
	icon.position = Vector2(5, 5)  # Center in slot
	icon.color = Color(1, 1, 1)
	icon.visible = false
	bg.add_child(icon)

	# Quantity label
	var qty_label = Label.new()
	qty_label.name = "QuantityLabel"
	qty_label.position = Vector2(35, 35)
	qty_label.size = Vector2(20, 20)
	qty_label.add_theme_color_override("font_color", Color.WHITE)
	qty_label.add_theme_color_override("font_outline_color", Color.BLACK)
	qty_label.add_theme_constant_override("outline_size", 2)
	qty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	qty_label.text = ""
	qty_label.visible = false
	bg.add_child(qty_label)

	# Number label (hotkey 1-9)
	var num_label = Label.new()
	num_label.name = "NumberLabel"
	num_label.position = Vector2(2, 2)
	num_label.size = Vector2(20, 20)
	num_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	num_label.add_theme_color_override("font_outline_color", Color.BLACK)
	num_label.add_theme_constant_override("outline_size", 2)
	num_label.add_theme_font_size_override("font_size", 14)
	num_label.text = str(slot_index + 1)
	bg.add_child(num_label)

	# Click/touch detection
	panel.gui_input.connect(_on_slot_gui_input.bind(slot_index))

	return panel


func _on_slot_changed(slot_index: int):
	update_slot_ui(slot_index)

	# Update player weapons if weapon slots changed
	var slot = inventory.get_slot(slot_index)
	if slot and slot.item_type == inventory.ItemType.WEAPON:
		update_player_weapons()


func update_slot_ui(slot_index: int):
	if slot_index < 0 or slot_index >= slot_panels.size():
		return

	var slot = inventory.get_slot(slot_index)
	if not slot:
		return

	var panel = slot_panels[slot_index]
	var bg = panel.get_node("Border/Background")
	var icon = bg.get_node("Icon")
	var qty_label = bg.get_node("QuantityLabel")

	if slot.is_empty():
		# Empty slot
		icon.visible = false
		qty_label.visible = false
	else:
		# Has item
		icon.visible = true

		# Set icon color based on item type
		match slot.item_type:
			inventory.ItemType.WEAPON:
				icon.color = Color(0.8, 0.8, 0.8)  # Gray
			inventory.ItemType.HEALTH_POTION:
				icon.color = Color(1, 0, 0)  # Red
			inventory.ItemType.MANA_POTION:
				icon.color = Color(0, 0.5, 1)  # Blue
			inventory.ItemType.GOLD:
				icon.color = Color(1, 0.84, 0)  # Gold

		# Update quantity
		if slot.quantity > 1:
			qty_label.text = str(slot.quantity)
			qty_label.visible = true
		else:
			qty_label.visible = false


func _update_selection_visual() -> void:
	"""Update border colors to show selected slot (Minecraft style)"""
	for i in range(slot_borders.size()):
		if i == selected_slot:
			slot_borders[i].color = SLOT_BORDER_SELECTED
		else:
			slot_borders[i].color = SLOT_BORDER_NORMAL


func select_slot(slot_index: int) -> void:
	"""Select a slot (Minecraft style selection)"""
	if slot_index < 0 or slot_index >= 9:
		return

	selected_slot = slot_index
	_update_selection_visual()

	print("🎮 Selected slot %d" % (slot_index + 1))


func _on_slot_gui_input(event: InputEvent, slot_index: int):
	# Handle touch events (mobile)
	if event is InputEventScreenTouch and event.pressed:
		_handle_touch_slot(slot_index)
		return

	# Handle mouse events (PC)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Left click: Select and use slot
			select_slot(slot_index)
			use_slot(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click: Drop item
			var amount = 1
			if Input.is_key_pressed(KEY_SHIFT):
				# Shift + Right click: Drop all
				var slot = inventory.get_slot(slot_index)
				if slot:
					amount = slot.quantity
			drop_slot(slot_index, amount)


func _handle_touch_slot(slot_index: int) -> void:
	"""Handle touch input on hotbar slot"""
	# Check touch cooldown to prevent double-tap
	if slot_index < touch_cooldowns.size() and touch_cooldowns[slot_index] > 0:
		return

	# Set cooldown
	if slot_index < touch_cooldowns.size():
		touch_cooldowns[slot_index] = TOUCH_COOLDOWN

	# Select the slot (shows bright border)
	select_slot(slot_index)

	# Use the slot item
	use_slot(slot_index)

	# Visual feedback (flash)
	_show_touch_feedback(slot_index)


func _show_touch_feedback(slot_index: int) -> void:
	"""Show visual feedback when slot is touched"""
	if slot_index < 0 or slot_index >= slot_panels.size():
		return

	var panel = slot_panels[slot_index]
	var bg = panel.get_node_or_null("Border/Background")
	if not bg:
		return

	# Flash the background brighter
	var original_color = bg.color
	bg.color = Color(0.4, 0.4, 0.4, 1.0)

	# Reset after short delay
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(bg):
		bg.color = original_color


func _input(event):
	if event is InputEventKey and event.pressed:
		# Hotkeys 1-9 to select and use slot
		for i in range(9):
			if event.keycode == KEY_1 + i:
				select_slot(i)
				use_slot(i)
				break


func use_slot(slot_index: int):
	if not inventory:
		return

	print("🎮 Using slot %d" % (slot_index + 1))

	var success = inventory.use_item(slot_index)
	if success:
		# Item was used (potion consumed)
		pass
	else:
		# Item cannot be used (weapon, gold, empty)
		pass


func drop_slot(slot_index: int, amount: int = 1):
	if not inventory or not player:
		return

	var slot = inventory.get_slot(slot_index)
	if not slot or slot.is_empty():
		return

	print("🎮 Dropping %d items from slot %d" % [amount, slot_index + 1])

	# Drop at player position
	inventory.drop_item(slot_index, player.global_position, amount)


func update_player_weapons():
	if not player or not inventory:
		return

	# Get all weapon slots
	var weapon_data = inventory.get_all_weapons()

	# Update player's equipped weapons
	if player.has_method("update_equipped_weapons"):
		player.update_equipped_weapons(weapon_data)
		print("⚔️ Updated equipped weapons: %d weapons" % weapon_data.size())


func get_selected_slot() -> int:
	"""Get currently selected slot index"""
	return selected_slot
