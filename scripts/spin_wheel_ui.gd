extends CanvasLayer
class_name SpinWheelUI

## Spin Wheel UI - Phase 7 Gacha System
## Rotating wheel animation for weapon rolls

# Wheel state
var is_spinning: bool = false
var spin_complete: bool = false  # NEW: Track if spin finished
var current_tier: int = 0
var target_weapon_index: int = 0
var weapons: Array = []
var current_player: CharacterBody2D = null

# Spin animation
var spin_rotation: float = 0.0
var spin_speed: float = 0.0
var spin_duration: float = 3.0
var spin_timer: float = 0.0

# Slot positions (5 weapons in circle)
const SLOT_COUNT = 5
const SLOT_RADIUS = 120.0
var slot_angles = []

# Rarity names for display
const RARITY_NAMES = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]

# UI references
@onready var panel = $Panel
@onready var wheel_container = $Panel/WheelContainer
@onready var arrow = $Panel/Arrow
@onready var tier_label = $Panel/TierLabel
@onready var status_label = $Panel/StatusLabel
@onready var close_button = $Panel/CloseButton
@onready var spin_button = $Panel/SpinButton

func _ready():
	# Hide initially
	visible = false
	add_to_group("spin_wheel_ui")

	# Calculate slot angles (72° apart for 5 slots)
	for i in range(SLOT_COUNT):
		slot_angles.append((TAU / SLOT_COUNT) * i)

	# Debug: Check if buttons exist
	print("🎰 === Spin Wheel UI Initialization ===")
	print("Panel exists: ", panel != null)
	print("Wheel container exists: ", wheel_container != null)
	print("Close button exists: ", close_button != null)
	print("Spin button exists: ", spin_button != null)

	# Connect buttons
	if close_button:
		close_button.pressed.connect(_on_close_button_pressed)
		print("✅ Close button connected")
	else:
		print("❌ ERROR: Close button not found!")

	if spin_button:
		spin_button.pressed.connect(_on_spin_button_pressed)
		print("✅ Spin button connected")
	else:
		print("❌ ERROR: Spin button not found!")

	print("🎰 Spin Wheel UI ready")

func open(tier: int, player: CharacterBody2D):
	"""Open spin wheel for ATM tier"""
	if is_spinning:
		print("⚠️ Already spinning!")
		return

	current_tier = tier
	current_player = player

	# Reset state
	is_spinning = false
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0

	# Generate weapons for wheel
	weapons = WeaponPoolManager.generate_spin_wheel_weapons(tier, SLOT_COUNT)

	# Pre-determine result
	target_weapon_index = randi() % SLOT_COUNT

	print("🎰 Opening spin wheel - Tier: ", tier, " Target: ", weapons[target_weapon_index])

	# Setup UI
	setup_wheel()

	# Update tier label
	if tier_label:
		var tier_names = ["BRONZE ATM", "SILVER ATM", "GOLD ATM", "DIVINE ATM"]
		tier_label.text = tier_names[tier]

	# Setup buttons
	if spin_button:
		spin_button.text = "SPIN!"
		spin_button.visible = true
		spin_button.disabled = false
		# Green color for spin
		spin_button.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2))

	if close_button:
		close_button.visible = true
		close_button.disabled = false

	# Update status
	if status_label:
		status_label.text = "Press SPIN to start!"
		status_label.modulate = Color(1, 1, 1)

	# Show UI
	visible = true
	get_tree().paused = true  # Pause game during gacha

	print("🎰 Spin Wheel opened! Waiting for player to press SPIN...")

func setup_wheel():
	"""Create weapon slots in wheel"""
	if not wheel_container:
		print("❌ Wheel container not found!")
		return

	# Clear existing children
	for child in wheel_container.get_children():
		child.queue_free()

	# Create weapon slots
	for i in range(SLOT_COUNT):
		var weapon_id = weapons[i]
		var slot = create_weapon_slot(weapon_id, i)
		wheel_container.add_child(slot)

	# Reset rotation
	wheel_container.rotation = 0.0

	print("✅ Wheel setup complete with ", SLOT_COUNT, " weapons")

func create_weapon_slot(weapon_id: String, index: int) -> Control:
	"""Create visual slot for weapon"""
	var slot = PanelContainer.new()
	slot.name = "Slot" + str(index)
	slot.custom_minimum_size = Vector2(80, 100)

	# Background
	var bg = ColorRect.new()
	bg.custom_minimum_size = Vector2(80, 100)
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	slot.add_child(bg)

	# Weapon icon (colored rectangle)
	var icon = ColorRect.new()
	icon.size = Vector2(64, 64)
	icon.position = Vector2(8, 8)
	var rarity = WeaponPoolManager.get_weapon_rarity(weapon_id)
	icon.color = WeaponPoolManager.get_rarity_color(rarity)
	bg.add_child(icon)

	# Weapon name
	var name_label = Label.new()
	name_label.text = WeaponPoolManager.get_weapon_display_name(weapon_id)
	name_label.position = Vector2(4, 74)
	name_label.size = Vector2(72, 20)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	bg.add_child(name_label)

	# Position in circle
	var angle = slot_angles[index]
	var pos = Vector2(
		cos(angle) * SLOT_RADIUS,
		sin(angle) * SLOT_RADIUS
	)
	slot.position = pos - slot.custom_minimum_size / 2

	return slot

