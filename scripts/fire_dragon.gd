extends CharacterBody2D
class_name FireDragon

# ========== BOSS STATS ==========

# Base stats
@export var max_hp: float = 1000.0  # 33x zombie
@export var base_damage: float = 30.0
@export var base_move_speed: float = 150.0
@export var xp_reward: float = 500.0  # 50x zombie
@export var detection_range: float = 800.0
@export var gold_drop_min: int = 200
@export var gold_drop_max: int = 500

# Current stats
var current_hp: float
var current_damage: float
var current_move_speed: float

# ========== PHASE SYSTEM ==========

enum Phase { PHASE_1, PHASE_2, PHASE_3 }
var current_phase: Phase = Phase.PHASE_1

# Phase HP thresholds
const PHASE_2_THRESHOLD: float = 0.66  # 66% HP
const PHASE_3_THRESHOLD: float = 0.33  # 33% HP

# Phase modifiers
const PHASE_2_SPEED_MULT: float = 1.2  # 20% faster
const PHASE_3_SPEED_MULT: float = 1.4  # 40% faster
const PHASE_HEAL_PERCENT: float = 0.10  # Heal 10% on transition

# ========== ATTACK STATS ==========

# Fireball (Phase 1+)
const FIREBALL_COOLDOWN: float = 3.0
const FIREBALL_DAMAGE: float = 40.0
const FIREBALL_SPEED: float = 400.0
const FIREBALL_LIFETIME: float = 5.0
const FIREBALL_SIZE: Vector2 = Vector2(32, 32)
var fireball_timer: float = 0.0

# Fire Breath (Phase 2+)
const BREATH_COOLDOWN: float = 8.0
const BREATH_DAMAGE: float = 25.0
const BREATH_TICKS: int = 5
const BREATH_DURATION: float = 1.0
const BREATH_RANGE: float = 300.0
const BREATH_OFFSET: float = 200.0  # Distance in front of dragon
const BREATH_SIZE: Vector2 = Vector2(600, 600)
var breath_timer: float = 0.0

# Tail Swipe (All phases, melee only)
const TAIL_COOLDOWN: float = 5.0
const TAIL_DAMAGE: float = 50.0
const TAIL_RANGE: float = 200.0  # Trigger range
const TAIL_RADIUS: float = 250.0  # Damage radius
const TAIL_KNOCKBACK: float = 400.0
const TAIL_DELAY: float = 0.3  # Windup before damage
var tail_timer: float = 0.0
var tail_active: bool = false

# ========== STATE MACHINE ==========

enum State { IDLE, CHASE, ATTACKING, PHASE_TRANSITION, DEAD }
var current_state: State = State.IDLE

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

# ========== SIGNALS ==========

signal boss_defeated
signal phase_changed(phase: int)
signal attack_started(attack_type: String)

# ========== INITIALIZATION ==========

func _ready():
	print("")
	print("╔══════════════════════════════════════╗")
	print("║       FIRE DRAGON INITIALIZED        ║")
	print("╚══════════════════════════════════════╝")

	# Initialize stats
	current_hp = max_hp
	current_damage = base_damage
	current_move_speed = base_move_speed

	print("Fire Dragon HP: ", max_hp)
	print("Fire Dragon Damage: ", base_damage)
	print("Fire Dragon Speed: ", base_move_speed)

	# Add to groups
	add_to_group("bosses")
	add_to_group("enemies")

	# Scale up to boss size
	if sprite:
		sprite.scale = Vector2(5.0, 5.0)
		print("✓ Boss scale set to 5.0")

	# Set visual
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.0)  # Orange-red
		print("✓ Boss color set to orange-red")

	print("Fire Dragon ready!")
	print("══════════════════════════════════════")
	print("")

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Update cooldown timers
	if fireball_timer > 0:
		fireball_timer -= delta
	if breath_timer > 0:
		breath_timer -= delta
	if tail_timer > 0:
		tail_timer -= delta

	# State machine
	match current_state:
		State.IDLE:
			search_for_player()

		State.CHASE:
			chase_player(delta)

		State.ATTACKING:
			perform_attacks(delta)

		State.PHASE_TRANSITION:
			# Handled by tween, do nothing
			pass

# ========== AI LOGIC ==========

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.CHASE
		print("🔥 Fire Dragon engaged!")

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

	var distance = global_position.distance_to(player.global_position)

	# Stop moving while attacking
	velocity = Vector2.ZERO

	# Face player
	update_sprite_direction()

	# Attack priority: Tail Swipe > Fireball > Fire Breath

	# 1. Tail Swipe (melee range)
	if distance < TAIL_RANGE and tail_timer <= 0:
		attack_tail_swipe()
		return

	# 2. Fireball (all phases)
	if fireball_timer <= 0:
		attack_fireball()
		return

	# 3. Fire Breath (Phase 2+)
	if current_phase >= Phase.PHASE_2 and breath_timer <= 0:
		attack_fire_breath()
		return

	# If no attacks available, chase
	if distance > 400:
		current_state = State.CHASE

