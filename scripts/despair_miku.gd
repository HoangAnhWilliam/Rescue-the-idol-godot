extends CharacterBody2D
class_name DespairMiku

## Despair Miku - Final boss of Miku Rescue Quest
## 3 phases with 7 unique attacks
## Defeating her grants permanent Miku companion

enum State { INTRO, IDLE, CHASE, ATTACK, DEAD }
enum BossPhase { PHASE_1, PHASE_2, PHASE_3 }

# Stats
var max_hp: float = 1000.0
var current_hp: float = 1000.0
var base_damage: float = 20.0
var move_speed: float = 40.0
var detection_range: float = 800.0
var attack_range: float = 150.0
var xp_reward: float = 500.0
var gold_reward: int = 5000

# State
var current_state: State = State.INTRO
var current_phase: BossPhase = BossPhase.PHASE_1
var player: CharacterBody2D = null

# Ability cooldowns
var ability_cooldowns := {
	"tears": 0.0,
	"lament_wave": 0.0,
	"shadow_clone": 0.0,
	"despair_beam": 0.0,
	"skeleton_summon": 0.0,
	"teleport_strike": 0.0,
	"void_collapse": 0.0
}

const TEARS_CD := 6.0
const LAMENT_WAVE_CD := 8.0
const SHADOW_CLONE_CD := 15.0
const DESPAIR_BEAM_CD := 12.0
const SKELETON_SUMMON_CD := 20.0
const TELEPORT_STRIKE_CD := 12.0
const VOID_COLLAPSE_CD := 25.0

# Phase tracking
var phase_transition_active: bool = false

# Visual
@onready var sprite: ColorRect = $ColorRect
@onready var hp_bar: ProgressBar = $HPBar

# Scenes
var tear_projectile_scene: PackedScene = preload("res://scenes/projectiles/tear_projectile.tscn")
var permanent_miku_scene: PackedScene = preload("res://scenes/miku/permanent_miku.tscn")

# Signals
signal boss_defeated
signal phase_changed(new_phase: int)

func _ready() -> void:
	add_to_group("bosses")
	add_to_group("despair_miku")

	# Setup sprite
	if sprite:
		sprite.size = Vector2(64, 64)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0.5, 0.85, 0.95)  # Cyan-white mix

	# Setup HP bar
	setup_hp_bar()

	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	# Start boss intro
	start_boss_intro()

	print("=== DESPAIR MIKU BOSS SPAWNED ===")


func setup_hp_bar() -> void:
	"""Setup boss HP bar at top of screen"""

	if not hp_bar:
		hp_bar = ProgressBar.new()
		add_child(hp_bar)

	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.custom_minimum_size = Vector2(200, 12)
	hp_bar.position = Vector2(-100, -50)
	hp_bar.show_percentage = false


func start_boss_intro() -> void:
	"""Boss introduction sequence"""

	current_state = State.INTRO

	# Spawn animation: Rise from below
	modulate.a = 0.0
	var start_y := position.y + 100
	position.y = start_y

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", start_y - 100, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 1.5)

	await tween.finished

	# Dialogue sequence
	ChatBox.send_chat_message("Despair Miku", "You freed me... only to bind me...", "DespairMiku", get_tree())
	await get_tree().create_timer(2.5).timeout

	ChatBox.send_chat_message("Despair Miku", "I am the despair you cannot escape...", "DespairMiku", get_tree())
	await get_tree().create_timer(2.5).timeout

	ChatBox.send_chat_message("Despair Miku", "FACE ME!", "DespairMiku", get_tree())
	await get_tree().create_timer(1.0).timeout

	# Start combat
	start_combat()


func start_combat() -> void:
	"""Start combat phase"""

	current_state = State.CHASE
	print("Despair Miku combat started!")


func _physics_process(delta: float) -> void:
	if current_state == State.DEAD or current_state == State.INTRO:
		return

	# Update cooldowns
	update_cooldowns(delta)

	# Check phase transitions
	check_phase_transitions()

	# State machine
	match current_state:
		State.IDLE:
			check_for_player()

		State.CHASE:
			chase_player(delta)

		State.ATTACK:
			execute_phase_attacks(delta)