func _on_spin_button_pressed():
	"""Spin button pressed"""
	print("🎰 === SPIN BUTTON PRESSED ===")
	print("Is spinning: ", is_spinning)
	print("Spin complete: ", spin_complete)

	if spin_complete:
		# After spin finished, button acts as Close
		print("Spin already complete, closing...")
		close()
	else:
		# Start spin
		print("Starting spin...")
		start_spin()

func start_spin():
	"""Start spinning animation"""
	if is_spinning:
		print("⚠️ Already spinning!")
		return

	is_spinning = true
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0
	spin_speed = 20.0  # Start fast (20 rad/s)

	# Hide spin button during spin
	if spin_button:
		spin_button.visible = false

	# Update status
	if status_label:
		status_label.text = "Spinning..."
		status_label.modulate = Color(1, 1, 0.5)

	print("🎰 Spin started! Target slot: ", target_weapon_index, " (", weapons[target_weapon_index], ")")

func _process(delta):
	if not is_spinning or not visible:
		return

	spin_timer += delta

	# Decelerate over time
	var progress = spin_timer / spin_duration
	var decel_curve = 1.0 - pow(progress, 2.0)  # Quadratic deceleration
	spin_speed = 20.0 * decel_curve

	# Calculate target rotation to land on target slot
	if progress > 0.7:
		# Near end, interpolate to exact target
		var target_angle = calculate_target_rotation()
		spin_rotation = lerp(spin_rotation, target_angle, delta * 5.0)
	else:
		# Normal spin
		spin_rotation += spin_speed * delta

	# Apply rotation to wheel
	if wheel_container:
		wheel_container.rotation = spin_rotation

	# Check if spin complete
	if spin_timer >= spin_duration:
		end_spin()

func calculate_target_rotation() -> float:
	"""Calculate final rotation to land on target"""
	# Target slot should be at top (arrow position)
	var target_slot_angle = slot_angles[target_weapon_index]

	# Arrow points down (180°), so rotate to align
	var target_rotation = -target_slot_angle + PI

	# Add multiple full rotations for visual effect
	target_rotation += TAU * 5  # 5 full rotations

	return target_rotation

func end_spin():
	"""End spinning and show result"""
	is_spinning = false
	spin_complete = true

	var result_weapon = weapons[target_weapon_index]
	var rarity = WeaponPoolManager.get_weapon_rarity(result_weapon)
	var weapon_name = WeaponPoolManager.get_weapon_display_name(result_weapon)

	print("🎰 Spin ended! Result: ", weapon_name, " (", RARITY_NAMES[rarity], ")")

	# Update status with rarity
	if status_label:
		status_label.text = "You got: " + weapon_name + " (" + RARITY_NAMES[rarity] + ")!"
		status_label.modulate = WeaponPoolManager.get_rarity_color(rarity)

	# Visual feedback
	create_result_effects(rarity)

	# Add weapon to inventory
	add_weapon_to_player(result_weapon)

	# Show spin button as "Close"
	if spin_button:
		spin_button.text = "Close"
		spin_button.visible = true
		# Gray color for close
		spin_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	# Optional: Auto-close after delay (commented out so player can read result)
	# await get_tree().create_timer(3.0).timeout
	# close()

func create_result_effects(rarity: int):
	"""Create visual effects for result"""
	# Particle effect based on rarity
	var effect_color = WeaponPoolManager.get_rarity_color(rarity)

	if wheel_container:
		# Spawn particles around result
		for i in range(10 + rarity * 5):
			var angle = randf() * TAU
			var distance = randf_range(50, 150)
			var pos = wheel_container.global_position + Vector2(cos(angle), sin(angle)) * distance

			ParticleManager.create_hit_effect(pos, effect_color)

	# Camera shake (intensity by rarity)
	var shake_intensity = 3.0 + (rarity * 3.0)
	var shake_duration = 0.3 + (rarity * 0.1)
	CameraShake.shake(shake_intensity, shake_duration)

	print("✨ Created effects for ", RARITY_NAMES[rarity], " rarity")

func add_weapon_to_player(weapon_id: String):
	"""Add weapon to player inventory"""
	if not current_player:
		print("❌ No player reference!")
		return

	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		print("❌ No inventory found!")
		return

	var weapon_data = {
		"weapon_name": WeaponPoolManager.get_weapon_display_name(weapon_id),
		"weapon_id": weapon_id,
		"rarity": WeaponPoolManager.get_weapon_rarity(weapon_id),
		"damage": 10.0,  # Base damage
		"attack_speed": 1.0
	}

	var success = inventory.add_item(
		inventory.ItemType.WEAPON,
		weapon_id,
		1,
		weapon_data
	)

	if success:
		print("✅ Added ", weapon_id, " to inventory")
	else:
		print("⚠️ Inventory full!")
		if status_label:
			status_label.text += "\n(Inventory Full!)"

func _on_close_button_pressed():
	"""Close button pressed - always works"""
	print("🎰 === CLOSE BUTTON PRESSED ===")
	print("Current visible state: ", visible)
	print("Game paused: ", get_tree().paused)
	close()

func close():
	"""Close spin wheel UI"""
	print("🎰 === CLOSING SPIN WHEEL ===")
	print("Before - visible: ", visible, ", paused: ", get_tree().paused)

	visible = false
	get_tree().paused = false

	# Reset state
	is_spinning = false
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0
	weapons.clear()
	current_player = null

	# Reset wheel rotation
	if wheel_container:
		wheel_container.rotation = 0.0

	print("After - visible: ", visible, ", paused: ", get_tree().paused)
	print("🎰 Spin wheel closed")
