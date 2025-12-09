extends CharacterBody2D
class_name Enemy

# Stats
@export var max_hp: float = 30.0
@export var damage: float = 5.0
@export var move_speed: float = 50.0
@export var xp_reward: float = 10.0
@export var detection_range: float = 400.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0  # ← THÊM
@export var gold_drop_min: int = 10
@export var gold_drop_max: int = 50

var current_hp: float
var attack_timer: float = 0.0  # ← THÊM
var player: CharacterBody2D = null  # ← ĐỔI từ Player

# State machine
enum State { IDLE, CHASE, ATTACK, DEAD }
var current_state: State = State.IDLE

# References - ĐÃ FIX ↓
@onready var sprite = $ColorRect if has_node("ColorRect") else null
@onready var collision = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var hitbox = $HitboxArea if has_node("HitboxArea") else null

#Preload damage number scene
var damage_number_scene = preload("res://scenes/effects/damage_number.tscn")
var hit_particle_scene = preload("res://scenes/effects/hit_particle.tscn")
var death_particle_scene = preload("res://scenes/effects/death_particle.tscn")

func _ready():
	print("Enemy ready: ", name)
	
	current_hp = max_hp
	add_to_group("enemies")
	
	# Connect hitbox với safety check
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)
		print("✓ Hitbox connected for ", name)
	else:
		print("WARNING: No hitbox for ", name)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	# Phase 6: Check if charmed (Enchanting Flute)
	if has_meta("charmed") and get_meta("charmed"):
		var duration = get_meta("charm_duration", 0.0)
		duration -= delta
		set_meta("charm_duration", duration)

		if duration > 0:
			# Attack other enemies instead of player
			attack_nearest_enemy(delta)
			return
		else:
			# Charm expired naturally (flute handles death)
			remove_meta("charmed")
			remove_meta("charm_duration")

	# Update attack timer
	if attack_timer > 0:
		attack_timer -= delta

	match current_state:
		State.IDLE:
			search_for_player()
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			perform_attack(delta)  # ← THÊM delta

func search_for_player():
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Don't detect invisible player
	if "is_invisible" in player and player.is_invisible:
		return

	var distance = global_position.distance_to(player.global_position)
	if distance < detection_range:
		current_state = State.CHASE
		print(name, " started chasing player")

func chase_player(delta):
	if not player:
		current_state = State.IDLE
		return

	# Stop chasing if player becomes invisible
	if "is_invisible" in player and player.is_invisible:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		return

	var distance = global_position.distance_to(player.global_position)

	if distance > detection_range * 1.5:
		current_state = State.IDLE
		return

	if distance < attack_range:
		current_state = State.ATTACK
		return

	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

	# Update sprite direction
	update_sprite()

func perform_attack(delta):  # ← THÊM delta parameter
	if not player:
		current_state = State.IDLE
		return
	
	var distance = global_position.distance_to(player.global_position)
	if distance > attack_range * 1.5:
		current_state = State.CHASE
		return
	
	# Stop moving
	velocity = Vector2.ZERO
	
	# Attack with cooldown
	if attack_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(damage)
			print(name, " attacked player!")
			attack_timer = attack_cooldown

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	print(name, " took ", amount, " damage. HP: ", current_hp, "/", max_hp)

	# ← AUDIO: Play hit impact sound (or critical hit if crit)
	if is_crit:
		AudioManager.play_sfx("critical_hit")
	else:
		AudioManager.play_sfx("hit_impact")

	# ← THÊM: Particle effect when hit
	ParticleManager.create_hit_effect(global_position, Color(1.0, 0.3, 0.3))

	# Spawn damage number
	spawn_damage_number(amount, is_crit)

	# Spawn hit particles
	spawn_hit_particle(is_crit)
	
	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Check again after await
			sprite.modulate = Color.WHITE
	
	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 200
	
	if current_hp <= 0:
		die()