func update_cooldowns(delta: float) -> void:
	"""Update all ability cooldowns"""

	for ability in ability_cooldowns:
		if ability_cooldowns[ability] > 0:
			ability_cooldowns[ability] -= delta


func check_for_player() -> void:
	"""Check if player is within detection range"""

	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
		return

	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_range:
		current_state = State.CHASE


func chase_player(delta: float) -> void:
	"""Chase player"""

	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	if distance <= attack_range:
		current_state = State.ATTACK
		velocity = Vector2.ZERO
		return

	# Move toward player
	var direction := (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Flip sprite
	if sprite and direction.x != 0:
		sprite.scale.x = -1 if direction.x > 0 else 1


func check_phase_transitions() -> void:
	"""Check and trigger phase transitions"""

	if phase_transition_active:
		return

	var hp_percent := current_hp / max_hp

	if hp_percent <= 0.7 and current_phase == BossPhase.PHASE_1:
		enter_phase_2()

	elif hp_percent <= 0.4 and current_phase == BossPhase.PHASE_2:
		enter_phase_3()


func enter_phase_2() -> void:
	"""Enter Phase 2: RAGE (70% HP)"""

	phase_transition_active = true
	current_phase = BossPhase.PHASE_2

	# Stop attacking
	current_state = State.IDLE
	velocity = Vector2.ZERO

	# Dialogue
	ChatBox.send_chat_message("Despair Miku", "You infuriate me!", "DespairMiku", get_tree())

	# Visual changes: Add red tint
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(1.2, 0.5, 0.5), 1.0)
		await tween.finished

	# Increase speed
	move_speed = 60.0

	# Screen shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(20.0, 1.0)

	# Reset cooldowns
	for ability in ability_cooldowns:
		ability_cooldowns[ability] = 0.0

	# Emit signal
	phase_changed.emit(2)

	print("=== PHASE 2: RAGE ===")

	# Resume combat
	current_state = State.CHASE
	phase_transition_active = false


func enter_phase_3() -> void:
	"""Enter Phase 3: ACCEPTANCE (40% HP)"""

	phase_transition_active = true
	current_phase = BossPhase.PHASE_3

	# Stop attacking
	current_state = State.IDLE
	velocity = Vector2.ZERO

	# Dialogue
	ChatBox.send_chat_message("Despair Miku", "This is my ultimate power!", "DespairMiku", get_tree())

	# Visual: Purple-cyan mix
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(0.7, 0.6, 0.9), 1.0)
		await tween.finished

	# Adjust speed
	move_speed = 50.0

	# Massive shake
	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(30.0, 2.0)

	# Reset cooldowns
	for ability in ability_cooldowns:
		ability_cooldowns[ability] = 0.0

	# Emit signal
	phase_changed.emit(3)

	print("=== PHASE 3: ACCEPTANCE ===")

	# Resume combat
	current_state = State.CHASE
	phase_transition_active = false


func execute_phase_attacks(delta: float) -> void:
	"""Execute attacks based on current phase"""

	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > attack_range * 2:
		current_state = State.CHASE
		return

	# Phase-specific attack patterns
	match current_phase:
		BossPhase.PHASE_1:
			execute_phase1_attacks()

		BossPhase.PHASE_2:
			execute_phase2_attacks()

		BossPhase.PHASE_3:
			execute_phase3_attacks()


func execute_phase1_attacks() -> void:
	"""Phase 1 attacks: Tears, Lament Wave, Shadow Clone"""

	if ability_cooldowns["tears"] <= 0:
		attack_tears()
		ability_cooldowns["tears"] = TEARS_CD

	elif ability_cooldowns["lament_wave"] <= 0:
		attack_lament_wave()
		ability_cooldowns["lament_wave"] = LAMENT_WAVE_CD

	elif ability_cooldowns["shadow_clone"] <= 0:
		attack_shadow_clone()
		ability_cooldowns["shadow_clone"] = SHADOW_CLONE_CD


