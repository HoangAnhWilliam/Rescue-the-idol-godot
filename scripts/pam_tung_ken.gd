extends CharacterBody2D
class_name PamTungKen

# ========== PAM TUNG KEN ==========
# "The Obsessed Otaku", "Miku's Self-Proclaimed Husband"
# Age: 25
# Professional NEET, Miku Superfan
# 347 Nendoroid collection

# ========== ENCOUNTER SYSTEM ==========

enum Encounter { BLOOD_TEMPLE, KIDNAPPING, FORTRESS }
@export var encounter_type: Encounter = Encounter.FORTRESS

# HP varies by encounter
const HP_BLOOD_TEMPLE: float = 15000.0  # Tutorial boss
const HP_FORTRESS: float = 50000.0       # Main boss fight

# ========== BOSS STATS ==========

var max_hp: float
@export var base_damage: float = 10.0
@export var base_move_speed: float = 140.0
var xp_reward: float = 30000.0
var detection_range: float = 500.0
var gold_drop_min: int = 60000
var gold_drop_max: int = 90000

# Current stats
var current_hp: float
var current_damage: float
var current_move_speed: float

# ========== PHASE SYSTEM (Fortress only) ==========

enum Phase { PHASE_1_OTAKU, PHASE_2_YANDERE, PHASE_3_ULTRA_INSTINCT }
var current_phase: Phase = Phase.PHASE_1_OTAKU

# Phase HP thresholds
const PHASE_2_THRESHOLD: float = 0.66  # 66% HP
const PHASE_3_THRESHOLD: float = 0.33  # 33% HP

# Phase flags
var phase_2_triggered: bool = false
var phase_3_triggered: bool = false

# ========== STATE MACHINE ==========

enum State { IDLE, CHASE, ATTACKING, CHANNELING, TELEPORTING, PHASE_TRANSITION, RETREATING, DEAD }
var current_state: State = State.IDLE

# ========== ATTACK COOLDOWNS ==========

# Phase 1 abilities (all encounters)
var glow_stick_cooldown: float = 0.0
const GLOW_STICK_CD: float = 2.0
const GLOW_STICK_DAMAGE: float = 10.0
const GLOW_STICK_RANGE: float = 3.0

var nendoroid_throw_cooldown: float = 0.0
const NENDOROID_THROW_CD: float = 5.0
const NENDOROID_THROW_DAMAGE: float = 15.0

var naruto_run_cooldown: float = 0.0
const NARUTO_RUN_CD: float = 8.0
const NARUTO_RUN_DAMAGE: float = 20.0
const NARUTO_RUN_DISTANCE: float = 8.0

var waifu_shield_cooldown: float = 0.0
const WAIFU_SHIELD_CD: float = 20.0
const WAIFU_SHIELD_DURATION: float = 5.0
const WAIFU_SHIELD_HEAL: float = 500.0

var keyboard_warrior_cooldown: float = 0.0
const KEYBOARD_WARRIOR_CD: float = 12.0
const KEYBOARD_WARRIOR_DAMAGE: float = 5.0
const KEYBOARD_WARRIOR_COUNT: int = 10

# Fortress Phase 1
var glow_stick_barrage_cooldown: float = 0.0
const GLOW_STICK_BARRAGE_CD: float = 5.0
const GLOW_STICK_BARRAGE_COUNT: int = 10

var nendoroid_army_cooldown: float = 0.0
const NENDOROID_ARMY_CD: float = 25.0

# Phase 2 abilities (Yandere Mode)
var katana_strike_cooldown: float = 0.0
const KATANA_STRIKE_CD: float = 6.0
const KATANA_STRIKE_DAMAGE: float = 35.0

var kamehameha_cooldown: float = 0.0
const KAMEHAMEHA_CD: float = 20.0
const KAMEHAMEHA_DAMAGE: float = 60.0
const KAMEHAMEHA_CHARGE_TIME: float = 3.0

var miku_clone_cooldown: float = 0.0
const MIKU_CLONE_CD: float = 30.0

var body_pillow_fortress_cooldown: float = 0.0
const BODY_PILLOW_FORTRESS_CD: float = 25.0
const BODY_PILLOW_FORTRESS_DURATION: float = 10.0

var teleport_combo_cooldown: float = 0.0
const TELEPORT_COMBO_CD: float = 18.0
const TELEPORT_COMBO_DAMAGE: float = 25.0

# Phase 3 abilities (Ultra Instinct)
var simp_energy_blast_cooldown: float = 0.0
const SIMP_ENERGY_BLAST_CD: float = 40.0
const SIMP_ENERGY_BLAST_DAMAGE: float = 100.0
const SIMP_ENERGY_BLAST_CHARGE: float = 5.0

var desperate_teleport_spam_cooldown: float = 0.0
const DESPERATE_TELEPORT_SPAM_CD: float = 30.0
const DESPERATE_TELEPORT_SPAM_DURATION: float = 15.0

# Special state flags
var is_invincible: bool = false  # Waifu Shield
var is_channeling: bool = false
var is_teleporting: bool = false
var is_flying: bool = false
var ultra_instinct_active: bool = false
var berserk_mode: bool = false  # Below 10%
var cage_destruction_attempted: bool = false

# Cringe Aura (Phase 2+)
var cringe_aura_active: bool = false
const CRINGE_AURA_DAMAGE: float = 5.0  # Per second
const CRINGE_AURA_RADIUS: float = 8.0

# Pillow fortress (Phase 2)
var pillow_fortress_active: bool = false

# ========== REFERENCES ==========

@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null

var player: CharacterBody2D = null
var miku: Node = null  # Miku companion reference

# Preload effects
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")

# Preload projectile mover
var projectile_mover_script = preload("res://scripts/projectile_mover.gd")

# Preload minions (loaded in _ready)
var nendoroid_minion_scene: Resource = null
var miku_clone_scene: Resource = null

# ========== SIGNALS ==========

signal boss_defeated
signal phase_changed(phase: int)
signal attack_started(attack_type: String)
signal pam_retreated
signal miku_kidnapped