func spawn_damage_number(damage: float, is_crit: bool = false):
	if not damage_number_scene:
		print("ERROR: Damage number scene not loaded!")
		return
	
	var damage_num = damage_number_scene.instantiate()
	damage_num.global_position = global_position + Vector2(0, -20)
	
	# Add to scene root để không bị ảnh hưởng khi enemy die
	get_tree().root.add_child(damage_num)
	
	# Setup damage number
	if damage_num.has_method("setup"):
		damage_num.setup(damage, is_crit)

func spawn_hit_particle(is_crit: bool = false):
	if not hit_particle_scene:
		print("WARNING: Hit particle scene not loaded!")
		return
	
	var particle = hit_particle_scene.instantiate()
	particle.global_position = global_position
	
	# Add to scene root
	get_tree().root.add_child(particle)
	
	# Set color based on crit
	if particle.has_method("set_color_from_damage"):
		particle.set_color_from_damage(is_crit)

func spawn_death_particle():
	if not death_particle_scene:
		print("WARNING: Death particle scene not loaded!")
		return
	
	var particle = death_particle_scene.instantiate()
	particle.global_position = global_position
	
	# Add to scene root
	get_tree().root.add_child(particle)
	
	# Set color based on enemy type
	if particle.has_method("set_color_for_enemy"):
		particle.set_color_for_enemy(name)

func die():
	current_state = State.DEAD
	set_physics_process(false)

	print(name, " died!")

	# ← AUDIO: Play enemy death sound
	AudioManager.play_sfx("enemy_death")

	# ← THÊM: Death explosion and camera shake
	var enemy_color = sprite.color if sprite else Color.RED
	ParticleManager.create_death_explosion(global_position, enemy_color, 1.0)
	CameraShake.shake(5.0, 0.2)

	# Spawn death particle effect
	spawn_death_particle()

	# Increment player kill counter
	if player and "total_kills" in player:
		player.total_kills += 1
		print("💀 Kill count: ", player.total_kills)

	# Drop XP Gem (Phase 5.1: Replace direct add_xp)
	drop_xp_gem()

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	# Drop items
	attempt_drop_items()

func attempt_drop_items():
	# Phase 5.5.7: Updated drop system with pickups
	var lucky_multiplier = get_player_lucky()

	# Health pickup (15% base chance)
	if randf() < 0.15 * lucky_multiplier:
		spawn_health_pickup()

	# Mana pickup (10% base chance)
	if randf() < 0.10 * lucky_multiplier:
		spawn_mana_pickup()

	# Gold coins (10% base chance)
	if randf() < 0.10 * lucky_multiplier:
		var gold_amount = randi_range(gold_drop_min, gold_drop_max)
		spawn_gold(gold_amount)

	# Weapon drop (1% base chance - rare!)
	if randf() < 0.01 * lucky_multiplier:
		spawn_weapon_drop()

func get_player_lucky() -> float:
	# Check if player exists and has lucky property
	if not player:
		return 1.0
	
	# Dùng "in" thay vì has()
	if "lucky" in player:
		return player.lucky
	
	# Default
	return 1.0

func drop_xp_gem():
	# Phase 5.1: Spawn XP gem instead of direct add_xp
	var xp_gem_scene = load("res://scenes/pickups/xp_gem.tscn")
	if xp_gem_scene:
		var gem = xp_gem_scene.instantiate()
		gem.global_position = global_position
		gem.xp_value = xp_reward
		get_tree().root.add_child(gem)

func spawn_health_pickup():
	var scene = load("res://scenes/pickups/health_pickup.tscn")
	if scene:
		var pickup = scene.instantiate()
		pickup.global_position = global_position
		get_tree().root.add_child(pickup)

func spawn_mana_pickup():
	var scene = load("res://scenes/pickups/mana_pickup.tscn")
	if scene:
		var pickup = scene.instantiate()
		pickup.global_position = global_position
		get_tree().root.add_child(pickup)

func spawn_gold(amount: int):
	# Phase 5.4: Spawn gold coins as pickups
	var scene = load("res://scenes/pickups/gold_coin.tscn")
	if scene:
		var coin = scene.instantiate()
		coin.gold_value = amount
		coin.global_position = global_position
		get_tree().root.add_child(coin)