# ========== ATTACK IMPLEMENTATIONS ==========

func attack_fireball():
	print("🔥 Fire Dragon: FIREBALL!")

	attack_started.emit("fireball")
	fireball_timer = FIREBALL_COOLDOWN

	# ← THÊM: Camera shake on fireball attack
	CameraShake.shake(8.0, 0.2)

	# Spawn fireball projectile
	spawn_fireball()

func spawn_fireball():
	# Create Area2D for projectile
	var fireball = Area2D.new()
	fireball.name = "Fireball"

	# Add ColorRect visual
	var visual = ColorRect.new()
	visual.size = FIREBALL_SIZE
	visual.position = -FIREBALL_SIZE / 2  # Center
	visual.color = Color(1.0, 0.5, 0.0)  # Orange
	fireball.add_child(visual)

	# Add collision shape
	var shape = RectangleShape2D.new()
	shape.size = FIREBALL_SIZE
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	fireball.add_child(collision_shape)

	# Set position
	fireball.global_position = global_position

	# Calculate direction to player
	var direction = (player.global_position - global_position).normalized()

	# Set metadata for projectile_mover
	fireball.set_meta("direction", direction)
	fireball.set_meta("speed", FIREBALL_SPEED)
	fireball.set_meta("damage", FIREBALL_DAMAGE)
	fireball.set_meta("lifetime", FIREBALL_LIFETIME)
	fireball.set_meta("from_boss", true)

	# Attach projectile mover script
	fireball.set_script(projectile_mover_script)

	# Add to scene
	get_tree().root.add_child(fireball)

	print("✓ Fireball spawned")

func attack_fire_breath():
	print("🔥 Fire Dragon: FIRE BREATH!")

	attack_started.emit("fire_breath")
	breath_timer = BREATH_COOLDOWN

	# Create breath cone
	create_breath_cone()

func create_breath_cone():
	# Calculate position in front of dragon
	var direction_to_player = (player.global_position - global_position).normalized()
	var breath_pos = global_position + direction_to_player * BREATH_OFFSET

	# Create Area2D for damage
	var breath = Area2D.new()
	breath.name = "FireBreath"
	breath.global_position = breath_pos

	# Add ColorRect visual (semi-transparent)
	var visual = ColorRect.new()
	visual.size = BREATH_SIZE
	visual.position = -BREATH_SIZE / 2  # Center
	visual.color = Color(1.0, 0.4, 0.0, 0.3)  # Orange, 30% alpha
	breath.add_child(visual)

	# Add collision shape (circle)
	var shape = CircleShape2D.new()
	shape.radius = BREATH_RANGE
	var collision_shape = CollisionShape2D.new()
	collision_shape.shape = shape
	breath.add_child(collision_shape)

	# Add to scene
	get_tree().root.add_child(breath)

	print("✓ Fire breath created at: ", breath_pos)

	# Deal damage over time
	apply_breath_damage(breath)

	# Remove after duration
	await get_tree().create_timer(BREATH_DURATION).timeout
	if is_instance_valid(breath):
		breath.queue_free()

func apply_breath_damage(breath: Area2D):
	var tick_interval = BREATH_DURATION / float(BREATH_TICKS)

	for i in range(BREATH_TICKS):
		await get_tree().create_timer(tick_interval).timeout

		if not is_instance_valid(breath):
			break

		# Check for player in area
		var bodies = breath.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player"):
				if body.has_method("take_damage"):
					body.take_damage(BREATH_DAMAGE)
					print("🔥 Fire breath tick: %.1f damage" % BREATH_DAMAGE)

func attack_tail_swipe():
	if tail_active:
		return  # Already performing swipe

	print("🔥 Fire Dragon: TAIL SWIPE!")

	attack_started.emit("tail_swipe")
	tail_timer = TAIL_COOLDOWN
	tail_active = true

	# ← THÊM: Camera shake on tail swipe
	CameraShake.shake(8.0, 0.2)

	# Visual: Rotate sprite 360°
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "rotation", TAU, TAIL_DELAY)
		tween.tween_property(sprite, "rotation", 0.0, 0.1)

	# Wait for windup
	await get_tree().create_timer(TAIL_DELAY).timeout

	# Deal damage
	deal_tail_damage()

	tail_active = false

func deal_tail_damage():
	print("💥 Tail swipe damage!")

	# Check all bodies in radius
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	# Create circle for area check
	var shape = CircleShape2D.new()
	shape.radius = TAIL_RADIUS
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1  # Player layer

	var results = space_state.intersect_shape(query, 32)

	for result in results:
		var body = result["collider"]

		if body.is_in_group("player"):
			if body.has_method("take_damage"):
				body.take_damage(TAIL_DAMAGE)
				print("💥 Tail swipe hit player! Damage: %.1f" % TAIL_DAMAGE)

				# Apply knockback
				var knockback_dir = (body.global_position - global_position).normalized()
				if "velocity" in body:
					body.velocity = knockback_dir * TAIL_KNOCKBACK
				print("💨 Knockback applied!")

