extends CharacterBody2D
class_name VampireLord

# ========== LORD CRIMSON NIGHTSHADE ==========
# "The Eternal Count", "Blood Moon Sovereign"
# Age: 847 years old
# Location: Volcanic Darklands (Blood Temple)

# ========== BOSS STATS ==========

@export var max_hp: float = 80000.0
@export var base_damage: float = 15.0
@export var base_move_speed: float = 180.0
@export var xp_reward: float = 50000.0
@export var detection_range: float = 600.0
@export var gold_drop_min: int = 80000
@export var gold_drop_max: int = 120000

# Current stats
var current_hp: float
var current_damage: float
var current_move_speed: float

# ========== PHASE SYSTEM ==========

enum Phase { PHASE_1_ARISTOCRAT, PHASE_2_BLOOD_MAGIC, PHASE_3_BAT_SWARM }
var current_phase: Phase = Phase.PHASE_1_ARISTOCRAT

# Phase HP thresholds
const PHASE_2_THRESHOLD: float = 0.66  # 66% HP
const PHASE_3_THRESHOLD: float = 0.33  # 33% HP

# Phase flags
var phase_2_triggered: bool = false
var phase_3_triggered: bool = false

# ========== STATE MACHINE ==========

enum State { IDLE, CHASE, ATTACKING, TELEPORTING, HEALING, PHASE_TRANSITION, DEAD }
var current_state: State = State.IDLE

# ========== ATTACK COOLDOWNS ==========

# Phase 1 abilities
var blood_slash_cooldown: float = 0.0
const BLOOD_SLASH_CD: float = 2.0
const BLOOD_SLASH_DAMAGE: float = 15.0
const BLOOD_SLASH_RANGE: float = 3.0

var crimson_lance_cooldown: float = 0.0
const CRIMSON_LANCE_CD: float = 5.0
const CRIMSON_LANCE_DAMAGE: float = 20.0
const CRIMSON_LANCE_RANGE: float = 15.0
const CRIMSON_LANCE_SPEED: float = 400.0

var shadow_step_cooldown: float = 0.0
const SHADOW_STEP_CD: float = 8.0

var thrall_summon_cooldown: float = 0.0
const THRALL_SUMMON_CD: float = 30.0
const THRALL_SUMMON_COUNT: int = 3

# Phase 2 abilities
var blood_pool_cooldown: float = 0.0
const BLOOD_POOL_CD: float = 15.0
const BLOOD_POOL_DAMAGE: float = 5.0  # Per second
const BLOOD_POOL_DURATION: float = 5.0

var sanguine_chains_cooldown: float = 0.0
const SANGUINE_CHAINS_CD: float = 20.0
const SANGUINE_CHAINS_DAMAGE: float = 30.0
const SANGUINE_CHAINS_STUN: float = 2.0

var life_drain_cooldown: float = 0.0
const LIFE_DRAIN_CD: float = 25.0
const LIFE_DRAIN_DAMAGE: float = 40.0
const LIFE_DRAIN_DURATION: float = 4.0

# Phase 3 abilities
var dive_bomb_cooldown: float = 0.0
const DIVE_BOMB_CD: float = 3.0
const DIVE_BOMB_DAMAGE: float = 35.0

var bat_tornado_cooldown: float = 0.0
const BAT_TORNADO_CD: float = 15.0
const BAT_TORNADO_DAMAGE: float = 10.0  # Per second
const BAT_TORNADO_DURATION: float = 8.0

var echo_shriek_cooldown: float = 0.0
const ECHO_SHRIEK_CD: float = 25.0
const ECHO_SHRIEK_DAMAGE: float = 50.0

var bat_bomb_cooldown: float = 0.0
const BAT_BOMB_CD: float = 8.0
const BAT_BOMB_DAMAGE: float = 30.0
const BAT_BOMB_COUNT: int = 5

var vampiric_regen_cooldown: float = 0.0
const VAMPIRIC_REGEN_CD: float = 40.0
const VAMPIRIC_REGEN_HEAL: float = 1000.0
const VAMPIRIC_REGEN_DURATION: float = 5.0
var vampiric_regen_uses: int = 2  # Can only use twice

# Special state flags
var is_teleporting: bool = false
var is_healing: bool = false
var is_channeling: bool = false
var is_flying: bool = false  # Phase 3

# Berserk mode (below 10% HP in Phase 3)
var berserk_mode: bool = false

# ========== REFERENCES ==========

@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null

var player: CharacterBody2D = null

# Preload effects
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")

# Preload projectile mover
var projectile_mover_script = preload("res://scripts/projectile_mover.gd")

# Preload minions
var vampire_thrall_scene: Resource = null  # Loaded in _ready

# Blood pools (healing zones in arena)
var blood_pools: Array[Area2D] = []

# ========== SIGNALS ==========

signal boss_defeated
signal phase_changed(phase: int)
signal attack_started(attack_type: String)

# ========== INITIALIZATION ==========

