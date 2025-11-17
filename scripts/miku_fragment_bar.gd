extends PanelContainer
class_name MikuFragmentBar

## Visual progress indicator for Miku fragment collection (0/5)
## Shows animated slots that fill as fragments are collected

@onready var slots_container: HBoxContainer = $MarginContainer/HBoxContainer/SlotsContainer
@onready var count_label: Label = $MarginContainer/HBoxContainer/CountLabel
@onready var icon_label: Label = $MarginContainer/HBoxContainer/IconLabel

const SLOT_SIZE := Vector2(40, 40)
const SLOT_SPACING := 5

var fragment_count: int = 0
var fragment_slots: Array[ColorRect] = []
var is_revealed: bool = false

signal all_fragments_collected
signal fragment_added(count: int)

func _ready() -> void:
	add_to_group("miku_fragment_bar")

	# Create 5 fragment slots
	create_fragment_slots()

	# Setup icon
	if icon_label:
		icon_label.text = "💙"
		icon_label.add_theme_font_size_override("font_size", 32)

	# Setup count label
	if count_label:
		count_label.text = "Miku Fragments: 0/5"
		count_label.add_theme_font_size_override("font_size", 16)

	# Start hidden
	hide()
	modulate.a = 0.0

	print("✓ Fragment bar created (hidden)")


func create_fragment_slots() -> void:
	"""Create 5 empty fragment slots"""

	if not slots_container:
		return

	for i in range(5):
		var slot := ColorRect.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.size = SLOT_SIZE

		# Empty slot style
		slot.color = Color(0.5, 0.5, 0.5, 0.3)  # Gray transparent
		slot.modulate = Color(1, 1, 1)

		slots_container.add_child(slot)
		fragment_slots.append(slot)


func show_fragment_bar_first_time() -> void:
	"""Reveal animation when first Miku is rescued"""

	if is_revealed:
		return

	is_revealed = true

	# Get target position (10px above hotbar)
	var viewport_size := get_viewport_rect().size
	var target_y := viewport_size.y - 150  # Approximate position above hotbar

	# Start position: Off-screen below
	position.y = viewport_size.y + 100
	modulate.a = 0.0
	show()

	# Slide up and fade in
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	await tween.finished

	# Pulse effect (3 times)
	for i in range(3):
		var pulse_tween := create_tween()
		pulse_tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5), 0.3)
		pulse_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)
		await pulse_tween.finished

	ChatBox.send_chat_message("System", "Miku's Soul Shards will appear here!", "System", get_tree())


func add_miku_fragment(miku_vanish_position: Vector2) -> void:
	"""Animate fragment collection from Miku's last position"""

	fragment_count += 1

	if fragment_count > 5:
		return

	# Create temporary fragment sprite
	var fragment_sprite := ColorRect.new()
	fragment_sprite.size = Vector2(20, 20)
	fragment_sprite.color = Color(0, 0.85, 1, 1.0)  # Cyan
	fragment_sprite.z_index = 100
	get_tree().root.add_child(fragment_sprite)
	fragment_sprite.global_position = miku_vanish_position - fragment_sprite.size / 2

	# Get target slot position in global coordinates
	var target_slot := fragment_slots[fragment_count - 1]
	var target_global_pos := target_slot.get_global_rect().get_center()

	# Animate fragment flying in parabolic arc
	var start_pos := fragment_sprite.global_position
	var mid_pos := (start_pos + target_global_pos) / 2
	mid_pos.y -= 100  # Arc height

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)

	# Animate along Bezier curve
	tween.tween_method(
		func(t: float) -> void:
			var p := quadratic_bezier(start_pos, mid_pos, target_global_pos, t)
			fragment_sprite.global_position = p,
		0.0, 1.0, 0.8
	)

	await tween.finished

	# Fragment reached slot
	fragment_sprite.queue_free()

	# Fill the slot
	fill_fragment_slot(target_slot)

	# Emit signal
	fragment_added.emit(fragment_count)


func fill_fragment_slot(slot: ColorRect) -> void:
	"""Fill a slot with cyan color and animate"""

	# Change color to cyan
	slot.color = Color(0, 0.85, 1, 1.0)

	# Scale pop animation
	var tween := create_tween()
	tween.tween_property(slot, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.15)

	# Flash effect
	var flash_tween := create_tween()
	flash_tween.tween_property(slot, "modulate", Color(2, 2, 2), 0.2)
	flash_tween.tween_property(slot, "modulate", Color(1.5, 1.5, 1.5), 0.2)

	# Update count label
	if count_label:
		count_label.text = "Miku Fragments: %d/5" % fragment_count

	# Chat notification
	ChatBox.send_chat_message("System", "Miku's Soul Shard collected: %d/5" % fragment_count, "System", get_tree())

	# Check if all collected
	if fragment_count >= 5:
		on_all_fragments_collected()


func on_all_fragments_collected() -> void:
	"""Called when all 5 fragments are collected"""

	# Entire bar glows
	var glow_tween := create_tween()
	glow_tween.set_loops(5)
	glow_tween.tween_property(self, "modulate", Color(1.8, 1.8, 1.8), 0.3)
	glow_tween.tween_property(self, "modulate", Color(1, 1, 1), 0.3)

	# Screen flash
	flash_screen(Color.WHITE, 0.8)

	# Camera shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(20.0, 1.0)

	# Emit signal
	all_fragments_collected.emit()

	# Chat notification
	ChatBox.send_chat_message("System", "━━━━━━━━━━━━━━━━━━━━━", "System", get_tree())
	ChatBox.send_chat_message("System", "ALL FRAGMENTS COLLECTED!", "System", get_tree())
	ChatBox.send_chat_message("System", "━━━━━━━━━━━━━━━━━━━━━", "System", get_tree())


func flash_screen(color: Color, duration: float) -> void:
	"""Create screen flash effect"""

	var flash := ColorRect.new()
	flash.color = color
	flash.modulate.a = 0.0
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 999

	# Make fullscreen
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)

	get_tree().root.add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "modulate:a", 0.7, duration / 2.0)
	tween.tween_property(flash, "modulate:a", 0.0, duration / 2.0)

	await tween.finished
	flash.queue_free()


func quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	"""Calculate point on quadratic Bezier curve"""

	var q0 := p0.lerp(p1, t)
	var q1 := p1.lerp(p2, t)
	return q0.lerp(q1, t)


func reset_fragments() -> void:
	"""Reset fragment count (for testing or new game+)"""

	fragment_count = 0

	for slot in fragment_slots:
		slot.color = Color(0.5, 0.5, 0.5, 0.3)
		slot.modulate = Color(1, 1, 1)
		slot.scale = Vector2(1, 1)

	if count_label:
		count_label.text = "Miku Fragments: 0/5"