func execute_phase2_attacks() -> void:
	"""Phase 2 adds: Despair Beam, Skeleton Summon, Teleport Strike"""

	if ability_cooldowns["despair_beam"] <= 0:
		attack_despair_beam()
		ability_cooldowns["despair_beam"] = DESPAIR_BEAM_CD

	elif ability_cooldowns["teleport_strike"] <= 0:
		attack_teleport_strike()
		ability_cooldowns["teleport_strike"] = TELEPORT_STRIKE_CD

	elif ability_cooldowns["skeleton_summon"] <= 0:
		attack_skeleton_summon()
		ability_cooldowns["skeleton_summon"] = SKELETON_SUMMON_CD

	elif ability_cooldowns["tears"] <= 0:
		attack_tears()
		ability_cooldowns["tears"] = TEARS_CD

	elif ability_cooldowns["shadow_clone"] <= 0:
		attack_shadow_clone()
		ability_cooldowns["shadow_clone"] = SHADOW_CLONE_CD


func execute_phase3_attacks() -> void:
	"""Phase 3 adds: Void Collapse (ultimate)"""

	if ability_cooldowns["void_collapse"] <= 0:
		attack_void_collapse()
		ability_cooldowns["void_collapse"] = VOID_COLLAPSE_CD

	elif ability_cooldowns["despair_beam"] <= 0:
		attack_despair_beam()
		ability_cooldowns["despair_beam"] = DESPAIR_BEAM_CD

	elif ability_cooldowns["teleport_strike"] <= 0:
		attack_teleport_strike()
		ability_cooldowns["teleport_strike"] = TELEPORT_STRIKE_CD

	elif ability_cooldowns["tears"] <= 0:
		attack_tears()
		ability_cooldowns["tears"] = TEARS_CD


# ============ ATTACKS ============

func attack_tears() -> void:
	"""Attack 1: Tear Projectiles (5 homing tears)"""

	print("Despair Miku: Tear Projectiles")

	for i in range(5):
		var tear := tear_projectile_scene.instantiate()
		tear.global_position = global_position
		tear.setup(player, 15.0, 100.0, true)  # homing = true
		get_parent().add_child(tear)

		await get_tree().create_timer(0.3).timeout


func attack_lament_wave() -> void:
	"""Attack 2: Lament Wave (expanding AoE)"""

	print("Despair Miku: Lament Wave")

	# Create expanding shockwave
	var wave := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10

	collision.shape = shape
	wave.add_child(collision)
	wave.global_position = global_position
	get_parent().add_child(wave)

	# Visual circle
	var visual := ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = -visual.size / 2
	visual.color = Color(0.8, 0.5, 0.9, 0.4)
	wave.add_child(visual)

	# Track if player hit
	var player_hit := false

	wave.body_entered.connect(func(body: Node2D) -> void:
		if body == player and not player_hit:
			player.take_damage(30.0, global_position)
			player_hit = true
	)

	# Expand wave
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(shape, "radius", 200, 1.2)
	tween.tween_property(visual, "size", Vector2(400, 400), 1.2)
	tween.tween_callback(func() -> void: visual.position = -visual.size / 2)

	await tween.finished
	wave.queue_free()


func attack_shadow_clone() -> void:
	"""Attack 3: Shadow Clone (spawn 2 clones)"""

	print("Despair Miku: Shadow Clone")

	for i in range(2):
		var clone := duplicate() as DespairMiku
		if not clone:
			continue

		# Setup as clone
		clone.max_hp = 50.0
		clone.current_hp = 50.0
		clone.base_damage = 8.0
		clone.modulate.a = 0.6  # Semi-transparent

		# Position around boss
		var angle := (TAU / 2) * i
		clone.global_position = global_position + Vector2(cos(angle), sin(angle)) * 120

		# Remove HP bar from clone
		if clone.has_node("HPBar"):
			clone.get_node("HPBar").queue_free()

		get_parent().add_child(clone)

		# Make clone start in chase state
		clone.current_state = State.CHASE
		clone.current_phase = current_phase


