extends CanvasLayer
class_name SpinWheelUI

## Spin Wheel UI - Phase 7 Gacha System
## Rotating wheel animation for weapon rolls with gold validation

# Wheel state
var is_spinning: bool = false
var spin_complete: bool = false
var current_tier: int = 0
var current_cost: int = 0  # Gold cost for this spin
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

# ATM tier costs
const TIER_COSTS = [0, 5000, 20000, 50000]  # Bronze=0, Silver=5k, Gold=20k, Divine=50k
const TIER_NAMES = ["BRONZE ATM", "SILVER ATM", "GOLD ATM", "DIVINE ATM"]

# UI references
@onready var panel = $Panel
@onready var wheel_container = $Panel/WheelContainer
@onready var arrow = $Panel/Arrow
@onready var tier_label = $Panel/TierLabel
@onready var status_label = $Panel/StatusLabel
@onready var close_button = $Panel/CloseButton
@onready var spin_button = $Panel/SpinButton

func _ready():
	# CRITICAL: Set process mode to work when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

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

	print("🎰 Process mode set to ALWAYS (works when paused)")
	print("========================")

func open(tier: int, player: CharacterBody2D):
	"""Open spin wheel for ATM tier"""
	if is_spinning:
		print("⚠️ Already spinning!")
		return

	current_tier = tier
	current_player = player
	current_cost = TIER_COSTS[tier] if tier < TIER_COSTS.size() else 0

	# Reset state
	is_spinning = false
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0

	# Generate weapons for wheel
	weapons = WeaponPoolManager.generate_spin_wheel_weapons(tier, SLOT_COUNT)

	# Pre-determine result
	target_weapon_index = randi() % SLOT_COUNT

	print("🎰 Opening spin wheel - Tier: ", tier, " (", TIER_NAMES[tier], ")")
	print("   Cost: ", current_cost, " gold")
	print("   Target: ", weapons[target_weapon_index])
	print("   Weapon pool: ", weapons)

	# Setup UI
	setup_wheel()

	# Update tier label
	if tier_label:
		tier_label.text = TIER_NAMES[tier]

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

	# Update status with cost
	if status_label:
		if current_cost > 0:
			var player_gold = get_player_gold()
			if player_gold >= current_cost:
				status_label.text = "Cost: " + str(current_cost) + " Gold - Press SPIN!"
				status_label.modulate = Color(1, 1, 1)
			else:
				status_label.text = "Not enough gold! Need: " + str(current_cost) + " (Have: " + str(player_gold) + ")"
				status_label.modulate = Color(1, 0.3, 0.3)
		else:
			status_label.text = "FREE SPIN! Press SPIN to start!"
			status_label.modulate = Color(0.2, 1.0, 0.2)

	# Show UI
	visible = true
	get_tree().paused = true  # Pause game during gacha

	print("✅ Spin wheel opened successfully!")

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
	"""Start spinning animation with gold validation"""
	if is_spinning:
		print("⚠️ Already spinning!")
		return

	# GOLD VALIDATION
	var player_gold = get_player_gold()

	print("💰 Gold check - Cost: ", current_cost, ", Player has: ", player_gold)

	if current_cost > 0:
		if player_gold < current_cost:
			# Not enough gold!
			print("❌ Not enough gold! Need ", current_cost, " but player has ", player_gold)

			if status_label:
				status_label.text = "NOT ENOUGH GOLD! Need: " + str(current_cost) + " (Have: " + str(player_gold) + ")"
				status_label.modulate = Color(1, 0.2, 0.2)

			# Flash the status label
			flash_status_label()
			return

		# Deduct gold
		if not spend_player_gold(current_cost):
			print("❌ Failed to spend gold!")
			return

		print("✅ Spent ", current_cost, " gold")
	else:
		print("✅ Free spin, no gold needed")

	# Start spin animation
	is_spinning = true
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0
	spin_speed = 20.0  # Start fast (20 rad/s)

	# Update buttons
	if spin_button:
		spin_button.text = "SPINNING..."
		spin_button.disabled = true
		spin_button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

	if close_button:
		close_button.visible = false  # Hide close during spin

	# Update status
	if status_label:
		status_label.text = "Spinning..."
		status_label.modulate = Color(1, 1, 0.5)

	print("🎰 Spin started! Target slot: ", target_weapon_index, " (", weapons[target_weapon_index], ")")

