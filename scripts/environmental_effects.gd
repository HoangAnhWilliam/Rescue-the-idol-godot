extends Node
class_name EnvironmentalEffects

# References
var player: CharacterBody2D
var biome_generator: BiomeGenerator

# Original player stats (for restoration)
var original_move_speed: float = 0.0

# Active effects tracking
var active_effects: Array[String] = []

# Effect timers
var lava_damage_timer: float = 0.0
var curse_damage_timer: float = 0.0

# Effect settings
const LAVA_DAMAGE: float = 5.0
const LAVA_INTERVAL: float = 0.5  # Damage every 0.5 seconds
const CURSE_DAMAGE: float = 2.0
const CURSE_INTERVAL: float = 1.0  # Damage every 1 second
const SNOW_SLOW_MULTIPLIER: float = 0.7  # 70% speed

# Signals
signal effect_added(effect_name: String)
signal effect_removed(effect_name: String)

func _ready():
	print("=== EnvironmentalEffects Init ===")

	# Wait for scene tree
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("❌ ERROR: Player not found!")
		return

	print("✓ Player found: ", player.name)

	# Find BiomeGenerator
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if not biome_generator:
		print("⚠️ WARNING: BiomeGenerator not found! Effects disabled.")
		return

	print("✓ BiomeGenerator found")

	# Store original player stats
	if "stats" in player and "move_speed" in player.stats:
		original_move_speed = player.stats.move_speed
		print("📊 Original move speed: ", original_move_speed)
	else:
		print("⚠️ WARNING: Cannot find player move_speed!")

	# Connect to biome changed signal
	biome_generator.biome_changed.connect(_on_biome_changed)
	print("✓ Connected to biome_changed signal")

	# Apply initial biome effects
	var current_biome = biome_generator.get_current_biome()
	if current_biome:
		apply_biome_effects(current_biome)

	print("==================================")

func _process(delta):
	if not player:
		return

	# Update damage-over-time effects
	if "lava_damage" in active_effects:
		lava_damage_timer -= delta
		if lava_damage_timer <= 0:
			apply_lava_damage()
			lava_damage_timer = LAVA_INTERVAL

	if "curse_drain" in active_effects:
		curse_damage_timer -= delta
		if curse_damage_timer <= 0:
			apply_curse_drain()
			curse_damage_timer = CURSE_INTERVAL

func _on_biome_changed(old_biome, new_biome):
	print("")
	print("🌍 === BIOME CHANGE DETECTED ===")
	if old_biome:
		print("FROM: ", old_biome.name)
	if new_biome:
		print("TO: ", new_biome.name)

	# Remove old effects
	remove_all_effects()

	# Apply new effects
	if new_biome:
		apply_biome_effects(new_biome)

	print("=================================")
	print("")

func apply_biome_effects(biome):
	if not biome or not player:
		return

	print("🔄 Applying effects for: ", biome.name)

	# Check biome type and apply appropriate effects
	match biome.type:
		BiomeGenerator.BiomeType.FROZEN_TUNDRA:
			apply_snow_slow()

		BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS:
			apply_lava_damage_effect()

		BiomeGenerator.BiomeType.BLOOD_TEMPLE:
			apply_curse_drain_effect()

		_:
			print("✓ No environmental effects for ", biome.name)

func remove_all_effects():
	if active_effects.is_empty():
		return

	print("🧹 Removing all environmental effects...")

	# Make a copy to iterate safely
	var effects_copy = active_effects.duplicate()

	for effect in effects_copy:
		match effect:
			"snow_slow":
				remove_snow_slow()
			"lava_damage":
				remove_lava_damage()
			"curse_drain":
				remove_curse_drain()

	active_effects.clear()
	print("✓ All effects removed")

# ========== FROZEN TUNDRA: SNOW SLOW ==========

func apply_snow_slow():
	if "snow_slow" in active_effects:
		return  # Already applied

	print("❄️ Applying Snow Slow...")

	if not player or not "stats" in player:
		print("❌ Cannot apply snow slow - invalid player")
		return

	# Reduce move speed to 70%
	if "move_speed" in player.stats:
		player.stats.move_speed = original_move_speed * SNOW_SLOW_MULTIPLIER
		print("❄️ Move speed reduced: %.1f → %.1f" % [original_move_speed, player.stats.move_speed])

	active_effects.append("snow_slow")
	effect_added.emit("snow_slow")
	print("✓ Snow Slow applied!")

func remove_snow_slow():
	if not "snow_slow" in active_effects:
		return

	print("❄️ Removing Snow Slow...")

	if player and "stats" in player and "move_speed" in player.stats:
		player.stats.move_speed = original_move_speed
		print("❄️ Move speed restored: %.1f" % player.stats.move_speed)

	active_effects.erase("snow_slow")
	effect_removed.emit("snow_slow")
	print("✓ Snow Slow removed!")

# ========== VOLCANIC DARKLANDS: LAVA DAMAGE ==========

func apply_lava_damage_effect():
	if "lava_damage" in active_effects:
		return  # Already applied

	print("🔥 Applying Lava Damage...")

	active_effects.append("lava_damage")
	lava_damage_timer = LAVA_INTERVAL  # Start immediately
	effect_added.emit("lava_damage")
	print("✓ Lava Damage applied!")

func remove_lava_damage():
	if not "lava_damage" in active_effects:
		return

	print("🔥 Removing Lava Damage...")

	active_effects.erase("lava_damage")
	lava_damage_timer = 0.0
	effect_removed.emit("lava_damage")
	print("✓ Lava Damage removed!")

func apply_lava_damage():
	if not player:
		return

	if player.has_method("take_damage"):
		player.take_damage(LAVA_DAMAGE)
		print("🔥 Lava damage: %.1f HP (%.1f/s)" % [LAVA_DAMAGE, LAVA_DAMAGE / LAVA_INTERVAL])

# ========== BLOOD TEMPLE: CURSE DRAIN ==========

func apply_curse_drain_effect():
	if "curse_drain" in active_effects:
		return  # Already applied

	print("💀 Applying Curse Drain...")

	active_effects.append("curse_drain")
	curse_damage_timer = CURSE_INTERVAL  # Start immediately
	effect_added.emit("curse_drain")
	print("✓ Curse Drain applied!")

func remove_curse_drain():
	if not "curse_drain" in active_effects:
		return

	print("💀 Removing Curse Drain...")

	active_effects.erase("curse_drain")
	curse_damage_timer = 0.0
	effect_removed.emit("curse_drain")
	print("✓ Curse Drain removed!")

func apply_curse_drain():
	if not player:
		return

	if player.has_method("take_damage"):
		player.take_damage(CURSE_DAMAGE)
		print("💀 Curse drain: %.1f HP (%.1f/s)" % [CURSE_DAMAGE, CURSE_DAMAGE / CURSE_INTERVAL])

# ========== UTILITY FUNCTIONS ==========

func get_active_effects() -> Array[String]:
	return active_effects.duplicate()

func has_effect(effect_name: String) -> bool:
	return effect_name in active_effects

func get_effect_description(effect_name: String) -> String:
	match effect_name:
		"snow_slow":
			return "❄️ Slowed (%.0f%% speed)" % (SNOW_SLOW_MULTIPLIER * 100)
		"lava_damage":
			return "🔥 Burning (%.1f HP/s)" % (LAVA_DAMAGE / LAVA_INTERVAL)
		"curse_drain":
			return "💀 Cursed (%.1f HP/s)" % (CURSE_DAMAGE / CURSE_INTERVAL)
		_:
			return ""