func attack_despair_beam() -> void:
	"""Attack 4: Despair Beam (tracking laser)"""

	print("Despair Miku: Despair Beam")

	# Create laser Line2D
	var beam := Line2D.new()
	beam.width = 25.0
	beam.default_color = Color(0.8, 0, 0.8, 0.8)
	beam.z_index = 10
	add_child(beam)

	var duration := 3.0
	var elapsed := 0.0

	while elapsed < duration:
		if not player or not is_instance_valid(player):
			break

		# Update beam to track player
		var direction := (player.global_position - global_position).normalized()
		var beam_end := direction * 600

		beam.clear_points()
		beam.add_point(Vector2.ZERO)
		beam.add_point(beam_end)

		# Check collision with player (simplified - distance check)
		var to_player := player.global_position - global_position
		var distance_to_beam := abs(to_player.cross(direction))

		if distance_to_beam < 25 and to_player.length() < 600:
			player.take_damage(40.0 * get_physics_process_delta_time(), global_position)

		elapsed += get_physics_process_delta_time()
		await get_tree().process_frame

	beam.queue_free()


func attack_skeleton_summon() -> void:
	"""Attack 5: Skeleton Summon (5 skeletons in circle)"""

	print("Despair Miku: Skeleton Summon")

	ChatBox.send_chat_message("Despair Miku", "Fight in my name!", "DespairMiku", get_tree())

	# Summon 5 basic enemies in circle
	for i in range(5):
		# Create simple enemy placeholder
		var skeleton := CharacterBody2D.new()
		var sprite := ColorRect.new()
		sprite.size = Vector2(24, 24)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0.9, 0.9, 0.9)  # White (skeleton)
		skeleton.add_child(sprite)

		# Position in circle
		var angle := (TAU / 5) * i
		var offset := Vector2(cos(angle), sin(angle)) * 100
		skeleton.global_position = global_position + offset

		get_parent().add_child(skeleton)


func attack_teleport_strike() -> void:
	"""Attack 6: Teleport Strike (backstab)"""

	print("Despair Miku: Teleport Strike")

	if not player or not is_instance_valid(player):
		return

	# Fade out
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		await tween.finished

	# Teleport behind player
	var behind_offset := Vector2(-100, 0)
	if player.velocity != Vector2.ZERO:
		behind_offset = -player.velocity.normalized() * 100

	global_position = player.global_position + behind_offset

	# Fade in
	if sprite:
		var original_alpha := sprite.modulate.a
		sprite.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)
		await tween.finished

	# Backstab attack
	if global_position.distance_to(player.global_position) < 100:
		player.take_damage(50.0, global_position)

		# Knockback
		var knockback_dir := (player.global_position - global_position).normalized()
		player.velocity = knockback_dir * 400


func attack_void_collapse() -> void:
	"""Attack 7: Void Collapse (ultimate AoE + void zones)"""

	print("Despair Miku: VOID COLLAPSE!")

	ChatBox.send_chat_message("Despair Miku", "VOID COLLAPSE!", "DespairMiku", get_tree())

	# Warning circle (3 second telegraph)
	var warning := ColorRect.new()
	warning.size = Vector2(600, 600)
	warning.position = -warning.size / 2
	warning.color = Color(0.8, 0, 0.8, 0.2)
	warning.z_index = -1
	add_child(warning)

	# Pulse animation
	for i in range(6):
		var tween := create_tween()
		tween.tween_property(warning, "modulate:a", 0.8, 0.25)
		tween.tween_property(warning, "modulate:a", 0.2, 0.25)
		await tween.finished

	warning.queue_free()

	# Execute attack
	var explosion_area := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 300
	collision.shape = shape
	explosion_area.add_child(collision)
	explosion_area.global_position = global_position
	get_parent().add_child(explosion_area)

	# Check if player in range
	await get_tree().process_frame
	if explosion_area.overlaps_body(player):
		player.take_damage(100.0, global_position)

		# Camera shake
		var camera_shake := get_node_or_null("/root/CameraShake")
		if camera_shake:
			camera_shake.shake(40.0, 1.0)

	explosion_area.queue_free()

	# Create void zones (3 pools)
	for i in range(3):
		create_void_zone()