# ========== INITIALIZATION ==========

func _ready():
	print("")
	print("╔══════════════════════════════════════╗")
	print("║    PAM TUNG KEN INITIALIZED         ║")
	print("║   The Obsessed Otaku                 ║")
	print("║   347 Nendoroid Collection           ║")
	print("╚══════════════════════════════════════╝")

	# Set HP based on encounter
	match encounter_type:
		Encounter.BLOOD_TEMPLE:
			max_hp = HP_BLOOD_TEMPLE
			xp_reward = 5000.0
			gold_drop_min = 10000
			gold_drop_max = 20000
			print("Encounter: BLOOD_TEMPLE (Tutorial)")

		Encounter.FORTRESS:
			max_hp = HP_FORTRESS
			xp_reward = 30000.0
			gold_drop_min = 60000
			gold_drop_max = 90000
			print("Encounter: FORTRESS (Main Boss)")

	# Initialize stats
	current_hp = max_hp
	current_damage = base_damage
	current_move_speed = base_move_speed

	print("Pam HP: ", max_hp)
	print("Pam Damage: ", base_damage)
	print("Pam Speed: ", base_move_speed)

	# Add to groups
	add_to_group("bosses")
	add_to_group("enemies")
	add_to_group("pam_tung_ken")

	# Scale and color (otaku nerd)
	if sprite:
		sprite.scale = Vector2(2.5, 3.5)  # Shorter, wider (nerd physique)
		sprite.color = Color(0.2, 0.8, 0.8)  # Teal (Miku hoodie)
		print("✓ Pam scale set to 2.5 x 3.5")
		print("✓ Pam color set to teal (Miku hoodie)")

	# Load minion scenes
	# nendoroid_minion_scene = load("res://scenes/enemies/nendoroid_minion.tscn")
	# miku_clone_scene = load("res://scenes/enemies/fake_miku.tscn")

	print("Pam Tung Ken ready!")
	print("══════════════════════════════════════")
	print("")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update cooldown timers
	update_cooldowns(delta)

	# Cringe Aura damage (Phase 2+)
	if cringe_aura_active:
		apply_cringe_aura_damage(delta)

	# State machine
	match current_state:
		State.IDLE:
			search_for_player()

		State.CHASE:
			chase_player(delta)

		State.ATTACKING:
			perform_attacks(delta)

		State.CHANNELING:
			# Handled by specific attacks
			pass

		State.TELEPORTING:
			# Handled by animation
			pass

		State.PHASE_TRANSITION:
			# Handled by tween
			pass

		State.RETREATING:
			# Handled by retreat function
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
		print("🎮 Pam Tung Ken engaged!")

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
	move_and_slide()

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

	# Attack based on encounter type
	if encounter_type == Encounter.BLOOD_TEMPLE:
		blood_temple_ai(distance, delta)
	else:  # Fortress
		fortress_ai(distance, delta)

# ========== BLOOD TEMPLE AI (Encounter 1) ==========

func blood_temple_ai(distance: float, delta: float):
	"""Blood Temple: Simple tutorial boss fight"""

	# Retreat at 20% HP
	if current_hp < max_hp * 0.2:
		retreat_from_battle()
		return

	# 1. Naruto Run (gap closer)
	if distance > 10.0 and naruto_run_cooldown <= 0:
		attack_naruto_run()
		return

	# 2. Waifu Shield (when HP below 50%)
	if current_hp < max_hp * 0.5 and waifu_shield_cooldown <= 0:
		attack_waifu_shield()
		return

	# 3. Keyboard Warrior (spam attack)
	if keyboard_warrior_cooldown <= 0:
		attack_keyboard_warrior()
		return

	# 4. Nendoroid Throw
	if nendoroid_throw_cooldown <= 0:
		attack_nendoroid_throw()
		return

	# 5. Glow Stick (melee)
	if distance < GLOW_STICK_RANGE and glow_stick_cooldown <= 0:
		attack_glow_stick()
		return

	# Move toward player if no attacks available
	if distance > GLOW_STICK_RANGE:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

# ========== FORTRESS AI (Encounter 3) ==========

func fortress_ai(distance: float, delta: float):
	"""Fortress: Complex 3-phase boss fight"""

	# Check for critical mechanics
	check_fortress_special_mechanics()

	# Attack based on phase
	match current_phase:
		Phase.PHASE_1_OTAKU:
			fortress_phase_1_ai(distance, delta)

		Phase.PHASE_2_YANDERE:
			fortress_phase_2_ai(distance, delta)

		Phase.PHASE_3_ULTRA_INSTINCT:
			fortress_phase_3_ai(distance, delta)

func check_fortress_special_mechanics():
	"""Check for special triggered events in Fortress"""

	# Cage Destruction attempt at 5% HP (ONCE)
	if current_hp < max_hp * 0.05 and not cage_destruction_attempted:
		attempt_cage_destruction()

	# Berserk mode at 10%
	if current_hp < max_hp * 0.10 and not berserk_mode:
		activate_berserk_mode()

