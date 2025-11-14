extends CanvasLayer
class_name SpinWheelUI

## Spin Wheel UI - Phase 7 Gacha System
## Rotating wheel animation for weapon rolls

# Wheel state
var is_spinning: bool = false
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

# UI references
@onready var panel = $Panel if has_node("Panel") else null
@onready var wheel_container = $Panel/WheelContainer if has_node("Panel/WheelContainer") else null
@onready var arrow = $Panel/Arrow if has_node("Panel/Arrow") else null
@onready var status_label = $Panel/StatusLabel if has_node("Panel/StatusLabel") else null
@onready var close_button = $Panel/CloseButton if has_node("Panel/CloseButton") else null

func _ready():
	# Hide initially
	visible = false
	add_to_group("spin_wheel_ui")

	# Calculate slot angles (72° apart for 5 slots)
	for i in range(SLOT_COUNT):
		slot_angles.append((TAU / SLOT_COUNT) * i)

	# Connect close button
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

	print("🎰 Spin Wheel UI ready")

func open(tier: int, player: CharacterBody2D):
	"""Open spin wheel for ATM tier"""
	if is_spinning:
		print("⚠️ Already spinning!")
		return

	current_tier = tier
	current_player = player

	# Generate weapons for wheel
	weapons = WeaponPoolManager.generate_spin_wheel_weapons(tier, SLOT_COUNT)

	# Pre-determine result
	target_weapon_index = randi() % SLOT_COUNT

	print("🎰 Opening spin wheel - Tier: ", tier, " Target: ", weapons[target_weapon_index])

	# Setup UI
	setup_wheel()

	# Show UI
	visible = true
	get_tree().paused = true  # Pause game during spin

	# Start spin
	start_spin()

func setup_wheel():
	"""Create weapon slots in wheel"""
	if not wheel_container:
		return

	# Clear existing children
	for child in wheel_container.get_children():
		child.queue_free()

	# Create weapon slots
	for i in range(SLOT_COUNT):
		var weapon_id = weapons[i]
		var slot = create_weapon_slot(weapon_id, i)
		wheel_container.add_child(slot)

	# Update status
	if status_label:
		status_label.text = "Spinning..."

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

func start_spin():
	"""Start spinning animation"""
	is_spinning = true
	spin_timer = 0.0
	spin_rotation = 0.0
	spin_speed = 20.0  # Start fast (20 rad/s)

	print("🎰 Spin started! Target slot: ", target_weapon_index)

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
	target_rotation += TAU * 3  # 3 full rotations

	return target_rotation

func end_spin():
	"""End spinning and show result"""
	is_spinning = false

	var result_weapon = weapons[target_weapon_index]
	var rarity = WeaponPoolManager.get_weapon_rarity(result_weapon)
	var weapon_name = WeaponPoolManager.get_weapon_display_name(result_weapon)

	print("🎰 Spin ended! Result: ", weapon_name, " (", WeaponPoolManager.get_rarity_name(rarity), ")")

	# Update status
	if status_label:
		status_label.text = "You got: " + weapon_name + "!"
		status_label.modulate = WeaponPoolManager.get_rarity_color(rarity)

	# Visual feedback
	create_result_effects(rarity)

	# Add weapon to inventory
	add_weapon_to_player(result_weapon)

	# Auto-close after delay
	await get_tree().create_timer(2.0).timeout
	close()

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
	var shake_intensity = 3.0 + (rarity * 2.0)
	CameraShake.shake(shake_intensity, 0.5)

	print("✨ Created effects for rarity ", rarity)

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

func close():
	"""Close spin wheel UI"""
	visible = false
	get_tree().paused = false

	# Reset state
	is_spinning = false
	spin_timer = 0.0
	weapons.clear()
	current_player = null

	print("🎰 Spin wheel closed")

func _on_close_pressed():
	"""Close button pressed"""
	if not is_spinning:
		close()
