extends Node2D
class_name RitualCircle

## Ritual circle that appears after collecting all 5 fragments
## Summons Despair Miku boss when activated

@onready var circle_sprite: Polygon2D = $CircleSprite
@onready var skull_markers: Node2D = $SkullMarkers
@onready var particles: CPUParticles2D = $Particles
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_prompt: Label = $InteractionPrompt

# State
var player_in_range: bool = false
var ritual_active: bool = false

# References
var despair_miku_scene: PackedScene = preload("res://scenes/bosses/despair_miku.tscn")

# Signals
signal ritual_started
signal boss_spawned

func _ready() -> void:
	add_to_group("ritual_circle")

	# Setup visuals
	setup_visuals()

	# Connect area signals
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
		interaction_area.body_exited.connect(_on_player_exited)

	# Hide prompt
	if interaction_prompt:
		interaction_prompt.hide()

	print("Ritual Circle spawned at %s" % global_position)


func setup_visuals() -> void:
	"""Setup ritual circle visual elements"""

	# Create circle sprite
	if circle_sprite:
		var points: PackedVector2Array = []
		var radius := 100.0
		var segments := 64

		for i in range(segments):
			var angle := (TAU / segments) * i
			var point := Vector2(cos(angle), sin(angle)) * radius
			points.append(point)

		circle_sprite.polygon = points
		circle_sprite.color = Color(0.5, 0.2, 0.6, 0.7)  # Purple semi-transparent

	# Create skull markers (8 around perimeter)
	if skull_markers:
		create_skull_markers()

	# Setup particles
	if particles:
		particles.emitting = true
		particles.amount = 30
		particles.lifetime = 2.0
		particles.direction = Vector2(0, -1)
		particles.gravity = Vector2(0, -50)
		particles.initial_velocity_min = 30.0
		particles.initial_velocity_max = 60.0
		particles.color = Color(0, 0.85, 1, 0.8)  # Cyan
		particles.scale_amount_min = 4.0
		particles.scale_amount_max = 8.0

	# Setup interaction area
	if interaction_area and not interaction_area.has_node("CollisionShape2D"):
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 80
		collision.shape = shape
		interaction_area.add_child(collision)


func create_skull_markers() -> void:
	"""Create 8 skull markers around the circle perimeter"""

	if not skull_markers:
		return

	for i in range(8):
		var skull := ColorRect.new()
		skull.size = Vector2(16, 16)
		skull.color = Color(0.95, 0.95, 0.95)  # White

		# Position at 45° intervals
		var angle := (TAU / 8) * i
		var radius := 100.0
		var pos := Vector2(cos(angle), sin(angle)) * radius
		skull.position = pos - skull.size / 2

		skull_markers.add_child(skull)


func _process(delta: float) -> void:
	"""Rotate circle slowly"""

	if circle_sprite:
		circle_sprite.rotation += 0.5 * delta  # 0.5 radians per second


func _on_player_entered(body: Node2D) -> void:
	"""Player entered ritual area"""

	if body.is_in_group("player"):
		player_in_range = true
		show_prompt()


func _on_player_exited(body: Node2D) -> void:
	"""Player exited ritual area"""

	if body.is_in_group("player"):
		player_in_range = false
		hide_prompt()


func show_prompt() -> void:
	"""Show interaction prompt"""

	if interaction_prompt and not ritual_active:
		interaction_prompt.text = "Press E to perform ritual"
		interaction_prompt.show()


func hide_prompt() -> void:
	"""Hide interaction prompt"""

	if interaction_prompt:
		interaction_prompt.hide()


func _input(event: InputEvent) -> void:
	"""Handle interaction input"""

	if not player_in_range or ritual_active:
		return

	if event.is_action_pressed("interact"):  # E key
		start_ritual_sequence()


func start_ritual_sequence() -> void:
	"""Start the ritual summoning sequence"""

	ritual_active = true
	hide_prompt()

	# Emit signal
	ritual_started.emit()

	# Get player reference
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D

	# 1. Freeze player
	if player and player.has_method("disable_input"):
		player.disable_input()

	# 2. Darken screen
	var vignette := create_vignette_overlay()
	var tween := create_tween()
	tween.tween_property(vignette, "modulate:a", 0.6, 1.0)
	await tween.finished

	# 3. Display ritual chant
	await display_ritual_chant()

	# 4. Screen flash white
	flash_screen(Color.WHITE, 0.5)
	await get_tree().create_timer(0.5).timeout

	# 5. Spawn Despair Miku boss
	spawn_despair_miku_boss()

	# 6. Remove vignette
	if vignette:
		tween = create_tween()
		tween.tween_property(vignette, "modulate:a", 0.0, 0.5)
		await tween.finished
		vignette.queue_free()

	# 7. Unfreeze player
	if player and player.has_method("enable_input"):
		player.enable_input()

	# 8. Remove ritual circle
	queue_free()


func create_vignette_overlay() -> ColorRect:
	"""Create dark vignette overlay"""

	var vignette := ColorRect.new()
	vignette.color = Color(0, 0, 0, 1.0)
	vignette.modulate.a = 0.0
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.z_index = 500

	# Make fullscreen
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)

	get_tree().root.add_child(vignette)

	return vignette


func display_ritual_chant() -> void:
	"""Display ritual chant text letter-by-letter"""

	var chant_lines := [
		"From the void, I summon you...",
		"From despair, I call out to you...",
		"Miku... Awaken!"
	]

	# Create centered label
	var chant_label := Label.new()
	chant_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chant_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	chant_label.add_theme_font_size_override("font_size", 32)
	chant_label.add_theme_color_override("font_color", Color(0, 0.85, 1))
	chant_label.z_index = 501

	# Position at screen center
	chant_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	get_tree().root.add_child(chant_label)

	# Type out each line
	for line in chant_lines:
		chant_label.text = ""

		# Type letter by letter
		for i in range(line.length()):
			chant_label.text += line[i]
			await get_tree().create_timer(0.05).timeout  # 50ms per letter

		# Pause after each line
		await get_tree().create_timer(1.5).timeout

	# Fade out chant
	var tween := create_tween()
	tween.tween_property(chant_label, "modulate:a", 0.0, 0.5)
	await tween.finished

	chant_label.queue_free()


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


func spawn_despair_miku_boss() -> void:
	"""Spawn Despair Miku boss at ritual position"""

	var boss := despair_miku_scene.instantiate()
	boss.global_position = global_position
	get_parent().add_child(boss)

	# Chat notification
	ChatBox.send_chat_message("System", "⚠️ Despair Miku has been summoned!", "System", get_tree())

	# Camera shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(30.0, 2.0)

	# Emit signal
	boss_spawned.emit()

	print("Despair Miku Boss spawned at %s" % global_position)