func spawn_weapon_drop():
	# Phase 6: Spawn weapon pickup with rarity system
	var weapon_id = get_random_weapon_id()
	var weapon_name = get_weapon_name(weapon_id)

	var scene = load("res://scenes/pickups/weapon_pickup.tscn")
	if scene:
		var weapon = scene.instantiate()
		weapon.weapon_id = weapon_id
		weapon.weapon_name = weapon_name
		weapon.global_position = global_position
		get_tree().root.add_child(weapon)
		print("💎 Weapon drop: ", weapon_name)

func get_random_weapon_id() -> String:
	"""Phase 6: Random weapon based on rarity"""
	var roll = randf()

	# Common (40%)
	if roll < 0.40:
		return "wooden_sword"

	# Uncommon (40%)
	elif roll < 0.80:
		var uncommon = ["earthshatter_staff", "shadow_daggers"]
		return uncommon[randi() % uncommon.size()]

	# Rare (18%)
	elif roll < 0.98:
		var rare = ["acid_gauntlets", "frost_bow", "lightning_chain"]
		return rare[randi() % rare.size()]

	# Epic (2%)
	else:
		return "enchanting_flute"

	# Note: Legendary (Miku Sword) only from Miku rescue, not random drops

func get_weapon_name(weapon_id: String) -> String:
	"""Phase 6: Get weapon display name"""
	match weapon_id:
		"wooden_sword": return "Wooden Sword"
		"kiku_sword": return "Miku Sword"
		"earthshatter_staff": return "Earthshatter Staff"
		"acid_gauntlets": return "Acid Storm Gauntlets"
		"enchanting_flute": return "Enchanting Flute"
		"shadow_daggers": return "Shadow Daggers"
		"frost_bow": return "Frost Bow"
		"lightning_chain": return "Lightning Chain"
		_: return "Unknown Weapon"

# Phase 6: Charm mechanics - charmed enemies attack other enemies
func attack_nearest_enemy(delta):
	"""Called when enemy is charmed - attacks other enemies"""
	var target_enemy = find_nearest_other_enemy()

	if target_enemy:
		var distance = global_position.distance_to(target_enemy.global_position)

		if distance > attack_range:
			# Move toward target
			var direction = (target_enemy.global_position - global_position).normalized()
			velocity = direction * move_speed
			move_and_slide()
		else:
			# Attack other enemy
			if attack_timer <= 0:
				if target_enemy.has_method("take_damage"):
					# Charmed enemies deal 50% damage
					target_enemy.take_damage(damage * 0.5, global_position)
					attack_timer = attack_cooldown
					print("💕 Charmed ", name, " attacks ", target_enemy.name)
	else:
		# No target, stand still
		velocity = Vector2.ZERO

func find_nearest_other_enemy() -> CharacterBody2D:
	"""Find nearest enemy that isn't self"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: CharacterBody2D = null
	var min_dist = INF

	for other in enemies:
		if other == self or not is_instance_valid(other):
			continue

		var dist = global_position.distance_to(other.global_position)
		if dist < min_dist and dist < detection_range:
			min_dist = dist
			closest = other

	return closest

func _on_hitbox_entered(body):
	# Check if body is player
	if body.is_in_group("player"):
		# Damage player on collision
		if body.has_method("take_damage") and attack_timer <= 0:
			body.take_damage(damage)
			attack_timer = attack_cooldown  # Prevent spam damage
			print(name, " collided with player!")

	# Also damage buff skeletons if we collide with them
	elif body.is_in_group("buff_skeletons"):
		if body.has_method("take_damage") and attack_timer <= 0:
			body.take_damage(damage, global_position)
			attack_timer = attack_cooldown
			print(name, " collided with buff skeleton!")

func update_sprite():
	if not sprite:
		return
	
	if velocity.x != 0:
		if sprite is Sprite2D:
			sprite.flip_h = velocity.x > 0
		elif sprite is ColorRect:
			sprite.scale.x = -1 if velocity.x > 0 else 1
