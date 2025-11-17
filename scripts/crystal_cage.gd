extends Area2D
class_name CrystalCage

## Crystal cage containing Miku
## Can be active (interactable) or dormant (non-interactable)
## Sequential activation system

@onready var background: ColorRect = $Background
@onready var miku_sprite: ColorRect = $MikuSprite
@onready var chains: Node2D = $Chains
@onready var particles: CPUParticles2D = $Particles
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_prompt: Label = $InteractionPrompt

# State
var is_active: bool = false
var cage_number: int = 0
var player_in_range: bool = false

# References
var miku_companion_scene: PackedScene = preload("res://scenes/miku/miku_companion.tscn")

# Signals
signal cage_opened(cage_number: int)
signal rescue_completed(cage_number: int)

func _ready() -> void:
	add_to_group("crystal_cages")

	# Setup visuals
	setup_visuals()

	# Connect signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Hide interaction prompt
	if interaction_prompt:
		interaction_prompt.hide()

	# Start as dormant
	set_dormant()


func setup_visuals() -> void:
	"""Setup cage visual elements"""

	# Background
	if background:
		background.size = Vector2(64, 64)
		background.position = -background.size / 2

	# Miku inside
	if miku_sprite:
		miku_sprite.size = Vector2(32, 32)
		miku_sprite.position = -miku_sprite.size / 2
		miku_sprite.color = Color(0, 0.85, 1, 1.0)  # Cyan

	# Create chain visuals
	if chains:
		create_chains()

	# Setup particles
	if particles:
		particles.emitting = false
		particles.amount = 20
		particles.lifetime = 2.0
		particles.direction = Vector2(0, -1)
		particles.gravity = Vector2(0, -50)
		particles.initial_velocity_min = 20.0
		particles.initial_velocity_max = 40.0
		particles.color = Color(0, 0.85, 1, 0.8)

	# Setup collision
	if collision_shape:
		var shape := CircleShape2D.new()
		shape.radius = 80
		collision_shape.shape = shape


func create_chains() -> void:
	"""Create chain visual elements around Miku"""

	if not chains:
		return

	for i in range(4):
		var chain := ColorRect.new()
		chain.size = Vector2(4, 16)
		chain.color = Color(0.5, 0.5, 0.5)

		# Position around Miku (4 corners)
		var angle := (TAU / 4) * i + TAU / 8
		var offset := Vector2(cos(angle), sin(angle)) * 20
		chain.position = offset - chain.size / 2

		chains.add_child(chain)


func set_active() -> void:
	"""Make cage active (interactable, glowing)"""

	is_active = true

	# Update background
	if background:
		background.color = Color(0, 0.85, 1, 0.6)  # Cyan semi-transparent
		background.modulate = Color(1.5, 1.5, 1.5)  # Glow

	# Start pulse animation
	start_pulse_animation()

	# Enable particles
	if particles:
		particles.emitting = true

	# Enable collision
	if collision_shape:
		collision_shape.disabled = false

	# Chat notification
	ChatBox.send_chat_message("System", "A crystal cage has appeared!", "System", get_tree())

	print("Crystal Cage #%d activated at %s" % [cage_number, global_position])


func set_dormant() -> void:
	"""Make cage dormant (non-interactable, dim)"""

	is_active = false

	# Update background
	if background:
		background.color = Color(0.3, 0.3, 0.3, 0.3)  # Gray transparent
		background.modulate = Color(1, 1, 1)  # No glow

	# Stop animations
	stop_pulse_animation()

	# Disable particles
	if particles:
		particles.emitting = false

	# Disable collision
	if collision_shape:
		collision_shape.disabled = true


func start_pulse_animation() -> void:
	"""Start pulsing glow animation"""

	if not background:
		return

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(background, "scale", Vector2(1.05, 1.05), 1.0)
	tween.tween_property(background, "scale", Vector2(0.95, 0.95), 1.0)


func stop_pulse_animation() -> void:
	"""Stop pulsing animation"""

	if background:
		background.scale = Vector2(1, 1)