func fortress_phase_1_ai(distance: float, delta: float):
	"""Phase 1: True Otaku Power"""

	# 1. Nendoroid Army (summon minions)
	if nendoroid_army_cooldown <= 0:
		summon_nendoroid_army()
		return

	# 2. Glow Stick Barrage (enhanced)
	if glow_stick_barrage_cooldown <= 0:
		attack_glow_stick_barrage()
		return

	# 3. Naruto Run Combo
	if distance > 8.0 and naruto_run_cooldown <= 0:
		attack_naruto_run_combo()
		return

	# 4. Waifu Shield (defensive)
	if current_hp < max_hp * 0.7 and waifu_shield_cooldown <= 0:
		attack_waifu_shield_enhanced()
		return

	# 5. Keyboard Spam
	if keyboard_warrior_cooldown <= 0:
		attack_keyboard_spam()
		return

	# 6. Nendoroid Throw
	if nendoroid_throw_cooldown <= 0:
		attack_nendoroid_throw()
		return

	# 7. Glow Stick (basic melee)
	if distance < GLOW_STICK_RANGE and glow_stick_cooldown <= 0:
		attack_glow_stick()
		return

	# Move around
	if distance > 6.0:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func fortress_phase_2_ai(distance: float, delta: float):
	"""Phase 2: Yandere Mode"""

	# 1. Kamehameha (big damage)
	if kamehameha_cooldown <= 0:
		attack_kamehameha()
		return

	# 2. Miku Clone Jutsu
	if miku_clone_cooldown <= 0:
		summon_miku_clones()
		return

	# 3. Body Pillow Fortress (defense)
	if current_hp < max_hp * 0.5 and body_pillow_fortress_cooldown <= 0:
		activate_body_pillow_fortress()
		return

	# 4. True Katana Strike
	if distance < 5.0 and katana_strike_cooldown <= 0:
		attack_true_katana()
		return

	# 5. Teleport Combo
	if teleport_combo_cooldown <= 0:
		attack_teleport_combo()
		return

	# 6. Glow Stick Barrage
	if glow_stick_barrage_cooldown <= 0:
		attack_glow_stick_barrage()
		return

	# Move aggressively
	if distance > 5.0:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * current_move_speed * 1.2  # 20% faster
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func fortress_phase_3_ai(distance: float, delta: float):
	"""Phase 3: Ultra Instinct Otaku"""

	# 1. 1000 Year Simp Energy Blast (ultimate)
	if simp_energy_blast_cooldown <= 0:
		attack_simp_energy_blast()
		return

	# 2. Desperate Teleport Spam
	if desperate_teleport_spam_cooldown <= 0:
		attack_desperate_teleport_spam()
		return

	# 3. Kamehameha (faster cooldown)
	if kamehameha_cooldown <= 0:
		attack_kamehameha()
		return

	# 4. All Phase 2 attacks but faster
	if katana_strike_cooldown <= 0:
		attack_true_katana()
		return

	if glow_stick_barrage_cooldown <= 0:
		attack_glow_stick_barrage()
		return

	# Erratic movement (teleport frequently in berserk)
	if berserk_mode:
		# Spam everything
		pass
	else:
		# Normal movement
		if distance > 4.0:
			var direction = (player.global_position - global_position).normalized()
			velocity = direction * current_move_speed * 2.0  # Double speed!
			move_and_slide()
		else:
			velocity = Vector2.ZERO

func activate_berserk_mode():
	"""Activate final desperation at 10% HP"""
	berserk_mode = true

	print("🎮🎮🎮 PAM BERSERK MODE ACTIVATED! 🎮🎮🎮")
	play_dialogue_berserk()

	# Massive attack speed increase (cut all cooldowns in half)
	current_move_speed *= 1.5

	# Visual: Even more intense
	if sprite:
		sprite.modulate = Color(2.0, 0.0, 0.0)  # Bright red (rage)

func attempt_cage_destruction():
	"""CRITICAL: Pam tries to destroy Miku's cage at 5% HP"""
	cage_destruction_attempted = true
	is_channeling = true
	current_state = State.CHANNELING

	print("")
	print("╔══════════════════════════════════════╗")
	print("║   ⚠️ CAGE DESTRUCTION ATTEMPT ⚠️    ║")
	print("║   INTERRUPT OR GAME OVER!            ║")
	print("╚══════════════════════════════════════╝")

	play_dialogue_cage_destruction()

	CameraShake.shake(15.0, 1.0)

	# Rush to cage (center of room)
	# TODO: Get actual cage position
	var cage_pos = Vector2(0, 0)  # Placeholder
	var direction = (cage_pos - global_position).normalized()

	# Channel for 8 seconds
	# If player doesn't interrupt: GAME OVER

	var channel_time = 8.0
	var elapsed = 0.0

	while elapsed < channel_time:
		var delta = get_physics_process_delta_time()
		elapsed += delta

		# Check if interrupted (damage sets is_channeling = false)
		if not is_channeling:
			print("✓ Cage destruction INTERRUPTED by player!")
			print("✓ Miku is safe!")
			return

		# Visual warning
		if int(elapsed) != int(elapsed - delta):
			print("⚠️ CAGE DESTRUCTION IN %.0f SECONDS!" % (channel_time - elapsed))

		await get_tree().process_frame

	# If we reach here, player failed to interrupt
	print("")
	print("╔══════════════════════════════════════╗")
	print("║        ❌ GAME OVER ❌               ║")
	print("║   Pam destroyed Miku's cage!         ║")
	print("║   Miku is lost forever...            ║")
	print("╚══════════════════════════════════════╝")

	# TODO: Trigger game over
	# For now, just cancel
	is_channeling = false

# ========== ATTACK IMPLEMENTATIONS ==========

func attack_glow_stick():
	"""Basic melee attack with rainbow glow sticks"""
	print("🎮 Pam: GLOW STICK SLASH!")

	attack_started.emit("glow_stick")
	glow_stick_cooldown = GLOW_STICK_CD

	CameraShake.shake(3.0, 0.1)

	# Check if player in range
	var distance = global_position.distance_to(player.global_position)
	if distance < GLOW_STICK_RANGE:
		if player.has_method("take_damage"):
			player.take_damage(GLOW_STICK_DAMAGE)
			print("💥 Glow Stick hit! Damage: %.1f" % GLOW_STICK_DAMAGE)

func attack_glow_stick_barrage():
	"""Fortress: Throw 10 glow sticks in arc"""
	print("🎮 Pam: GLOW STICK BARRAGE!")

	attack_started.emit("glow_stick_barrage")
	glow_stick_barrage_cooldown = GLOW_STICK_BARRAGE_CD

	CameraShake.shake(6.0, 0.25)

	# Shoot 10 glow sticks in spread
	for i in range(GLOW_STICK_BARRAGE_COUNT):
		var angle = (TAU / GLOW_STICK_BARRAGE_COUNT) * i
		var direction = Vector2(cos(angle), sin(angle))

		spawn_glow_stick_projectile(direction)

		await get_tree().create_timer(0.05).timeout