func get_player_gold() -> int:
	"""Get player's current gold amount"""
	if not current_player:
		print("⚠️ No player reference!")
		return 0

	if current_player.has_method("get_total_gold"):
		return current_player.get_total_gold()

	print("⚠️ Player doesn't have get_total_gold() method!")
	return 0

func spend_player_gold(amount: int) -> bool:
	"""Spend player's gold"""
	if not current_player:
		print("⚠️ No player reference!")
		return false

	if current_player.has_method("spend_gold"):
		return current_player.spend_gold(amount)

	print("⚠️ Player doesn't have spend_gold() method!")
	return false

func flash_status_label():
	"""Flash status label red for error feedback"""
	if not status_label:
		return

	var original_modulate = status_label.modulate

	# Flash sequence
	for i in range(3):
		status_label.modulate = Color(1, 0, 0)
		await get_tree().create_timer(0.1).timeout
		status_label.modulate = original_modulate
		await get_tree().create_timer(0.1).timeout

func _process(delta):
	if not is_spinning or not visible:
		return

	spin_timer += delta

	# Decelerate over time (ease-out cubic)
	var progress = spin_timer / spin_duration
	var decel_curve = 1.0 - pow(1.0 - progress, 3.0)  # Ease-out cubic

	# Calculate target rotation (5 full rotations = 1800° + alignment)
	var target_angle = calculate_target_rotation()

	# Interpolate to target
	spin_rotation = lerp(0.0, target_angle, decel_curve)

	# Apply rotation to wheel
	if wheel_container:
		wheel_container.rotation = spin_rotation

	# Check if spin complete
	if spin_timer >= spin_duration:
		end_spin()

func calculate_target_rotation() -> float:
	"""Calculate final rotation to land on target (5 full rotations + alignment)"""
	# Target slot should be at top (arrow position)
	var target_slot_angle = slot_angles[target_weapon_index]

	# Arrow points down (180°), so rotate to align
	var target_rotation = -target_slot_angle + PI

	# Add 5 full rotations (1800° = 5 * 360° = 5 * TAU)
	target_rotation += TAU * 5

	return target_rotation

func end_spin():
	"""End spinning and show result"""
	is_spinning = false
	spin_complete = true

	var result_weapon = weapons[target_weapon_index]
	var rarity = WeaponPoolManager.get_weapon_rarity(result_weapon)
	var weapon_name = WeaponPoolManager.get_weapon_display_name(result_weapon)

	print("🎰 Spin complete! Selected weapon: ", weapon_name)
	print("   Rarity: ", RARITY_NAMES[rarity])

	# Update status with rarity
	if status_label:
		status_label.text = "You got: " + weapon_name + " (" + RARITY_NAMES[rarity] + ")!"
		status_label.modulate = WeaponPoolManager.get_rarity_color(rarity)

	# Visual feedback
	create_result_effects(rarity)

	# Add weapon to inventory
	add_weapon_to_player(result_weapon)

	# Show buttons
	if spin_button:
		spin_button.text = "CLOSE"
		spin_button.visible = true
		spin_button.disabled = false
		# Gray color for close
		spin_button.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	if close_button:
		close_button.visible = true  # Show close button again

	print("✅ Spin finished successfully!")

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
	close()

func close():
	"""Close spin wheel UI"""
	print("🎰 Closing spin wheel...")
	print("   Before - visible: ", visible, ", paused: ", get_tree().paused)

	visible = false
	get_tree().paused = false

	# Reset state
	is_spinning = false
	spin_complete = false
	spin_timer = 0.0
	spin_rotation = 0.0
	current_cost = 0
	weapons.clear()
	current_player = null

	# Reset wheel rotation
	if wheel_container:
		wheel_container.rotation = 0.0

	print("   After - visible: ", visible, ", paused: ", get_tree().paused)
	print("✅ Spin wheel closed")
