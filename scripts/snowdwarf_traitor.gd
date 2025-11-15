extends Enemy
class_name SnowdwarfTraitor

# Snowdwarf Traitor specific mechanics
enum TraitorState { APPROACHING, DECIDING, TRADING, BETRAYED, FIGHTING }
var traitor_state: TraitorState = TraitorState.APPROACHING
var has_decided: bool = false
var trade_prompt_shown: bool = false
var will_betray: bool = false

var ice_blast_cooldown: float = 10.0
var ice_blast_timer: float = 0.0
var ice_blast_damage: float = 25.0
var ice_blast_range: float = 150.0

var approach_speed: float = 30.0
var combat_speed: float = 50.0
var decision_range: float = 100.0

# Trade UI (simple)
var trade_label: Label = null

func _ready():
	# Override base stats
	max_hp = 40.0
	current_hp = max_hp
	damage = 8.0  # Melee damage
	move_speed = approach_speed
	xp_reward = 35.0
	detection_range = 500.0  # Detect from far
	attack_range = ice_blast_range
	attack_cooldown = 1.5

	add_to_group("enemies")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_entered)

	# Random decision: 50% betray
	will_betray = randf() < 0.5

	print("Snowdwarf Traitor spawned (Will betray: ", will_betray, ") at ", global_position)

func _physics_process(delta):
	if current_state == State.DEAD:
		return

	if attack_timer > 0:
		attack_timer -= delta
	if ice_blast_timer > 0:
		ice_blast_timer -= delta

	# Handle traitor states
	match traitor_state:
		TraitorState.APPROACHING:
			handle_approach(delta)
		TraitorState.DECIDING:
			handle_decision(delta)
		TraitorState.TRADING:
			handle_trading(delta)
		TraitorState.BETRAYED:
			handle_betrayed(delta)
		TraitorState.FIGHTING:
			handle_fighting(delta)

func handle_approach(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	var distance = global_position.distance_to(player.global_position)

	# Check if close enough to decide
	if distance <= decision_range:
		traitor_state = TraitorState.DECIDING
		velocity = Vector2.ZERO
		return

	# Walk slowly toward player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * approach_speed
	move_and_slide()

	# Visual: Friendly mode (green outline simulation)
	if sprite:
		sprite.modulate = Color(0.8, 1.2, 0.9)

func handle_decision(delta):
	if has_decided:
		return

	has_decided = true

	if will_betray:
		print("Snowdwarf Traitor BETRAYED!")
		betray_player()
	else:
		print("Snowdwarf Traitor offering trade...")
		offer_trade()

func offer_trade():
	traitor_state = TraitorState.TRADING

	# Show trade prompt
	show_trade_prompt()

	# Wait for player interaction or timeout
	await get_tree().create_timer(5.0).timeout

	# Trade timeout - despawn peacefully
	if traitor_state == TraitorState.TRADING:
		print("Snowdwarf Traitor trade timeout, leaving...")
		despawn_peacefully()

func show_trade_prompt():
	# Create simple label
	trade_label = Label.new()
	trade_label.text = "Press E to Trade (2000 gold - Random Weapon)"
	trade_label.position = Vector2(-100, -60)
	add_child(trade_label)

	trade_prompt_shown = true

func _input(event):
	if traitor_state == TraitorState.TRADING and trade_prompt_shown:
		if event is InputEventKey and event.pressed and event.keycode == KEY_E:
			attempt_trade()

func attempt_trade():
	if not player:
		return

	# Check if player has enough gold
	var player_gold = 0
	if player.has_method("get_total_gold"):
		player_gold = player.get_total_gold()

	if player_gold >= 2000:
		print("Snowdwarf Traitor: Trade successful!")

		# Take gold
		if player.has_method("spend_gold"):
			player.spend_gold(2000)

		# Give random weapon (simplified - just give XP bonus)
		if player.has_method("add_xp"):
			player.add_xp(100)

		# Show message
		if trade_label:
			trade_label.text = "Thanks for trading!"

		await get_tree().create_timer(1.0).timeout
		despawn_peacefully()
	else:
		print("Snowdwarf Traitor: Not enough gold!")
		if trade_label:
			trade_label.text = "Not enough gold!"

func despawn_peacefully():
	if trade_label:
		trade_label.queue_free()

	# Fade out
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tween.tween_callback(queue_free)
	else:
		queue_free()

func betray_player():
	traitor_state = TraitorState.BETRAYED

	# Visual: Red outline
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)

	# Immediate ice blast
	ice_blast_attack()

	# Enter combat mode
	await get_tree().create_timer(0.5).timeout
	traitor_state = TraitorState.FIGHTING
	move_speed = combat_speed

func handle_trading(delta):
	# Wait in trading state, player can press E to trade
	# Movement is stopped, just idle
	velocity = Vector2.ZERO

func handle_betrayed(delta):
	# Just transition state, actual attack already fired
	pass

func handle_fighting(delta):
	if not player:
		return

	var distance = global_position.distance_to(player.global_position)

	# Ice blast attack
	if ice_blast_timer <= 0 and distance <= ice_blast_range:
		ice_blast_attack()

	# Simple chase and melee
	if distance > 50.0:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		if attack_timer <= 0 and player.has_method("take_damage"):
			player.take_damage(damage)
			attack_timer = attack_cooldown

func ice_blast_attack():
	if not player or not player.has_method("take_damage"):
		return

	print("Snowdwarf Traitor ICE BLAST!")

	# Damage
	player.take_damage(ice_blast_damage)

	# Freeze effect: 70% slow for 3s
	if player.has_method("apply_slow"):
		player.apply_slow(0.7, 3.0)

	ice_blast_timer = ice_blast_cooldown

	# Visual effect
	if has_node("/root/ParticleManager"):
		get_node("/root/ParticleManager").create_hit_effect(player.global_position)

	# Camera shake
	if has_node("/root/CameraShake"):
		get_node("/root/CameraShake").shake(0.3, 0.3)

func take_damage(amount: float, from_position: Vector2 = Vector2.ZERO, is_crit: bool = false):
	current_hp -= amount

	# If attacked during approach/trading, immediately betray
	if traitor_state == TraitorState.APPROACHING or traitor_state == TraitorState.TRADING:
		print("Snowdwarf Traitor attacked! Immediate betrayal!")
		if trade_label:
			trade_label.queue_free()
		betray_player()

	# Visual feedback
	if sprite:
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if sprite:
			if traitor_state == TraitorState.FIGHTING or traitor_state == TraitorState.BETRAYED:
				sprite.modulate = Color(1.5, 0.5, 0.5)
			else:
				sprite.modulate = Color(0.8, 0.7, 0.9)

	# Knockback
	if from_position != Vector2.ZERO:
		var knockback_dir = (global_position - from_position).normalized()
		velocity = knockback_dir * 180

	if current_hp <= 0:
		die()

func die():
	current_state = State.DEAD
	set_physics_process(false)

	# Remove trade label
	if trade_label:
		trade_label.queue_free()

	# Drop XP
	if player and player.has_method("add_xp"):
		player.add_xp(xp_reward)

	# Death animation
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_callback(queue_free)
	else:
		queue_free()

	print("Snowdwarf Traitor died")
