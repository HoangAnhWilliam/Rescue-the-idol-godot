extends CharacterBody2D
class_name KikuCompanion

## Temporary Kiku companion that follows player for 5 minutes
## Has 4 corruption stages based on time remaining
## Provides buffs to player while active

enum KikuState { FOLLOWING, VANISHING, VANISHED }

# State
var current_state: KikuState = KikuState.FOLLOWING

# Timer
const MIKU_DURATION := 300.0  # 5 minutes
var time_remaining: float = MIKU_DURATION

# Corruption stages: 1 (normal) to 4 (skeleton)
var corruption_stage: int = 1

# Following mechanics
var player: CharacterBody2D = null
var follow_offset: Vector2 = Vector2(-100, 0)  # 100 pixels to left
var follow_speed: float = 250.0
var min_distance: float = 80.0   # Don't get closer than this
var max_distance: float = 300.0  # Teleport if farther than this

# Animation
var bob_amplitude: float = 10.0
var bob_speed: float = 2.0
var bob_time: float = 0.0

# Visual
@onready var sprite: ColorRect = $ColorRect

# Signals
signal kiku_vanished(position: Vector2)
signal corruption_stage_changed(stage: int)
signal kiku_spawned

func _ready() -> void:
	add_to_group("kiku_companion")

	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_error("KikuCompanion: Player not found!")
		queue_free()
		return

	# Setup sprite
	if sprite:
		sprite.size = Vector2(32, 32)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0, 0.85, 1)  # Cyan (normal)

	# No collision with anything
	collision_layer = 0
	collision_mask = 0

	# Apply buffs to player
	apply_buffs_to_player()

	# Chat message
	ChatBox.send_chat_message("Kiku", "Thank you! I will fight by your side!", "Kiku", get_tree())

	# Emit signal
	kiku_spawned.emit()

	print("Kiku Companion spawned at %s" % global_position)
	print("Timer: %d:00 started" % int(MIKU_DURATION / 60))


func _physics_process(delta: float) -> void:
	if current_state != KikuState.FOLLOWING:
		return

	# Update timer
	time_remaining -= delta
	if time_remaining <= 0:
		start_vanish_sequence()
		return

	# Check corruption stage
	update_corruption_stage()

	# Follow player
	follow_player(delta)

	# Bobbing animation
	animate_bobbing(delta)


func follow_player(delta: float) -> void:
	"""Follow player with smooth movement"""

	if not player or not is_instance_valid(player):
		return

	var target_pos := player.global_position + follow_offset
	var distance := global_position.distance_to(target_pos)

	# Teleport if too far
	if distance > max_distance:
		global_position = target_pos
		return

	# Move toward target if beyond min distance
	if distance > min_distance:
		var direction := (target_pos - global_position).normalized()
		velocity = direction * follow_speed
		move_and_slide()

		# Flip sprite based on movement
		if direction.x != 0 and sprite:
			sprite.scale.x = -1 if direction.x > 0 else 1
	else:
		velocity = Vector2.ZERO


func animate_bobbing(delta: float) -> void:
	"""Smooth bobbing animation"""

	if not sprite:
		return

	bob_time += delta
	var bob_offset := sin(bob_time * bob_speed * TAU) * bob_amplitude
	sprite.position.y = -sprite.size.y / 2 + bob_offset


func update_corruption_stage() -> void:
	"""Update corruption stage based on time remaining"""

	var new_stage := get_corruption_stage_from_time()

	if new_stage != corruption_stage:
		corruption_stage = new_stage
		transition_to_stage(new_stage)


func get_corruption_stage_from_time() -> int:
	"""Get corruption stage based on time remaining"""

	if time_remaining > 180:      # 3-5 min
		return 1  # Normal
	elif time_remaining > 120:    # 2-3 min
		return 2  # Pale
	elif time_remaining > 60:     # 1-2 min
		return 3  # Half skeleton
	else:                         # 0-1 min
		return 4  # Full skeleton


func transition_to_stage(stage: int) -> void:
	"""Transition to new corruption stage"""

	if not sprite:
		return

	var target_color := get_stage_color(stage)

	# Smooth color transition (2 seconds)
	var tween := create_tween()
	tween.tween_property(sprite, "color", target_color, 2.0)

	# Emit signal for HUD updates
	corruption_stage_changed.emit(stage)

	# Send chat message
	var message := get_stage_message(stage)
	if not message.is_empty():
		ChatBox.send_chat_message("Kiku", message, "Kiku", get_tree())

	print("Corruption stage changed: %d" % stage)


func get_stage_color(stage: int) -> Color:
	"""Get color for corruption stage"""

	match stage:
		1: return Color(0, 0.85, 1)        # Cyan (normal)
		2: return Color(0.7, 0.7, 0.75)    # Gray (pale)
		3: return Color(0.83, 0.83, 0.88)  # Light gray (half)
		4: return Color(0.95, 0.95, 0.95)  # White (skeleton)
		_: return Color.WHITE


func get_stage_message(stage: int) -> String:
	"""Get chat message for corruption stage"""

	match stage:
		2: return "My strength is fading..."
		3: return "No... it is happening..."
		4: return "I must leave soon..."
		_: return ""


func apply_buffs_to_player() -> void:
	"""Apply Kiku's buffs to player"""

	if not player or not player.has_method("apply_kiku_buffs"):
		return

	var buffs := {
		"attack_speed": 1.3,   # +30%
		"hp_regen": 1.2,       # +20%
		"crit_chance": 0.1,    # +10%
		"move_speed": 1.15     # +15%
	}

	player.apply_kiku_buffs(buffs)
	print("Buffs applied to player")


func start_vanish_sequence() -> void:
	"""Start Kiku's vanish sequence"""

	current_state = KikuState.VANISHING

	# Stop moving
	velocity = Vector2.ZERO
	set_physics_process(false)

	# Chat dialogue
	ChatBox.send_chat_message("Kiku", "Goodbye... Thank you...", "Kiku", get_tree())

	await get_tree().create_timer(1.0).timeout

	# Screen flash
	flash_screen(Color.WHITE, 0.5)

	# Fade animation
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 2.0)
		await tween.finished

	# Particle burst
	var particle_manager := get_node_or_null("/root/ParticleManager")
	if particle_manager:
		particle_manager.create_level_up_effect(global_position)

	# Camera shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(5.0, 0.5)

	# Remove buffs from player
	if player and is_instance_valid(player) and player.has_method("remove_kiku_buffs"):
		player.remove_kiku_buffs()

	print("Kiku vanishing...")

	# Store position for fragment animation
	var vanish_pos := global_position

	# Emit signal for fragment collection
	kiku_vanished.emit(vanish_pos)

	# Despawn
	queue_free()


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


func get_time_remaining_formatted() -> String:
	"""Get formatted time remaining (MM:SS)"""

	var minutes := int(time_remaining) / 60
	var seconds := int(time_remaining) % 60
	return "%02d:%02d" % [minutes, seconds]


func force_vanish() -> void:
	"""Force Kiku to vanish immediately (for testing)"""

	time_remaining = 0
	start_vanish_sequence()