func spawn_glow_stick_projectile(direction: Vector2):
	"""Spawn a single glow stick projectile"""
	var stick = Area2D.new()
	stick.name = "GlowStick"

	var visual = ColorRect.new()
	visual.size = Vector2(20, 6)
	visual.position = -visual.size / 2
	# Rainbow colors
	var colors = [Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN, Color.CYAN, Color.BLUE, Color.MAGENTA]
	visual.color = colors[randi() % colors.size()]
	stick.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	stick.add_child(collision_shape)

	stick.global_position = global_position

	stick.set_meta("direction", direction)
	stick.set_meta("speed", 350.0)
	stick.set_meta("damage", 15.0)
	stick.set_meta("lifetime", 4.0)
	stick.set_meta("from_boss", true)

	stick.set_script(projectile_mover_script)
	get_tree().root.add_child(stick)

func attack_nendoroid_throw():
	"""Throw a Nendoroid box projectile"""
	print("🎮 Pam: NENDOROID THROW!")

	attack_started.emit("nendoroid_throw")
	nendoroid_throw_cooldown = NENDOROID_THROW_CD

	play_dialogue_nendoroid()

	CameraShake.shake(4.0, 0.15)

	# Spawn projectile
	var box = Area2D.new()
	box.name = "NendoroidBox"

	var visual = ColorRect.new()
	visual.size = Vector2(32, 32)
	visual.position = -visual.size / 2
	visual.color = Color(0.9, 0.9, 1.0)  # White box
	box.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	box.add_child(collision_shape)

	box.global_position = global_position

	var direction = (player.global_position - global_position).normalized()
	box.set_meta("direction", direction)
	box.set_meta("speed", 300.0)
	box.set_meta("damage", NENDOROID_THROW_DAMAGE)
	box.set_meta("lifetime", 5.0)
	box.set_meta("from_boss", true)
	box.set_meta("explodes", true)  # Explodes on impact

	box.set_script(projectile_mover_script)
	get_tree().root.add_child(box)

func attack_naruto_run():
	"""Dash toward player with arms behind back"""
	print("🎮 Pam: NARUTO RUN JUTSU!")

	attack_started.emit("naruto_run")
	naruto_run_cooldown = NARUTO_RUN_CD

	play_dialogue_naruto_run()

	CameraShake.shake(5.0, 0.2)

	# Fast dash toward player
	var direction = (player.global_position - global_position).normalized()
	var dash_speed = 500.0
	var dash_distance = NARUTO_RUN_DISTANCE

	var start_pos = global_position
	var target_pos = start_pos + direction * dash_distance

	var tween = create_tween()
	tween.tween_property(self, "global_position", target_pos, 0.3)

	await tween.finished

	# Check if hit player
	var distance = global_position.distance_to(player.global_position)
	if distance < 3.0:
		if player.has_method("take_damage"):
			player.take_damage(NARUTO_RUN_DAMAGE)
			print("💥 Naruto Run hit! Damage: %.1f" % NARUTO_RUN_DAMAGE)

func attack_naruto_run_combo():
	"""Fortress: Enhanced Naruto Run with 5-hit combo"""
	print("🎮 Pam: NARUTO RUN COMBO!")

	attack_started.emit("naruto_run_combo")
	naruto_run_cooldown = NARUTO_RUN_CD

	play_dialogue_naruto_run()

	CameraShake.shake(7.0, 0.4)

	# Dash + 5 hit combo
	await attack_naruto_run()

	# 5 rapid hits
	for i in range(5):
		await get_tree().create_timer(0.2).timeout

		var distance = global_position.distance_to(player.global_position)
		if distance < 4.0:
			if player.has_method("take_damage"):
				player.take_damage(5.0)
				print("💥 Combo hit %d! Damage: 5" % (i + 1))

func attack_waifu_shield():
	"""Summon Miku hologram for invincibility"""
	print("🎮 Pam: WAIFU SHIELD!")

	attack_started.emit("waifu_shield")
	waifu_shield_cooldown = WAIFU_SHIELD_CD
	is_invincible = true

	play_dialogue_waifu_shield()

	CameraShake.shake(5.0, 0.3)

	# Visual: Miku hologram
	if sprite:
		sprite.modulate = Color(0.0, 1.0, 1.0)  # Cyan glow

	# Heal
	current_hp += WAIFU_SHIELD_HEAL
	current_hp = min(current_hp, max_hp)
	print("💚 Healed %.1f HP! (%.1f/%.1f)" % [WAIFU_SHIELD_HEAL, current_hp, max_hp])

	# Duration
	await get_tree().create_timer(WAIFU_SHIELD_DURATION).timeout

	is_invincible = false

	if sprite:
		sprite.modulate = Color.WHITE

	print("✓ Waifu Shield expired")

func attack_waifu_shield_enhanced():
	"""Fortress: Enhanced shield with 8s duration, 1000 heal"""
	print("🎮 Pam: WAIFU PROTECTION MAXIMUM!")

	attack_started.emit("waifu_shield_enhanced")
	waifu_shield_cooldown = WAIFU_SHIELD_CD
	is_invincible = true

	play_dialogue_waifu_shield()

	CameraShake.shake(7.0, 0.5)

	# Visual: Miku hologram orbiting
	if sprite:
		sprite.modulate = Color(0.0, 1.5, 1.5)  # Brighter cyan

	# Heal MORE
	current_hp += 1000.0
	current_hp = min(current_hp, max_hp)
	print("💚 Healed 1000 HP! (%.1f/%.1f)" % [current_hp, max_hp])

	# Longer duration
	await get_tree().create_timer(8.0).timeout

	is_invincible = false

	if sprite:
		sprite.modulate = Color.WHITE

	print("✓ Enhanced Waifu Shield expired")