func _ready():
	print("")
	print("╔══════════════════════════════════════╗")
	print("║    VAMPIRE LORD INITIALIZED         ║")
	print("║   LORD CRIMSON NIGHTSHADE           ║")
	print("║     Age: 847 years                   ║")
	print("╚══════════════════════════════════════╝")

	# Initialize stats
	current_hp = max_hp
	current_damage = base_damage
	current_move_speed = base_move_speed

	print("Vampire Lord HP: ", max_hp)
	print("Vampire Lord Damage: ", base_damage)
	print("Vampire Lord Speed: ", base_move_speed)

	# Add to groups
	add_to_group("bosses")
	add_to_group("enemies")
	add_to_group("vampire_lord")

	# Scale up to boss size
	if sprite:
		sprite.scale = Vector2(4.0, 6.0)  # Tall aristocratic figure
		sprite.color = Color(0.8, 0.7, 0.85)  # Pale purple (vampire)
		print("✓ Boss scale set to 4.0 x 6.0")
		print("✓ Boss color set to pale vampire")

	# Load thrall scene
	vampire_thrall_scene = load("res://scenes/enemies/vampire_thrall.tscn")
	if vampire_thrall_scene:
		print("✓ Vampire Thrall scene loaded")
	else:
		print("⚠️ WARNING: Vampire Thrall scene not found")

	# Setup blood pools in arena
	setup_blood_pools()

	print("Vampire Lord ready!")
	print("══════════════════════════════════════")
	print("")

func setup_blood_pools():
	"""Create blood pool healing zones in arena"""
	# Create 2 blood pools on the sides
	var pool_positions = [
		global_position + Vector2(-300, 0),  # Left
		global_position + Vector2(300, 0)    # Right
	]

	for pos in pool_positions:
		var pool = Area2D.new()
		pool.name = "BloodPool"
		pool.global_position = pos

		# Visual
		var visual = ColorRect.new()
		visual.size = Vector2(150, 150)
		visual.position = -visual.size / 2
		visual.color = Color(0.6, 0.0, 0.0, 0.4)  # Dark red, semi-transparent
		pool.add_child(visual)

		# Collision
		var shape = CircleShape2D.new()
		shape.radius = 75
		var collision_shape = CollisionShape2D.new()
		collision_shape.shape = shape
		pool.add_child(collision_shape)

		# Add to scene
		get_tree().root.add_child(pool)
		blood_pools.append(pool)

	print("✓ Created 2 blood pools for healing")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update cooldown timers
	update_cooldowns(delta)

	# Check for blood pool healing
	check_blood_pool_healing(delta)

	# State machine
	match current_state:
		State.IDLE:
			search_for_player()

		State.CHASE:
			chase_player(delta)

		State.ATTACKING:
			perform_attacks(delta)

		State.TELEPORTING:
			# Handled by animation
			pass

		State.HEALING:
			# Channeling heal
			pass

		State.PHASE_TRANSITION:
			# Handled by tween
			pass

# ========== AI LOGIC ==========

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.ATTACKING
		play_dialogue_intro()
		print("🧛 Vampire Lord engaged!")

func chase_player(delta):
	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return

	var distance = global_position.distance_to(player.global_position)

	# Switch to attacking if in range
	if distance < detection_range:
		current_state = State.ATTACKING
		return

	# Move toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * current_move_speed

	if not is_flying:
		move_and_slide()
	else:
		# Phase 3: Flying movement (no collision)
		global_position += velocity * delta

	# Update sprite direction
	update_sprite_direction()

func perform_attacks(delta):
	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return

	# Don't attack while teleporting or channeling
	if is_teleporting or is_channeling:
		return

	var distance = global_position.distance_to(player.global_position)

	# Face player
	update_sprite_direction()

	# Attack based on phase
	match current_phase:
		Phase.PHASE_1_ARISTOCRAT:
			phase_1_ai(distance, delta)

		Phase.PHASE_2_BLOOD_MAGIC:
			phase_2_ai(distance, delta)

		Phase.PHASE_3_BAT_SWARM:
			phase_3_ai(distance, delta)

# ========== PHASE 1: ARISTOCRATIC DUEL ==========

func phase_1_ai(distance: float, delta: float):
	"""Phase 1: Melee focused with occasional teleports"""

	# 1. Thrall Summon (if HP below 80%)
	if current_hp < max_hp * 0.8 and thrall_summon_cooldown <= 0:
		summon_thralls(THRALL_SUMMON_COUNT)
		return

	# 2. Shadow Step (teleport behind player if far)
	if distance > 10.0 and shadow_step_cooldown <= 0:
		shadow_step_teleport()
		return

	# 3. Blood Slash (melee)
	if distance < BLOOD_SLASH_RANGE and blood_slash_cooldown <= 0:
		attack_blood_slash()
		return

	# 4. Crimson Lance (ranged)
	if distance >= BLOOD_SLASH_RANGE and distance < CRIMSON_LANCE_RANGE and crimson_lance_cooldown <= 0:
		attack_crimson_lance()
		return

	# 5. Move toward player if no attacks available
	if distance > BLOOD_SLASH_RANGE:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# ========== PHASE 2: BLOOD MAGIC AWAKENED ==========

