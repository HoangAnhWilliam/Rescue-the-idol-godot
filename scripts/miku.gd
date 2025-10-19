extends CharacterBody2D
class_name Miku

# Corruption sprites
var corruption_stages: Array[Texture2D] = []

# State
enum MikuState { SEALED, RESCUED, CORRUPTING, VANISHED }
var current_state: MikuState = MikuState.SEALED

# Timer
var miku_duration: float = 600.0  # 10 minutes
var miku_timer: float = 0.0

# References
var player: CharacterBody2D  # ← SỬA: Đổi từ Player thành CharacterBody2D
@onready var sprite := $Sprite2D
@onready var follow_offset: Vector2 = Vector2(-100, 0)

# Movement
var follow_speed: float = 250.0
var min_distance: float = 80.0

# Signals
signal miku_vanished

func _ready():
	load_corruption_sprites()
	if current_state == MikuState.RESCUED:
		start_following()

func _physics_process(delta):
	if current_state != MikuState.RESCUED and current_state != MikuState.CORRUPTING:
		return
	
	# Update timer
	miku_timer += delta
	
	# Check for vanish
	if miku_timer >= miku_duration:
		vanish()
		return
	
	# Update corruption visual
	if miku_timer >= 300.0:  # After 5 minutes
		current_state = MikuState.CORRUPTING
		update_corruption_visual()
	
	# Follow player
	follow_player(delta)

func start_following():
	current_state = MikuState.RESCUED
	miku_timer = 0.0
	
	# Apply buffs to player
	if player:
		# TODO: Apply buffs later
		pass
		# player.apply_miku_buffs()
		# player.equip_weapon(create_miku_sword())
	
	# Start music - COMMENT TẠM THỜI ↓
	# AudioManager.play_miku_music()
	print("Miku started following!")

func follow_player(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	var target_pos = player.global_position + follow_offset
	var distance = global_position.distance_to(target_pos)
	
	if distance > min_distance:
		var direction = (target_pos - global_position).normalized()
		velocity = direction * follow_speed
		move_and_slide()
		
		# Flip sprite
		if sprite and direction.x != 0:  # ← THÊM check sprite tồn tại
			sprite.flip_h = direction.x > 0

func update_corruption_visual():
	if corruption_stages.size() == 0:  # ← THÊM check
		return
		
	var time_ratio = (miku_timer - 300.0) / 300.0  # 0-1 over last 5 minutes
	var stage = int(time_ratio * 4)
	stage = clamp(stage, 0, corruption_stages.size() - 1)
	
	if sprite:  # ← THÊM check
		sprite.texture = corruption_stages[stage]
		
		# Fade effect in last 30 seconds
		if miku_timer >= miku_duration - 30.0:
			var fade_progress = (miku_duration - miku_timer) / 30.0
			sprite.modulate.a = fade_progress

func vanish():
	current_state = MikuState.VANISHED
	
	# Remove buffs
	if player:
		# TODO: Remove buffs later
		pass
		# player.remove_miku_buffs()
	
	# Fade out music - COMMENT TẠM THỜI ↓
	# AudioManager.fade_out_music()
	print("Miku vanished!")
	
	# Play vanish effect
	play_vanish_effect()
	
	miku_vanished.emit()
	
	# Remove self
	await get_tree().create_timer(2.0).timeout
	queue_free()

func play_vanish_effect():
	# TODO: Particle effect
	# TODO: Sound effect
	print("Vanish effect played")

func load_corruption_sprites():
	# TODO: Load sprites later when we have them
	# For now, leave empty array
	corruption_stages = []
	
	# COMMENT TẠM THỜI ↓
	# corruption_stages = [
	# 	load("res://sprites/miku_normal.png"),
	# 	load("res://sprites/miku_pale.png"),
	# 	load("res://sprites/miku_half_skeleton.png"),
	# 	load("res://sprites/miku_skeleton.png")
	# ]

func create_miku_sword():
	# TODO: Create weapon later
	# COMMENT TẠM THỜI ↓
	# var sword = preload("res://weapons/miku_sword.tscn").instantiate()
	# return sword
	return null

func get_time_remaining() -> float:
	return miku_duration - miku_timer

func get_time_remaining_formatted() -> String:
	var remaining = get_time_remaining()
	var minutes = int(remaining / 60)
	var seconds = int(remaining) % 60
	return "%d:%02d" % [minutes, seconds]