func attack_keyboard_warrior():
	"""Spam 10 text bubbles"""
	print("🎮 Pam: KEYBOARD WARRIOR!")

	attack_started.emit("keyboard_warrior")
	keyboard_warrior_cooldown = KEYBOARD_WARRIOR_CD

	play_dialogue_keyboard()

	CameraShake.shake(4.0, 0.3)

	# Spawn 10 text bubbles
	for i in range(KEYBOARD_WARRIOR_COUNT):
		spawn_text_bubble()
		await get_tree().create_timer(0.1).timeout

func attack_keyboard_spam():
	"""Fortress: Spam 20 text bubbles (enhanced)"""
	print("🎮 Pam: KEYBOARD SPAM MAXIMUM!")

	attack_started.emit("keyboard_spam")
	keyboard_warrior_cooldown = KEYBOARD_WARRIOR_CD - 3.0  # Faster cooldown

	play_dialogue_keyboard()

	CameraShake.shake(6.0, 0.4)

	# Spawn 20 text bubbles
	for i in range(20):
		spawn_text_bubble()
		await get_tree().create_timer(0.05).timeout

func spawn_text_bubble():
	"""Spawn a text bubble projectile"""
	var bubble = Area2D.new()
	bubble.name = "TextBubble"

	var visual = ColorRect.new()
	visual.size = Vector2(40, 24)
	visual.position = -visual.size / 2
	visual.color = Color(1.0, 1.0, 1.0)  # White bubble
	bubble.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	bubble.add_child(collision_shape)

	bubble.global_position = global_position

	# Shoot toward player with spread
	var base_dir = (player.global_position - global_position).normalized()
	var spread = randf_range(-0.3, 0.3)
	var direction = base_dir.rotated(spread)

	bubble.set_meta("direction", direction)
	bubble.set_meta("speed", 250.0)
	bubble.set_meta("damage", KEYBOARD_WARRIOR_DAMAGE)
	bubble.set_meta("lifetime", 6.0)
	bubble.set_meta("from_boss", true)

	bubble.set_script(projectile_mover_script)
	get_tree().root.add_child(bubble)

func summon_nendoroid_army():
	"""Fortress Phase 1: Summon 5 Nendoroid minions"""
	print("🎮 Pam: MY NENDOROIDS WILL DESTROY YOU!")

	attack_started.emit("nendoroid_army")
	nendoroid_army_cooldown = NENDOROID_ARMY_CD

	play_dialogue_nendoroid()

	CameraShake.shake(8.0, 0.4)

	# Spawn 5 Nendoroid minions in circle
	# TODO: Create actual Nendoroid minion enemy
	# For now just print
	print("✓ Summoned 5 Nendoroid minions (not implemented yet)")

func attack_true_katana():
	"""Phase 2: Overhead katana slash"""
	print("🎮 Pam: MY KATANA IS FOLDED 1000 TIMES!")

	attack_started.emit("katana_strike")
	katana_strike_cooldown = KATANA_STRIKE_CD

	play_dialogue_katana()

	CameraShake.shake(8.0, 0.25)

	# Check if player in range
	var distance = global_position.distance_to(player.global_position)
	if distance < 5.0:
		if player.has_method("take_damage"):
			player.take_damage(KATANA_STRIKE_DAMAGE)
			print("💥 Katana Strike hit! Damage: %.1f" % KATANA_STRIKE_DAMAGE)

func attack_kamehameha():
	"""Phase 2+: Charge and fire massive beam"""
	print("🎮 Pam: KA-ME-HA-ME-HAAA!")

	attack_started.emit("kamehameha")
	kamehameha_cooldown = KAMEHAMEHA_CD
	is_channeling = true

	play_dialogue_kamehameha()

	# 3 second charge
	print("⚡ Kamehameha charging...")

	if sprite:
		# Charge visual
		for i in range(6):
			sprite.modulate = Color.CYAN
			await get_tree().create_timer(0.25).timeout
			sprite.modulate = Color.WHITE
			await get_tree().create_timer(0.25).timeout
	else:
		await get_tree().create_timer(KAMEHAMEHA_CHARGE_TIME).timeout

	is_channeling = false

	print("⚡⚡⚡ KAMEHAMEHA FIRED!")

	CameraShake.shake(15.0, 0.5)

	# Spawn beam
	var beam = Area2D.new()
	beam.name = "Kamehameha"

	var visual = ColorRect.new()
	visual.size = Vector2(600, 100)  # Long beam
	visual.position = Vector2(0, -visual.size.y / 2)  # Extend forward
	visual.color = Color(0.0, 0.8, 1.0, 0.7)  # Blue beam
	beam.add_child(visual)

	var shape = RectangleShape2D.new()
	shape.size = visual.size
	var collision_shape = CollisionShape2D.new()
	collision_shape.position = visual.position + visual.size / 2
	collision_shape.shape = shape
	beam.add_child(collision_shape)

	beam.global_position = global_position

	# Face player
	var direction = (player.global_position - global_position).normalized()
	beam.rotation = direction.angle()

	get_tree().root.add_child(beam)

	# Check if player hit
	await get_tree().create_timer(0.1).timeout

	var bodies = beam.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(KAMEHAMEHA_DAMAGE)
				print("💥💥 KAMEHAMEHA HIT! Damage: %.1f" % KAMEHAMEHA_DAMAGE)

	# Remove beam
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(beam):
		beam.queue_free()

func summon_miku_clones():
	"""Phase 2: Summon 3 Fake Miku clones"""
	print("🎮 Pam: SHADOW CLONE JUTSU!")

	attack_started.emit("miku_clones")
	miku_clone_cooldown = MIKU_CLONE_CD

	play_dialogue_miku_clones()

	CameraShake.shake(10.0, 0.4)

	# Spawn 3 Fake Mikus
	# TODO: Create actual Fake Miku enemy
	print("✓ Summoned 3 Miku clones (not implemented yet)")