func phase_2_ai(distance: float, delta: float):
	"""Phase 2: More aggressive, blood magic focused"""

	# 1. Life Drain (high priority when close)
	if distance < 8.0 and life_drain_cooldown <= 0:
		attack_life_drain()
		return

	# 2. Blood Pool Prison
	if blood_pool_cooldown <= 0:
		attack_blood_pool_prison()
		return

	# 3. Sanguine Chains (pull player)
	if distance > 5.0 and distance < 20.0 and sanguine_chains_cooldown <= 0:
		attack_sanguine_chains()
		return

	# 4. Enhanced Crimson Lance x3
	if distance > 8.0 and crimson_lance_cooldown <= 0:
		attack_crimson_lance_multi()
		return

	# 5. Enhanced Blood Slash
	if distance < 5.0 and blood_slash_cooldown <= 0:
		attack_blood_slash_enhanced()
		return

	# 6. Thrall Army (enhanced summon)
	if thrall_summon_cooldown <= 0:
		summon_thralls(5)  # 5 thralls in Phase 2
		return

	# 7. Shadow Step
	if distance > 15.0 and shadow_step_cooldown <= 0:
		shadow_step_teleport()
		return

	# Move toward player
	if distance > 8.0:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_move_speed * 1.2  # 20% faster in Phase 2
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# ========== PHASE 3: BAT SWARM LORD ==========

func phase_3_ai(distance: float, delta: float):
	"""Phase 3: Flying, swarm-based attacks"""

	# Check berserk mode (below 10% HP)
	if current_hp < max_hp * 0.10 and not berserk_mode:
		activate_berserk_mode()

	# 1. Vampiric Regeneration (if available and low HP)
	if current_hp < max_hp * 0.5 and vampiric_regen_uses > 0 and vampiric_regen_cooldown <= 0:
		attack_vampiric_regeneration()
		return

	# 2. Echo Location Shriek (AOE nuke)
	if echo_shriek_cooldown <= 0:
		attack_echo_shriek()
		return

	# 3. Bat Tornado
	if bat_tornado_cooldown <= 0:
		attack_bat_tornado()
		return

	# 4. Bat Bomb (homing bats)
	if bat_bomb_cooldown <= 0:
		attack_bat_bomb()
		return

	# 5. Dive Bomb (spam this)
	if dive_bomb_cooldown <= 0:
		attack_dive_bomb()
		return

	# 6. Summon thralls (max swarm in berserk)
	if berserk_mode and thrall_summon_cooldown <= 0:
		summon_thralls(10)  # 10 thralls in berserk mode!
		return

	# Fly around player erratically
	var orbit_angle = Time.get_ticks_msec() / 1000.0 * 2.0  # Rotate around
	var orbit_radius = 12.0
	var target_pos = player.global_position + Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius

	var direction = (target_pos - global_position).normalized()
	velocity = direction * current_move_speed * 1.4  # 40% faster in Phase 3
	global_position += velocity * delta  # Flying movement

func activate_berserk_mode():
	"""Activate final desperation mode below 10% HP"""
	berserk_mode = true

	print("🦇🦇🦇 VAMPIRE LORD BERSERK MODE ACTIVATED! 🦇🦇🦇")
	play_dialogue_berserk()

	# Increase attack speed (reduce cooldowns)
	current_move_speed *= 1.5

	# Visual: Darker, more intense
	if sprite:
		sprite.modulate = Color(0.3, 0.1, 0.2)  # Very dark purple

# ========== ATTACK IMPLEMENTATIONS ==========

func attack_blood_slash():
	"""Phase 1: Basic melee attack"""
	print("🧛 Vampire Lord: BLOOD SLASH!")

	attack_started.emit("blood_slash")
	blood_slash_cooldown = BLOOD_SLASH_CD

	CameraShake.shake(5.0, 0.15)

	# Check if player in range
	var distance = global_position.distance_to(player.global_position)
	if distance < BLOOD_SLASH_RANGE:
		if player.has_method("take_damage"):
			player.take_damage(BLOOD_SLASH_DAMAGE)
			print("💥 Blood Slash hit! Damage: %.1f" % BLOOD_SLASH_DAMAGE)

func attack_blood_slash_enhanced():
	"""Phase 2: Blood Slash shoots crescent wave"""
	print("🧛 Vampire Lord: ENHANCED BLOOD SLASH!")

	attack_started.emit("blood_slash_enhanced")
	blood_slash_cooldown = BLOOD_SLASH_CD

	CameraShake.shake(6.0, 0.15)

	# Spawn crescent wave projectile
	var wave = Area2D.new()
	wave.name = "BloodWave"

	var visual = ColorRect.new()
	visual.size = Vector2(60, 20)
	visual.position = -visual.size / 2
	visual.color = Color(0.8, 0.0, 0.0)  # Dark red
	wave.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	wave.add_child(collision_shape)

	wave.global_position = global_position

	var direction = (player.global_position - global_position).normalized()
	wave.set_meta("direction", direction)
	wave.set_meta("speed", 350.0)
	wave.set_meta("damage", 25.0)  # Enhanced damage
	wave.set_meta("lifetime", 3.0)
	wave.set_meta("from_boss", true)

	wave.set_script(projectile_mover_script)
	get_tree().root.add_child(wave)

func attack_crimson_lance():
	"""Phase 1: Single blood spear projectile"""
	print("🧛 Vampire Lord: CRIMSON LANCE!")

	attack_started.emit("crimson_lance")
	crimson_lance_cooldown = CRIMSON_LANCE_CD

	CameraShake.shake(5.0, 0.15)

	spawn_crimson_lance(player.global_position)

