extends Node2D
class_name PermanentKiku

## Permanent Kiku pet companion (reward after defeating Despair Kiku)
## Follows player, provides passive buffs, visual reactions

# Following
var player: CharacterBody2D = null
var offset: Vector2 = Vector2(100, -50)  # Upper-right of player

# Animation
var bob_amplitude: float = 8.0
var bob_speed: float = 3.0
var bob_time: float = 0.0

# Visual
@onready var sprite: ColorRect = $ColorRect

# Signals
signal kiku_unlocked

func _ready() -> void:
	add_to_group("permanent_kiku")

	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if not player:
		push_error("PermanentKiku: Player not found!")
		queue_free()
		return

	# Setup sprite
	if sprite:
		sprite.size = Vector2(24, 24)
		sprite.position = -sprite.size / 2
		sprite.color = Color(0, 0.85, 1)  # Cyan

	# Make it child of player (moves with player automatically)
	# But first need to reparent properly
	var parent := get_parent()
	if parent:
		parent.remove_child(self)

	player.add_child(self)

	# Apply passive buffs to player
	apply_passive_buffs()

	# Emit signal
	kiku_unlocked.emit()

	print("✓ Permanent Kiku pet unlocked!")


func _process(delta: float) -> void:
	# Bobbing animation
	bob_time += delta
	var bob_offset := Vector2(0, sin(bob_time * bob_speed * TAU) * bob_amplitude)
	position = offset + bob_offset

	# React to player state
	react_to_player_state()


func react_to_player_state() -> void:
	"""React to player's current state"""

	if not player or not is_instance_valid(player):
		return

	if not sprite:
		return

	# Check player HP
	if player.has_method("get_hp_percent"):
		var hp_percent: float = player.get_hp_percent()

		if hp_percent < 0.3:
			# Low HP: Worried (red tint)
			sprite.modulate = Color(1, 0.6, 0.6)
		else:
			# Normal: Cyan
			sprite.modulate = Color(1, 1, 1)
	else:
		# Fallback: Check current_hp directly
		if "current_hp" in player and "stats" in player:
			var current_hp: float = player.current_hp
			var max_hp: float = player.stats.max_hp
			var hp_percent: float = current_hp / max_hp

			if hp_percent < 0.3:
				sprite.modulate = Color(1, 0.6, 0.6)
			else:
				sprite.modulate = Color(1, 1, 1)


func on_player_level_up() -> void:
	"""Happy spin animation when player levels up"""

	var tween := create_tween()
	tween.tween_property(self, "rotation", TAU, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func() -> void: rotation = 0.0)


func apply_passive_buffs() -> void:
	"""Apply permanent passive buffs to player"""

	if not player:
		return

	# Apply passive bonuses
	if player.has_method("apply_permanent_kiku_buffs"):
		player.apply_permanent_kiku_buffs()
	else:
		# Fallback: Apply buffs directly if method exists
		if player.get("stats"):
			var stats = player.stats

			# +10% luck (better drops)
			if stats.has("lucky"):
				stats.lucky *= 1.1

			# +0.2 HP/s regen
			if stats.has("hp_regen_per_second"):
				stats.hp_regen_per_second += 0.2

		# Set multipliers
		if "xp_multiplier" in player:
			var current_xp_mult: float = player.xp_multiplier if "xp_multiplier" in player else 1.0
			player.xp_multiplier = current_xp_mult * 1.05  # +5% XP

		if "gold_multiplier" in player:
			var current_gold_mult: float = player.gold_multiplier if "gold_multiplier" in player else 1.0
			player.gold_multiplier = current_gold_mult * 1.05  # +5% gold

	print("Permanent buffs applied: +10% luck, +5% XP, +5% gold, +0.2 HP/s regen")


func celebrate() -> void:
	"""Play celebration animation (on boss kill, etc.)"""

	if not sprite:
		return

	# Jump up and spin
	var original_y := position.y
	var tween := create_tween()
	tween.tween_property(self, "position:y", original_y - 30, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "rotation", TAU, 0.6)
	tween.tween_property(self, "position:y", original_y, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void: rotation = 0.0)


func show_love() -> void:
	"""Show love animation (hearts)"""

	if not sprite:
		return

	# Create heart particle effect
	var heart := Label.new()
	heart.text = "💙"
	heart.add_theme_font_size_override("font_size", 20)
	heart.z_index = 100
	heart.position = Vector2(0, -20)
	add_child(heart)

	# Animate heart floating up and fading
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(heart, "position:y", -60, 1.5)
	tween.tween_property(heart, "modulate:a", 0.0, 1.5)

	await tween.finished
	heart.queue_free()