func activate_body_pillow_fortress():
	"""Phase 2: 50% damage reduction for 10 seconds"""
	print("🎮 Pam: PILLOW FORTRESS!")

	attack_started.emit("pillow_fortress")
	body_pillow_fortress_cooldown = BODY_PILLOW_FORTRESS_CD
	pillow_fortress_active = true

	play_dialogue_pillow_fortress()

	CameraShake.shake(6.0, 0.3)

	# Visual
	if sprite:
		sprite.modulate = Color(1.5, 1.5, 1.5)  # Brighter (pillow walls)

	# Duration
	await get_tree().create_timer(BODY_PILLOW_FORTRESS_DURATION).timeout

	pillow_fortress_active = false

	if sprite:
		sprite.modulate = Color.WHITE

	print("✓ Pillow Fortress expired")

func attack_teleport_combo():
	"""Phase 2: Teleport 3 times, attack from different angles"""
	print("🎮 Pam: TELEPORT COMBO!")

	attack_started.emit("teleport_combo")
	teleport_combo_cooldown = TELEPORT_COMBO_CD
	is_teleporting = true

	CameraShake.shake(10.0, 0.6)

	# 3 rapid teleports
	for i in range(3):
		# Fade out
		if sprite:
			sprite.modulate.a = 0.0

		await get_tree().create_timer(0.2).timeout

		# Teleport to random angle around player
		var angle = randf() * TAU
		var distance = 6.0
		var offset = Vector2(cos(angle), sin(angle)) * distance
		global_position = player.global_position + offset

		# Fade in
		if sprite:
			sprite.modulate.a = 1.0

		await get_tree().create_timer(0.1).timeout

		# Attack
		if player.has_method("take_damage"):
			player.take_damage(TELEPORT_COMBO_DAMAGE)
			print("💥 Teleport attack %d! Damage: %.1f" % [i + 1, TELEPORT_COMBO_DAMAGE])

		await get_tree().create_timer(0.3).timeout

	is_teleporting = false

func attack_simp_energy_blast():
	"""Phase 3: Ultimate 1000 Year Simp Energy attack"""
	print("🎮 Pam: 1000 YEARS OF DEDICATION!")

	attack_started.emit("simp_energy")
	simp_energy_blast_cooldown = SIMP_ENERGY_BLAST_CD
	is_channeling = true

	play_dialogue_simp_energy()

	# 5 second charge
	print("⚠️⚠️ SIMP ENERGY CHARGING! HIDE BEHIND COVER!")

	CameraShake.shake(20.0, 5.0)

	# Visual: Arena turns red
	if sprite:
		sprite.modulate = Color(3.0, 0.0, 0.0)  # Bright red

	# Charge for 5 seconds
	await get_tree().create_timer(SIMP_ENERGY_BLAST_CHARGE).timeout

	is_channeling = false

	print("💥💥💥 1000 YEAR SIMP ENERGY BLAST!!!")

	CameraShake.shake(30.0, 1.0)

	# AOE explosion (entire arena)
	# TODO: Check if player behind cover
	# For now just deal massive damage
	if player.has_method("take_damage"):
		player.take_damage(SIMP_ENERGY_BLAST_DAMAGE)
		print("💥💥💥 SIMP ENERGY HIT! Damage: %.1f" % SIMP_ENERGY_BLAST_DAMAGE)

	if sprite:
		sprite.modulate = Color.WHITE

func attack_desperate_teleport_spam():
	"""Phase 3: Teleport every 2 seconds for 15 seconds"""
	print("🎮 Pam: DESPERATE TELEPORT SPAM!")

	attack_started.emit("teleport_spam")
	desperate_teleport_spam_cooldown = DESPERATE_TELEPORT_SPAM_CD
	is_teleporting = true

	CameraShake.shake(15.0, 0.8)

	var elapsed = 0.0
	var teleport_interval = 2.0

	while elapsed < DESPERATE_TELEPORT_SPAM_DURATION:
		# Teleport
		if sprite:
			sprite.modulate.a = 0.0

		await get_tree().create_timer(0.1).timeout

		# Random position near player
		var angle = randf() * TAU
		var distance = randf_range(4.0, 8.0)
		var offset = Vector2(cos(angle), sin(angle)) * distance
		global_position = player.global_position + offset

		if sprite:
			sprite.modulate.a = 1.0

		# Attack
		if player.has_method("take_damage"):
			player.take_damage(20.0)
			print("💥 Teleport spam attack! Damage: 20")

		await get_tree().create_timer(teleport_interval).timeout
		elapsed += teleport_interval

	is_teleporting = false
	print("✓ Teleport spam complete")

func apply_cringe_aura_damage(delta: float):
	"""Phase 2+: Passive damage aura"""
	if not player or not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < CRINGE_AURA_RADIUS:
		if player.has_method("take_damage"):
			player.take_damage(CRINGE_AURA_DAMAGE * delta)

		# Slow player
		if "velocity" in player:
			player.velocity *= 0.7

func retreat_from_battle():
	"""Blood Temple only: Retreat at 20% HP"""
	print("🎮 Pam: I'll let you have this round!")

	current_state = State.RETREATING

	play_dialogue_retreat()

	# Teleport away animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		await tween.finished

	# Emit retreat signal
	pam_retreated.emit()

	# Remove
	queue_free()

# ========== DAMAGE & DEATH ==========

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	# Invulnerable checks
	if is_invincible:
		print("🛡️ Waifu Shield blocked damage!")
		return

	# Phase 3: Ultra Instinct dodge (50% chance)
	if ultra_instinct_active and randf() < 0.5:
		print("✨ Ultra Instinct dodged!")
		return

	# Pillow Fortress damage reduction
	if pillow_fortress_active:
		amount *= 0.5
		print("🛡️ Pillow Fortress reduced damage to %.1f" % amount)

	# Interrupt channeling
	if is_channeling and not cage_destruction_attempted:
		is_channeling = false
		print("⚠️ Channeling interrupted!")

	# Interrupt cage destruction (CRITICAL)
	if cage_destruction_attempted and is_channeling:
		is_channeling = false
		print("✓✓✓ CAGE DESTRUCTION INTERRUPTED! ✓✓✓")

	current_hp -= amount

	var hp_percent = (current_hp / max_hp) * 100.0
	print("🎮 Pam took %.1f damage! HP: %.1f/%.1f (%.1f%%)" % [amount, current_hp, max_hp, hp_percent])

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

	# Check for phase transitions (Fortress only)
	if encounter_type == Encounter.FORTRESS:
		check_phase_transition()

	# Check death
	if current_hp <= 0:
		die()