func create_void_zone() -> void:
	"""Create damaging void zone"""

	var zone := Area2D.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 40
	collision.shape = shape
	zone.add_child(collision)

	# Visual
	var visual := ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color(0.3, 0, 0.3, 0.6)
	zone.add_child(visual)

	# Random position near boss
	var offset := Vector2(randf_range(-150, 150), randf_range(-150, 150))
	zone.global_position = global_position + offset

	get_parent().add_child(zone)

	# Damage over time (every 0.5s)
	var damage_timer := Timer.new()
	damage_timer.wait_time = 0.5
	damage_timer.timeout.connect(func() -> void:
		if zone.overlaps_body(player):
			player.take_damage(10.0, zone.global_position)
	)
	zone.add_child(damage_timer)
	damage_timer.start()

	# Lifetime: 10 seconds
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(zone):
		zone.queue_free()


# ============ DAMAGE & DEATH ============

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO) -> void:
	"""Take damage"""

	if current_state == State.DEAD:
		return

	current_hp -= amount
	update_hp_bar()

	# Hit effect
	var particle_manager := get_node_or_null("/root/ParticleManager")
	if particle_manager:
		particle_manager.create_hit_effect(global_position)

	# Flash
	if sprite:
		var original_modulate := sprite.modulate
		sprite.modulate = Color(2, 2, 2)
		await get_tree().create_timer(0.1).timeout
		if sprite and is_instance_valid(self):
			sprite.modulate = original_modulate

	# Check death
	if current_hp <= 0:
		die()


func update_hp_bar() -> void:
	"""Update HP bar"""

	if hp_bar:
		hp_bar.value = current_hp


func die() -> void:
	"""Boss defeat sequence"""

	current_state = State.DEAD
	set_physics_process(false)

	# Stop all attacks
	velocity = Vector2.ZERO

	# Dialogue
	ChatBox.send_chat_message("Despair Miku", "At last... I am free...", "DespairMiku", get_tree())

	await get_tree().create_timer(2.0).timeout

	# Transform to light
	if sprite:
		sprite.color = Color(0, 0.85, 1)  # Pure cyan
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "modulate", Color(3, 3, 3), 2.0)  # Bright glow
		tween.tween_property(sprite, "scale", Vector2(2, 2), 2.0)  # Expand
		await tween.finished

	# Victory effects
	flash_screen(Color.WHITE, 1.0)

	var camera_shake := get_node_or_null("/root/CameraShake")
	if camera_shake:
		camera_shake.shake(25.0, 1.5)

	var particle_manager := get_node_or_null("/root/ParticleManager")
	if particle_manager:
		particle_manager.create_level_up_effect(global_position)

	# Give rewards
	if player and is_instance_valid(player):
		if player.has_method("add_xp"):
			player.add_xp(xp_reward)
		if player.has_method("add_gold"):
			player.add_gold(gold_reward)

	# Spawn permanent Miku
	spawn_permanent_miku()

	# Chat notifications
	ChatBox.send_chat_message("System", "", "System", get_tree())
	ChatBox.send_chat_message("System", "VICTORY!", "System", get_tree())
	ChatBox.send_chat_message("System", "You obtained Permanent Miku!", "System", get_tree())
	ChatBox.send_chat_message("System", "", "System", get_tree())

	# Save progress
	var save_system := get_node_or_null("/root/SaveSystem")
	if save_system:
		if save_system.get("save_data"):
			var save_data: Dictionary = save_system.save_data
			if save_data.has("progress"):
				save_data.progress["despair_miku_defeated"] = true
				save_data.progress["miku_rescues"] = save_data.progress.get("miku_rescues", 0) + 1
			save_system.save_game()

	# Emit signal
	boss_defeated.emit()

	print("=== DESPAIR MIKU DEFEATED ===")

	# Despawn
	queue_free()


func spawn_permanent_miku() -> void:
	"""Spawn permanent Miku pet for player"""

	if not player or not is_instance_valid(player):
		return

	var miku := permanent_miku_scene.instantiate()
	# Miku will auto-attach to player in its _ready()
	get_parent().add_child(miku)

	print(" Permanent Miku pet spawned!")


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