func attack_crimson_lance_multi():
	"""Phase 2: Triple lance spread"""
	print("🧛 Vampire Lord: CRIMSON LANCE x3!")

	attack_started.emit("crimson_lance_multi")
	crimson_lance_cooldown = CRIMSON_LANCE_CD - 1.0  # Faster cooldown

	CameraShake.shake(7.0, 0.2)

	# Shoot 3 lances in spread pattern
	var base_dir = (player.global_position - global_position).normalized()
	var spread_angle = deg_to_rad(20.0)

	for i in range(3):
		var angle_offset = spread_angle * (i - 1)  # -20°, 0°, +20°
		var direction = base_dir.rotated(angle_offset)
		var target_pos = global_position + direction * 20.0

		spawn_crimson_lance(target_pos)

		# Small delay between shots
		await get_tree().create_timer(0.1).timeout

func spawn_crimson_lance(target_pos: Vector2):
	"""Spawn a single crimson lance projectile"""
	var lance = Area2D.new()
	lance.name = "CrimsonLance"

	var visual = ColorRect.new()
	visual.size = Vector2(40, 12)
	visual.position = -visual.size / 2
	visual.color = Color(1.0, 0.1, 0.1)  # Bright red
	lance.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	lance.add_child(collision_shape)

	lance.global_position = global_position

	var direction = (target_pos - global_position).normalized()
	lance.set_meta("direction", direction)
	lance.set_meta("speed", CRIMSON_LANCE_SPEED)
	lance.set_meta("damage", CRIMSON_LANCE_DAMAGE)
	lance.set_meta("lifetime", 5.0)
	lance.set_meta("from_boss", true)

	lance.set_script(projectile_mover_script)
	get_tree().root.add_child(lance)

func shadow_step_teleport():
	"""Teleport behind player with follow-up attack"""
	print("🧛 Vampire Lord: SHADOW STEP!")

	attack_started.emit("shadow_step")
	shadow_step_cooldown = SHADOW_STEP_CD
	is_teleporting = true

	play_dialogue_teleport()

	# Fade out
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		await tween.finished
	else:
		await get_tree().create_timer(0.3).timeout

	# Teleport behind player
	var direction_from_player = (global_position - player.global_position).normalized()
	var behind_player = player.global_position + direction_from_player * 5.0
	global_position = behind_player

	print("💨 Teleported behind player!")

	# Fade in
	if sprite:
		var tween2 = create_tween()
		tween2.tween_property(sprite, "modulate:a", 1.0, 0.3)
		await tween2.finished
	else:
		await get_tree().create_timer(0.3).timeout

	is_teleporting = false

	# Immediate follow-up Blood Slash
	await get_tree().create_timer(0.2).timeout
	blood_slash_cooldown = 0.0  # Reset cooldown for instant attack
	attack_blood_slash()