func check_phase_transition():
	var hp_ratio = current_hp / max_hp

	# Phase 1 -> 2
	if current_phase == Phase.PHASE_1_OTAKU and hp_ratio <= PHASE_2_THRESHOLD and not phase_2_triggered:
		transition_to_phase_2()

	# Phase 2 -> 3
	elif current_phase == Phase.PHASE_2_YANDERE and hp_ratio <= PHASE_3_THRESHOLD and not phase_3_triggered:
		transition_to_phase_3()

func transition_to_phase_2():
	"""Transition to Phase 2: Yandere Mode"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║   PAM PHASE 2: YANDERE MODE         ║")
	print("╚══════════════════════════════════════╝")

	phase_2_triggered = true
	current_phase = Phase.PHASE_2_YANDERE
	current_state = State.PHASE_TRANSITION

	play_dialogue_phase_2()

	# Activate Cringe Aura
	cringe_aura_active = true

	# Increase speed
	current_move_speed *= 1.2
	print("⚡ Speed increased to %.1f" % current_move_speed)

	# Visual: Red tint (yandere)
	if sprite:
		sprite.modulate = Color(1.5, 0.3, 0.3)  # Red
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(3.5, 4.5), 0.5)
		tween.tween_property(sprite, "scale", Vector2(2.5, 3.5), 0.5)

	ParticleManager.create_phase_change_effect(global_position, 300.0)
	CameraShake.shake(20.0, 0.7)

	phase_changed.emit(2)

	# 2-second pause
	await get_tree().create_timer(2.0).timeout

	if is_instance_valid(self):
		current_state = State.ATTACKING
		print("🎮 Phase 2 transition complete! Yandere mode active!")

	print("══════════════════════════════════════")
	print("")

func transition_to_phase_3():
	"""Transition to Phase 3: Ultra Instinct Otaku"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║   PAM PHASE 3: ULTRA INSTINCT       ║")
	print("╚══════════════════════════════════════╝")

	phase_3_triggered = true
	current_phase = Phase.PHASE_3_ULTRA_INSTINCT
	current_state = State.PHASE_TRANSITION

	play_dialogue_phase_3()

	# Activate Ultra Instinct
	ultra_instinct_active = true

	# Massive speed increase
	current_move_speed *= 1.4
	print("⚡⚡ Speed increased to %.1f (ULTRA!)" % current_move_speed)

	# Visual: RGB rainbow aura
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0)  # Super bright
		sprite.scale = Vector2(3.0, 4.0)

	# Reduce ALL cooldowns by 50%
	# (already handled by attack functions checking berserk)

	ParticleManager.create_phase_change_effect(global_position, 400.0)
	CameraShake.shake(30.0, 1.0)

	phase_changed.emit(3)

	# 3-second dramatic pause
	await get_tree().create_timer(3.0).timeout

	if is_instance_valid(self):
		current_state = State.ATTACKING
		print("🎮 Phase 3 transition complete! ULTRA INSTINCT ACTIVATED!")

	print("══════════════════════════════════════")
	print("")

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print("")
	print("╔══════════════════════════════════════╗")
	print("║   === PAM TUNG KEN DEFEATED ===     ║")
	print("╚══════════════════════════════════════╝")

	play_dialogue_death()

	# Death explosion
	ParticleManager.create_death_explosion(global_position, Color(0.2, 0.8, 0.8), 5.0)
	CameraShake.shake(25.0, 1.0)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
		print("⭐ Dropped %.1f XP!" % xp_reward)

	# Drop gold
	attempt_drop_items()

	# Fortress: Offer spare choice
	if encounter_type == Encounter.FORTRESS:
		offer_spare_choice()
	else:
		final_death()

func offer_spare_choice():
	"""Fortress: Give player choice to spare or defeat Pam"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║        SPARE PAM?                    ║")
	print("║   [1] SPARE - Redemption ending      ║")
	print("║   [2] DEFEAT - No mercy ending       ║")
	print("╚══════════════════════════════════════╝")

	# TODO: Implement actual choice UI
	# For now, default to SPARE
	await get_tree().create_timer(2.0).timeout

	print("→ Player chose: SPARE")
	spare_pam_ending()

func spare_pam_ending():
	"""SPARE ending: Pam is redeemed"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║      REDEMPTION ENDING               ║")
	print("╚══════════════════════════════════════╝")

	print("🎮 Pam: \"Why... why would you spare me?\"")
	print("🎮 Pam: \"I tried to kidnap Miku-chan...\"")
	print("💙 Miku: \"True fans don't cage their idols.\"")
	print("🎮 Pam: \"I... I understand now.\"")
	print("🎮 Pam: \"Thank you... both of you.\"")

	print("")
	print("✓ Pam becomes redeemed")
	print("✓ Unlocked: Redemption achievement")
	print("✓ Pam will help in final battle (if applicable)")
	print("✓ Post-game: Pam's shop available")

	# Free Miku permanently
	free_miku_permanently()

	final_death()

func defeat_pam_ending():
	"""DEFEAT ending: No mercy"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║      NO MERCY ENDING                 ║")
	print("╚══════════════════════════════════════╝")

	print("🎮 Pam: \"I... I failed...\"")
	print("🎮 Pam: \"My 347 Nendoroids... worthless...\"")
	print("🎮 Pam: \"Miku-chan... I'm sorry...\"")
	print("🎮 [Dissolves into anime sparkles]")

	print("")
	print("✓ Pam is gone forever")
	print("✓ Unlocked: No Mercy achievement")
	print("✓ Unlocked: Pam's Katana (legendary weapon)")
	print("✓ Post-game: No Pam shop")

	# Free Miku permanently
	free_miku_permanently()

	final_death()

func free_miku_permanently():
	"""Break Miku's cage and set as permanent companion"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║   MIKU FREED PERMANENTLY!            ║")
	print("║   No more timer! Companion forever!  ║")
	print("╚══════════════════════════════════════╝")

	# TODO: Implement actual Miku permanent companion
	# For now just print