# ========== DAMAGE & DEATH ==========

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	# Invulnerable during phase transition
	if current_state == State.PHASE_TRANSITION:
		return

	current_hp -= amount

	var hp_percent = (current_hp / max_hp) * 100.0
	print("🔥 Fire Dragon took %.1f damage! HP: %.1f/%.1f (%.1f%%)" % [amount, current_hp, max_hp, hp_percent])

	# Spawn damage number
	spawn_damage_number(amount, is_crit)

	# Visual feedback
	if sprite:
		var original_color = sprite.modulate
		sprite.modulate = Color.YELLOW
		await get_tree().create_timer(0.1).timeout
		if sprite and is_instance_valid(self):
			sprite.modulate = original_color

	# Check for phase transitions
	check_phase_transition()

	# Check death
	if current_hp <= 0:
		die()

func check_phase_transition():
	var hp_ratio = current_hp / max_hp

	# Phase 1 -> 2
	if current_phase == Phase.PHASE_1 and hp_ratio <= PHASE_2_THRESHOLD:
		transition_to_phase(Phase.PHASE_2)

	# Phase 2 -> 3
	elif current_phase == Phase.PHASE_2 and hp_ratio <= PHASE_3_THRESHOLD:
		transition_to_phase(Phase.PHASE_3)

func transition_to_phase(new_phase: Phase):
	print("")
	print("╔══════════════════════════════════════╗")
	print("║   !!! FIRE DRAGON PHASE %d !!!      ║" % (new_phase + 1))
	print("╚══════════════════════════════════════╝")

	current_phase = new_phase
	current_state = State.PHASE_TRANSITION

	# Heal 10%
	var heal_amount = max_hp * PHASE_HEAL_PERCENT
	current_hp = min(current_hp + heal_amount, max_hp)
	print("💚 Healed %.1f HP! Current: %.1f/%.1f" % [heal_amount, current_hp, max_hp])

	# Increase speed
	match new_phase:
		Phase.PHASE_2:
			current_move_speed = base_move_speed * PHASE_2_SPEED_MULT
			print("⚡ Speed increased to %.1f" % current_move_speed)

		Phase.PHASE_3:
			current_move_speed = base_move_speed * PHASE_3_SPEED_MULT
			print("⚡⚡ Speed increased to %.1f (ENRAGED!)" % current_move_speed)

	# Visual: Scale animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(6.0, 6.0), 0.5)
		tween.tween_property(sprite, "scale", Vector2(5.0, 5.0), 0.5)

	# ← THÊM: Phase change particle effect and camera shake
	ParticleManager.create_phase_change_effect(global_position, 300.0)
	CameraShake.shake(20.0, 0.6)

	# Emit signal
	phase_changed.emit(new_phase + 1)  # 1-indexed for display

	# 2-second pause
	await get_tree().create_timer(2.0).timeout

	# Resume combat
	if is_instance_valid(self):
		current_state = State.ATTACKING
		print("🔥 Phase transition complete! Resuming combat...")

	print("══════════════════════════════════════")
	print("")

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print("")
	print("╔══════════════════════════════════════╗")
	print("║  === FIRE DRAGON DEFEATED ===        ║")
	print("╚══════════════════════════════════════╝")

	# ← THÊM: Massive death explosion and extreme camera shake
	ParticleManager.create_death_explosion(global_position, Color(1.0, 0.3, 0.0), 5.0)
	CameraShake.shake(30.0, 1.0)

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)
		print("⭐ Dropped %.1f XP!" % xp_reward)

	# Drop gold
	attempt_drop_items()

	# Death animation (scale up + fade)
	if sprite:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(sprite, "scale", Vector2(8.0, 8.0), 1.0)
		tween.tween_property(sprite, "modulate:a", 0.0, 1.0)
		tween.tween_callback(cleanup_and_destroy)
	else:
		cleanup_and_destroy()

	print("══════════════════════════════════════")
	print("")

func cleanup_and_destroy():
	# Emit defeated signal
	boss_defeated.emit()

	# Remove from scene
	queue_free()

func attempt_drop_items():
	# Gold drop
	var gold_amount = randi_range(gold_drop_min, gold_drop_max)
	spawn_gold(gold_amount)

func spawn_gold(amount: int):
	if player and player.has_method("add_gold"):
		player.add_gold(amount)
		print("💰 Dropped %d gold!" % amount)

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		return

	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -50)

	get_tree().root.add_child(damage_num)

	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

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