func summon_thralls(count: int):
	"""Summon vampire thralls"""
	print("🧛 Vampire Lord: SUMMONING %d THRALLS!" % count)

	attack_started.emit("summon_thralls")
	thrall_summon_cooldown = THRALL_SUMMON_CD

	play_dialogue_summon()

	CameraShake.shake(8.0, 0.3)

	if not vampire_thrall_scene:
		print("❌ ERROR: Vampire Thrall scene not loaded!")
		return

	# Spawn thralls in circle around boss
	for i in range(count):
		var thrall = vampire_thrall_scene.instantiate()
		var angle = (TAU / count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 6.0
		thrall.global_position = global_position + offset
		get_tree().root.add_child(thrall)

		print("✓ Thrall %d spawned" % (i + 1))

func attack_blood_pool_prison():
	"""Phase 2: Create blood pools under player"""
	print("🧛 Vampire Lord: BLOOD POOL PRISON!")

	attack_started.emit("blood_pool_prison")
	blood_pool_cooldown = BLOOD_POOL_CD

	play_dialogue_blood_pool()

	CameraShake.shake(7.0, 0.2)

	# Create 3 blood pools around player
	for i in range(3):
		var offset = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		var pool_pos = player.global_position + offset

		create_damage_blood_pool(pool_pos)

func create_damage_blood_pool(pos: Vector2):
	"""Create a damaging blood pool"""
	var pool = Area2D.new()
	pool.name = "DamageBloodPool"
	pool.global_position = pos

	# Visual (red circle)
	var visual = ColorRect.new()
	visual.size = Vector2(120, 120)
	visual.position = -visual.size / 2
	visual.color = Color(0.8, 0.0, 0.0, 0.5)  # Red, semi-transparent
	pool.add_child(visual)

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = 60
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	pool.add_child(collision_shape)

	get_tree().root.add_child(pool)

	# Apply damage over time
	apply_blood_pool_damage(pool)

	# Remove after duration
	await get_tree().create_timer(BLOOD_POOL_DURATION).timeout
	if is_instance_valid(pool):
		pool.queue_free()

func apply_blood_pool_damage(pool: Area2D):
	"""Apply DOT and slow to player in blood pool"""
	var ticks = int(BLOOD_POOL_DURATION)

	for i in range(ticks):
		await get_tree().create_timer(1.0).timeout

		if not is_instance_valid(pool):
			break

		var bodies = pool.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(BLOOD_POOL_DAMAGE)
					print("🩸 Blood pool damage: %.1f" % BLOOD_POOL_DAMAGE)

				# Slow movement
				if "velocity" in body:
					body.velocity *= 0.5

func attack_sanguine_chains():
	"""Phase 2: Pull player toward boss and stun"""
	print("🧛 Vampire Lord: SANGUINE CHAINS!")

	attack_started.emit("sanguine_chains")
	sanguine_chains_cooldown = SANGUINE_CHAINS_CD

	play_dialogue_chains()

	CameraShake.shake(10.0, 0.3)

	# Deal damage
	if player.has_method("take_damage"):
		player.take_damage(SANGUINE_CHAINS_DAMAGE)

	# Pull player toward boss
	var pull_direction = (global_position - player.global_position).normalized()
	if "velocity" in player:
		player.velocity = pull_direction * 500.0

	print("⛓️ Player pulled and stunned!")

	# TODO: Implement stun (requires player stun mechanic)

func attack_life_drain():
	"""Phase 2: Grab player and drain life"""
	print("🧛 Vampire Lord: LIFE DRAIN!")

	attack_started.emit("life_drain")
	life_drain_cooldown = LIFE_DRAIN_CD
	is_channeling = true

	play_dialogue_life_drain()

	CameraShake.shake(8.0, 0.4)

	# Channel for duration
	var ticks = int(LIFE_DRAIN_DURATION)
	var damage_per_tick = LIFE_DRAIN_DAMAGE / ticks

	for i in range(ticks):
		await get_tree().create_timer(1.0).timeout

		if not is_instance_valid(self) or not is_instance_valid(player):
			break

		# Deal damage
		if player.has_method("take_damage"):
			player.take_damage(damage_per_tick)
			print("🧛 Life drained: %.1f" % damage_per_tick)

		# Heal self
		current_hp += damage_per_tick
		current_hp = min(current_hp, max_hp)
		print("💚 Vampire Lord healed: %.1f (%.1f/%.1f)" % [damage_per_tick, current_hp, max_hp])

	is_channeling = false
	print("✓ Life Drain complete!")

func attack_dive_bomb():
	"""Phase 3: Dive bomb from above"""
	print("🧛 Vampire Lord: DIVE BOMB!")

	attack_started.emit("dive_bomb")
	dive_bomb_cooldown = DIVE_BOMB_CD

	CameraShake.shake(10.0, 0.25)

	# Fly up
	var original_pos = global_position
	global_position.y -= 15.0

	# Wait briefly
	await get_tree().create_timer(0.3).timeout

	# Dive at player
	var dive_target = player.global_position
	var direction = (dive_target - global_position).normalized()

	# Fast dive
	var dive_speed = 600.0
	var dive_duration = 0.5
	var elapsed = 0.0

	while elapsed < dive_duration:
		var delta = get_physics_process_delta_time()
		elapsed += delta
		global_position += direction * dive_speed * delta

		# Check collision with player
		var dist = global_position.distance_to(player.global_position)
		if dist < 3.0:
			if player.has_method("take_damage"):
				player.take_damage(DIVE_BOMB_DAMAGE)
				print("💥 Dive Bomb hit! Damage: %.1f" % DIVE_BOMB_DAMAGE)
			break

		await get_tree().process_frame

	print("✓ Dive Bomb complete!")

func attack_bat_tornado():
	"""Phase 3: Create spinning bat tornado"""
	print("🧛 Vampire Lord: BAT SWARM TORNADO!")

	attack_started.emit("bat_tornado")
	bat_tornado_cooldown = BAT_TORNADO_CD

	play_dialogue_tornado()

	CameraShake.shake(12.0, 0.4)

	# Create tornado area
	var tornado = Area2D.new()
	tornado.name = "BatTornado"
	tornado.global_position = global_position

	# Visual (dark purple circle)
	var visual = ColorRect.new()
	visual.size = Vector2(200, 200)
	visual.position = -visual.size / 2
	visual.color = Color(0.2, 0.0, 0.3, 0.5)  # Dark purple
	tornado.add_child(visual)

	# Collision
	var shape = CircleShape2D.new()
	shape.radius = 100
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	tornado.add_child(collision_shape)

	get_tree().root.add_child(tornado)

	# Move tornado toward player while active
	move_tornado_toward_player(tornado)

	# Apply damage over time
	apply_tornado_damage(tornado)

	# Remove after duration
	await get_tree().create_timer(BAT_TORNADO_DURATION).timeout
	if is_instance_valid(tornado):
		tornado.queue_free()

func move_tornado_toward_player(tornado: Area2D):
	"""Move tornado toward player"""
	var duration = BAT_TORNADO_DURATION
	var elapsed = 0.0
	var speed = 100.0

	while elapsed < duration:
		await get_tree().process_frame

		if not is_instance_valid(tornado) or not is_instance_valid(player):
			break

		var delta = get_physics_process_delta_time()
		elapsed += delta

		var direction = (player.global_position - tornado.global_position).normalized()
		tornado.global_position += direction * speed * delta

func apply_tornado_damage(tornado: Area2D):
	"""Apply multi-hit damage from tornado"""
	var ticks = int(BAT_TORNADO_DURATION)

	for i in range(ticks):
		await get_tree().create_timer(1.0).timeout

		if not is_instance_valid(tornado):
			break

		var bodies = tornado.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(BAT_TORNADO_DAMAGE)
					print("🌪️ Tornado damage: %.1f" % BAT_TORNADO_DAMAGE)

				# Pull toward center
				var pull_dir = (tornado.global_position - body.global_position).normalized()
				if "velocity" in body:
					body.velocity += pull_dir * 150.0

func attack_echo_shriek():
	"""Phase 3: AOE shriek (must hide behind pillars)"""
	print("🧛 Vampire Lord: ECHO LOCATION SHRIEK!")

	attack_started.emit("echo_shriek")
	echo_shriek_cooldown = ECHO_SHRIEK_CD

	play_dialogue_shriek()

	# 3 second telegraph
	print("⚠️ WARNING: ECHO SHRIEK CHARGING!")

	if sprite:
		# Flash warning
		for i in range(6):
			sprite.modulate = Color.YELLOW
			await get_tree().create_timer(0.25).timeout
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.25).timeout
	else:
		await get_tree().create_timer(3.0).timeout

	print("🔊 ECHO SHRIEK RELEASED!")

	CameraShake.shake(20.0, 0.5)

	# Check if player is hiding (not implemented yet, just deal damage)
	# TODO: Add pillar cover mechanic
	if player.has_method("take_damage"):
		player.take_damage(ECHO_SHRIEK_DAMAGE)
		print("💥 Echo Shriek hit! Damage: %.1f" % ECHO_SHRIEK_DAMAGE)