func final_death():
	"""Final cleanup and death"""
	# Drop legendary rewards
	drop_legendary_rewards()

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 2.0)
		tween.tween_callback(cleanup_and_destroy)
	else:
		cleanup_and_destroy()

func cleanup_and_destroy():
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
	"""Drop Pam's legendary items"""
	print("")
	print("╔══════════════════════════════════════╗")
	print("║     LEGENDARY REWARDS DROPPED!       ║")
	print("╚══════════════════════════════════════╝")
	print("💡 Glow Stick of Dedication")
	print("🎭 Cringe Aura Charm")
	print("⚔️ Pam's Katana (if defeated)")
	print("══════════════════════════════════════")
	print("")

	# TODO: Implement actual item drops

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		return

	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -40)

	get_tree().root.add_child(damage_num)

	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

# ========== COOLDOWN MANAGEMENT ==========

func update_cooldowns(delta: float):
	"""Update all attack cooldowns"""
	var cooldown_mult = 1.0
	if berserk_mode:
		cooldown_mult = 2.0  # Double cooldown speed

	# Phase 1
	glow_stick_cooldown = max(0, glow_stick_cooldown - delta * cooldown_mult)
	nendoroid_throw_cooldown = max(0, nendoroid_throw_cooldown - delta * cooldown_mult)
	naruto_run_cooldown = max(0, naruto_run_cooldown - delta * cooldown_mult)
	waifu_shield_cooldown = max(0, waifu_shield_cooldown - delta * cooldown_mult)
	keyboard_warrior_cooldown = max(0, keyboard_warrior_cooldown - delta * cooldown_mult)

	# Fortress Phase 1
	glow_stick_barrage_cooldown = max(0, glow_stick_barrage_cooldown - delta * cooldown_mult)
	nendoroid_army_cooldown = max(0, nendoroid_army_cooldown - delta * cooldown_mult)

	# Phase 2
	katana_strike_cooldown = max(0, katana_strike_cooldown - delta * cooldown_mult)
	kamehameha_cooldown = max(0, kamehameha_cooldown - delta * cooldown_mult)
	miku_clone_cooldown = max(0, miku_clone_cooldown - delta * cooldown_mult)
	body_pillow_fortress_cooldown = max(0, body_pillow_fortress_cooldown - delta * cooldown_mult)
	teleport_combo_cooldown = max(0, teleport_combo_cooldown - delta * cooldown_mult)

	# Phase 3
	simp_energy_blast_cooldown = max(0, simp_energy_blast_cooldown - delta * cooldown_mult)
	desperate_teleport_spam_cooldown = max(0, desperate_teleport_spam_cooldown - delta * cooldown_mult)

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
	if encounter_type == Encounter.BLOOD_TEMPLE:
		var lines = [
			"YAMERO! Don't touch Miku-chan!",
			"I've been waiting for her my ENTIRE LIFE!",
			"Miku-chan wa ore no yome desu!"
		]
		print("🎮 \"%s\"" % lines[randi() % lines.size()])
	else:  # Fortress
		var lines = [
			"YOU FOUND MY FORTRESS?!",
			"Impressive... for a normie.",
			"But you'll NEVER take Miku-chan from me!"
		]
		print("🎮 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_damage():
	var lines = [
		"NANI?!",
		"Impossible! I have the power of anime!",
		"My 347 Nendoroids give me strength!"
	]
	if randf() < 0.3:
		print("🎮 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_phase_2():
	print("🎮 \"YANDERE MODE... ACTIVATED!\"")
	print("🎮 \"IF I CAN'T HAVE MIKU, NOBODY CAN!\"")

func play_dialogue_phase_3():
	print("🎮 \"WITNESS MY FINAL FORM!\"")
	print("🎮 \"ULTRA INSTINCT OTAKU!\"")
	print("🎮 \"1000 YEAR SIMP ENERGY!\"")

func play_dialogue_death():
	print("🎮 \"No... my 347 Nendoroids...\"")
	print("🎮 \"My... perfect... plan...\"")
	print("🎮 \"In another timeline... Miku-chan...\"")
	print("🎮 \"Tell her... I... loved her...\"")

func play_dialogue_retreat():
	var lines = [
		"Tch... I'll let you have this round!",
		"This isn't over! I'll be back!",
		"Miku-chan will be MINE!"
	]
	print("🎮 \"%s\"" % lines[randi() % lines.size()])

func play_dialogue_nendoroid():
	print("🎮 \"My precious Nendoroids!\"")

func play_dialogue_naruto_run():
	print("🎮 \"NARUTO RUN JUTSU!\"")

func play_dialogue_waifu_shield():
	print("🎮 \"WAIFU PROTECTION!\"")

func play_dialogue_keyboard():
	print("🎮 \"ACKCHYUALLY...\"")

func play_dialogue_katana():
	print("🎮 \"MY KATANA IS FOLDED 1000 TIMES!\"")

func play_dialogue_kamehameha():
	print("🎮 \"KA-ME-HA-ME-HAAA!\"")

func play_dialogue_miku_clones():
	print("🎮 \"SHADOW CLONE JUTSU!\"")

func play_dialogue_pillow_fortress():
	print("🎮 \"PILLOW FORTRESS!\"")

func play_dialogue_simp_energy():
	print("🎮 \"1000 YEARS OF DEDICATION!\"")

func play_dialogue_berserk():
	print("🎮 \"MIKU-CHAN WA ORE NO YOME!\"")

func play_dialogue_cage_destruction():
	print("🎮 \"IF I CAN'T HAVE HER, NOBODY CAN!\"")
	print("🎮 \"I'LL DESTROY HER FIRST!\"")