func start_bobbing_animation() -> void:
	"""Start Miku bobbing animation"""

	if not miku_sprite:
		return

	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(miku_sprite, "position:y", -miku_sprite.size.y / 2 - 5, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(miku_sprite, "position:y", -miku_sprite.size.y / 2 + 5, 1.0).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	"""Player entered cage area"""

	if not is_active:
		return

	if body.is_in_group("player"):
		player_in_range = true
		show_interaction_prompt()


func _on_body_exited(body: Node2D) -> void:
	"""Player exited cage area"""

	if body.is_in_group("player"):
		player_in_range = false
		hide_interaction_prompt()


func show_interaction_prompt() -> void:
	"""Show 'Press E to rescue' prompt"""

	if interaction_prompt:
		interaction_prompt.text = "Press E to rescue Miku"
		interaction_prompt.show()


func hide_interaction_prompt() -> void:
	"""Hide interaction prompt"""

	if interaction_prompt:
		interaction_prompt.hide()


func _input(event: InputEvent) -> void:
	"""Handle interaction input"""

	if not is_active or not player_in_range:
		return

	if event.is_action_pressed("interact"):  # E key
		attempt_rescue()


func attempt_rescue() -> void:
	"""Attempt to rescue Miku from cage"""

	# Check if player has key
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		return

	if not player.has_method("has_item") or not player.has_item("Miku's Seal Key"):
		ChatBox.send_chat_message("System", "You need the Sealing Key!", "System", get_tree())
		return

	# Note: Key is PERMANENT (not consumed)
	start_rescue_sequence()


func start_rescue_sequence() -> void:
	"""Start the rescue sequence animation"""

	# Disable further interaction
	is_active = false
	player_in_range = false
	hide_interaction_prompt()

	# Freeze player
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player and player.has_method("disable_input"):
		player.disable_input()

	# Play chain break animation
	break_chains()

	await get_tree().create_timer(0.5).timeout

	# Cage fades out
	if background:
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(background, "modulate:a", 0.0, 0.5)
		tween.tween_property(chains, "modulate:a", 0.0, 0.5)
		await tween.finished

	# Miku flies upward
	if miku_sprite:
		var tween := create_tween()
		tween.tween_property(miku_sprite, "position:y", miku_sprite.position.y - 50, 0.5)
		await tween.finished

	# Chat
	ChatBox.send_chat_message("Miku", "Thank you! I will fight by your side!", "Miku", get_tree())

	# Spawn MikuCompanion
	spawn_miku_companion()

	# Enable player input
	if player and player.has_method("enable_input"):
		player.enable_input()

	# Change to dormant state
	set_dormant()
	visible = false

	# Emit signals
	cage_opened.emit(cage_number)
	rescue_completed.emit(cage_number)

	print("Crystal Cage #%d opened" % cage_number)


func break_chains() -> void:
	"""Animate chains breaking"""

	if not chains:
		return

	# Particle burst
	var particle_manager := get_node_or_null("/root/ParticleManager")
	if particle_manager:
		particle_manager.create_hit_effect(global_position)

	# Camera shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(10.0, 0.3)

	# Make chains fall
	for chain in chains.get_children():
		if chain is ColorRect:
			var tween := create_tween()
			tween.tween_property(chain, "position:y", chain.position.y + 50, 0.3)
			tween.parallel().tween_property(chain, "modulate:a", 0.0, 0.3)


func spawn_miku_companion() -> void:
	"""Spawn Miku companion at cage position"""

	var miku := miku_companion_scene.instantiate()
	miku.global_position = global_position
	get_parent().add_child(miku)

	print("Miku Companion spawned at %s" % global_position)


func transition_to_active() -> void:
	"""Smooth transition from dormant to active (2 seconds)"""

	# Make visible first
	visible = true

	# Transition animation
	var tween := create_tween()
	tween.set_parallel(true)

	if background:
		tween.tween_property(background, "modulate", Color(1.5, 1.5, 1.5), 2.0)
		tween.tween_property(background, "color", Color(0, 0.85, 1, 0.6), 2.0)

	if miku_sprite:
		tween.tween_property(miku_sprite, "color", Color(0, 0.85, 1, 1.0), 2.0)

	await tween.finished

	# Now set as active
	set_active()