func attack_bat_bomb():
	"""Phase 3: Shoot 5 homing bat projectiles"""
	print("🧛 Vampire Lord: BAT BOMB!")

	attack_started.emit("bat_bomb")
	bat_bomb_cooldown = BAT_BOMB_CD

	CameraShake.shake(8.0, 0.3)

	# Spawn 5 bat bombs
	for i in range(BAT_BOMB_COUNT):
		spawn_bat_bomb()
		await get_tree().create_timer(0.15).timeout

func spawn_bat_bomb():
	"""Spawn a single homing bat bomb"""
	var bat = Area2D.new()
	bat.name = "BatBomb"

	var visual = ColorRect.new()
	visual.size = Vector2(24, 24)
	visual.position = -visual.size / 2
	visual.color = Color(0.1, 0.0, 0.1)  # Dark bat
	bat.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	bat.add_child(collision_shape)

	bat.global_position = global_position

	# Initial direction toward player
	var direction = (player.global_position - global_position).normalized()
	bat.set_meta("direction", direction)
	bat.set_meta("speed", 300.0)
	bat.set_meta("damage", BAT_BOMB_DAMAGE)
	bat.set_meta("lifetime", 6.0)
	bat.set_meta("from_boss", true)
	bat.set_meta("homing", true)  # Weak homing

	bat.set_script(projectile_mover_script)
	get_tree().root.add_child(bat)

func attack_vampiric_regeneration():
	"""Phase 3: Channel to heal 1000 HP (interruptible)"""
	print("🧛 Vampire Lord: VAMPIRIC REGENERATION!")

	attack_started.emit("vampiric_regen")
	vampiric_regen_cooldown = VAMPIRIC_REGEN_CD
	vampiric_regen_uses -= 1
	is_channeling = true

	play_dialogue_regeneration()

	CameraShake.shake(10.0, 0.5)

	# Visual: Swirl effect
	if sprite:
		sprite.modulate = Color(1.0, 0.2, 0.2)  # Red glow

	var channel_time = VAMPIRIC_REGEN_DURATION
	var start_hp = current_hp

	# Channel for duration (can be interrupted by taking damage)
	var ticks = 10
	var heal_per_tick = VAMPIRIC_REGEN_HEAL / ticks

	for i in range(ticks):
		await get_tree().create_timer(channel_time / ticks).timeout

		# Check if interrupted (would need damage to set a flag)
		if not is_channeling:
			print("⚠️ Vampiric Regeneration interrupted!")
			break

		# Heal
		current_hp += heal_per_tick
		current_hp = min(current_hp, max_hp)
		print("💚 Regenerating: +%.1f HP (%.1f/%.1f)" % [heal_per_tick, current_hp, max_hp])

	is_channeling = false

	if sprite:
		sprite.modulate = Color.WHITE

	print("✓ Vampiric Regeneration complete! Total healed: %.1f" % (current_hp - start_hp))

# ========== BLOOD POOL HEALING ==========

func check_blood_pool_healing(delta: float):
	"""Check if boss is standing in blood pools to heal"""
	for pool in blood_pools:
		if not is_instance_valid(pool):
			continue

		var distance = global_position.distance_to(pool.global_position)
		if distance < 75.0:  # Radius of blood pool
			# Heal over time
			current_hp += 100.0 * delta
			current_hp = min(current_hp, max_hp)
			# Visual feedback would go here

# ========== DAMAGE & DEATH ==========

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	# Invulnerable during phase transition
	if current_state == State.PHASE_TRANSITION:
		return

	# Interrupt channeling if taking damage
	if is_channeling:
		is_channeling = false
		print("⚠️ Channeling interrupted by damage!")

	current_hp -= amount

	var hp_percent = (current_hp / max_hp) * 100.0
	print("🧛 Vampire Lord took %.1f damage! HP: %.1f/%.1f (%.1f%%)" % [amount, current_hp, max_hp, hp_percent])

	# Spawn damage number
	spawn_damage_number(amount, is_crit)

	# Visual feedback
	if sprite:
		var original_color = sprite.modulate
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite and is_instance_valid(self):
			sprite.modulate = original_color

	# Play damage dialogue
	play_dialogue_damage()

	# Check for phase transitions
	check_phase_transition()

	# Check death
	if current_hp <= 0:
		die()

func check_phase_transition():
	var hp_ratio = current_hp / max_hp

	# Phase 1 -> 2
	if current_phase == Phase.PHASE_1_ARISTOCRAT and hp_ratio <= PHASE_2_THRESHOLD and not phase_2_triggered:
		transition_to_phase_2()

	# Phase 2 -> 3
	elif current_phase == Phase.PHASE_2_BLOOD_MAGIC and hp_ratio <= PHASE_3_THRESHOLD and not phase_3_triggered:
		transition_to_phase_3()

func transition_to_phase_2():
	"""Transition to Phase 2: Blood Magic Awakened"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║  VAMPIRE LORD PHASE 2: BLOOD MAGIC  ║")
	print("╚══════════════════════════════════════╝")

	phase_2_triggered = true
	current_phase = Phase.PHASE_2_BLOOD_MAGIC
	current_state = State.PHASE_TRANSITION

	play_dialogue_phase_2()

	# Heal 10%
	var heal_amount = max_hp * 0.10
	current_hp = min(current_hp + heal_amount, max_hp)
	print("💚 Healed %.1f HP! Current: %.1f/%.1f" % [heal_amount, current_hp, max_hp])

	# Increase speed
	current_move_speed *= 1.2
	print("⚡ Speed increased to %.1f" % current_move_speed)

	# Visual: Redder, blood aura
	if sprite:
		sprite.modulate = Color(1.2, 0.5, 0.6)  # Reddish tint
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(5.0, 7.0), 0.5)
		tween.tween_property(sprite, "scale", Vector2(4.0, 6.0), 0.5)

	ParticleManager.create_phase_change_effect(global_position, 400.0)
	CameraShake.shake(25.0, 0.8)

	phase_changed.emit(2)

	# 2-second pause
	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(self):
		current_state = State.ATTACKING
		print("🧛 Phase 2 transition complete! Blood magic unlocked!")

	print("══════════════════════════════════════")
	print("")

func transition_to_phase_3():
	"""Transition to Phase 3: Bat Swarm Lord"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║  VAMPIRE LORD PHASE 3: BAT SWARM    ║")
	print("╚══════════════════════════════════════╝")

	phase_3_triggered = true
	current_phase = Phase.PHASE_3_BAT_SWARM
	current_state = State.PHASE_TRANSITION

	play_dialogue_phase_3()

	# Heal 10%
	var heal_amount = max_hp * 0.10
	current_hp = min(current_hp + heal_amount, max_hp)
	print("💚 Healed %.1f HP! Current: %.1f/%.1f" % [heal_amount, current_hp, max_hp])

	# Transform to bat form
	is_flying = true
	current_move_speed *= 1.4
	print("⚡⚡ Speed increased to %.1f (FLYING!)" % current_move_speed)

	# Visual: Darker, bat form
	if sprite:
		sprite.modulate = Color(0.2, 0.0, 0.2)  # Very dark purple
		sprite.scale = Vector2(5.0, 4.0)  # Wider (wings)
		sprite.color = Color(0.1, 0.0, 0.1)  # Almost black

	# Disable collision (flying)
	if collision:
		collision.disabled = true

	ParticleManager.create_phase_change_effect(global_position, 500.0)
	CameraShake.shake(30.0, 1.0)

	phase_changed.emit(3)

	# 3-second dramatic pause
	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(self):
		current_state = State.ATTACKING
		print("🧛 Phase 3 transition complete! BAT FORM ACTIVATED!")

	print("══════════════════════════════════════")
	print("")

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print("")
	print("╔══════════════════════════════════════╗")
	print("║   === VAMPIRE LORD DEFEATED ===     ║")
	print("║     After 847 years... destroyed     ║")
	print("╚══════════════════════════════════════╝")

	play_dialogue_death()

	# Massive death explosion
	ParticleManager.create_death_explosion(global_position, Color(0.8, 0.0, 0.2), 8.0)
	CameraShake.shake(40.0, 1.5)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
		print("⭐ Dropped %.1f XP!" % xp_reward)

	# Drop gold
	attempt_drop_items()

	# Drop legendary rewards
	drop_legendary_rewards()

	# Death animation (dissolve to ash)
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(0.5, 0.5), 2.0)  # Shrink
		tween.tween_property(sprite, "modulate:a", 0.0, 2.0)  # Fade
		tween.tween_callback(cleanup_and_destroy)
	else:
		cleanup_and_destroy()

	print("══════════════════════════════════════")
	print("")

func cleanup_and_destroy():
	# Clean up blood pools
	for pool in blood_pools:
		if is_instance_valid(pool):
			pool.queue_free()

	# Emit defeated signal
	boss_defeated.emit()

	# Remove from scene
	queue_free()

func attempt_drop_items():
	"""Drop gold"""
	var gold_amount = randi_range(gold_drop_min, gold_drop_max)
	spawn_gold(gold_amount)

func spawn_gold(amount: int):
	"""Spawn gold coins"""
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
		print("💰 Dropped %d gold!" % amount)

func drop_legendary_rewards():
	"""Drop Vampire Lord legendary items"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║     LEGENDARY REWARDS DROPPED!       ║")
	print("╚══════════════════════════════════════╝")
	print("👑 Crown of the Eternal Count")
	print("💎 Blood Gem x5")
	print("🎭 Crimson Cape (cosmetic)")
	print("══════════════════════════════════════")
	print("")

	# TODO: Implement actual item drops
	# For now just print

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		return

	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -50)

	get_tree().root.add_child(damage_num)

	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

# ========== COOLDOWN MANAGEMENT ==========

func update_cooldowns(delta: float):
	"""Update all attack cooldowns"""
	# Phase 1
	blood_slash_cooldown = max(0, blood_slash_cooldown - delta)
	crimson_lance_cooldown = max(0, crimson_lance_cooldown - delta)
	shadow_step_cooldown = max(0, shadow_step_cooldown - delta)
	thrall_summon_cooldown = max(0, thrall_summon_cooldown - delta)

	# Phase 2
	blood_pool_cooldown = max(0, blood_pool_cooldown - delta)
	sanguine_chains_cooldown = max(0, sanguine_chains_cooldown - delta)
	life_drain_cooldown = max(0, life_drain_cooldown - delta)

	# Phase 3
	dive_bomb_cooldown = max(0, dive_bomb_cooldown - delta)
	bat_tornado_cooldown = max(0, bat_tornado_cooldown - delta)
	echo_shriek_cooldown = max(0, echo_shriek_cooldown - delta)
	bat_bomb_cooldown = max(0, bat_bomb_cooldown - delta)
	vampiric_regen_cooldown = max(0, vampiric_regen_cooldown - delta)

# ========== UTILITY ==========

func update_sprite_direction():
	if not sprite or not player:
		return

	# Flip sprite to face player
	var direction_to_player = player.global_position.x - global_position.x

	if sprite is ColorRect:
		if direction_to_player > 0:
			sprite.scale.x = abs(sprite.scale.x)
		else:
			sprite.scale.x = -abs(sprite.scale.x)

# ========== DIALOGUE SYSTEM ==========

func play_dialogue_intro():
	var lines = [
		"Another mortal dares enter my domain?",
		"How amusing. I haven't fed in decades.",
		"Let me show you the power of eternity."
	]
	print("🧛 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_damage():
	var lines = [
		"Insolent whelp!",
		"You dare draw my blood?!",
		"Impressive... for a human.",
		"IMPOSSIBLE!"
	]
	if randf() < 0.3:  # 30% chance to speak
		print("🧛 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_phase_2():
	print("🧛 \"You... are stronger than I anticipated.\"")
	print("🧛 \"Very well. I shall show you TRUE power!\"")
	print("🧛 \"Witness centuries of dark magic!\"")

func play_dialogue_phase_3():
	print("🧛 \"No... NO! This cannot be!\"")
	print("🧛 \"I am ETERNAL! I am IMMORTAL!\"")
	print("🧛 \"If I cannot defeat you in this form...\"")
	print("🧛 \"I SHALL OVERWHELM YOU WITH NUMBERS!\"")
	print("🧛 \"MY FINAL FORM!\"")

func play_dialogue_death():
	print("🧛 \"Impossible... after 847 years...\"")
	print("🧛 \"I... I was supposed to be... eternal...\"")
	print("🧛 \"Remember my name... Lord Crimson... Nightshade...\"")
	print("🧛 [Dissolves into ash, crown falls to ground]")

func play_dialogue_teleport():
	if randf() < 0.5:
		print("🧛 \"Too slow!\"")

func play_dialogue_summon():
	var lines = [
		"Come forth, my servants!",
		"Arise, children of the night!",
		"Feast upon this mortal!"
	]
	print("🧛 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_blood_pool():
	print("🧛 \"Drown in crimson!\"")

func play_dialogue_chains():
	print("🧛 \"COME TO ME!\"")

func play_dialogue_life_drain():
	print("🧛 \"Let me TASTE you!\"")

func play_dialogue_tornado():
	print("🧛 \"DROWN IN THE SWARM!\"")

func play_dialogue_shriek():
	print("🧛 \"HEAR MY SONG!\"")

func play_dialogue_regeneration():
	var lines = [
		"I AM ETERNAL!",
		"Death cannot claim me!",
		"Foolish to think you could kill me!"
	]
	print("🧛 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_berserk():
	print("🧛 \"IF I FALL, I TAKE YOU WITH ME!\"")
	print("🧛 \"CURSE YOU, MORTAL!\"")
