extends Node
class_name BossManager

# Boss scene references (assign in Inspector or auto-load)
@export var fire_dragon_scene: PackedScene
@export var vampire_lord_scene: PackedScene

# Boss tracking
var active_bosses: Dictionary = {}  # BiomeType -> Boss instance
var boss_spawned_flags: Dictionary = {}  # BiomeType -> bool (spawned this session)
var boss_defeated_flags: Dictionary = {}  # BiomeType -> bool (defeated this session)

# Spawn positions for each boss
const BOSS_SPAWN_POSITIONS: Dictionary = {
	BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS: Vector2(0, 3500),
	BiomeGenerator.BiomeType.BLOOD_TEMPLE: Vector2(-3500, 0)
}

# Distance thresholds for boss spawning
const BOSS_SPAWN_DISTANCES: Dictionary = {
	BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS: 4000.0,
	BiomeGenerator.BiomeType.BLOOD_TEMPLE: 5000.0
}

# References
var player: CharacterBody2D
var biome_generator: BiomeGenerator

# Signals
signal boss_spawned(boss_type: String, boss: Node)
signal boss_defeated(boss_type: String)
signal boss_phase_changed(boss: Node, phase: int)

func _ready():
	print("")
	print("╔══════════════════════════════════════╗")
	print("║     BOSS MANAGER INITIALIZATION      ║")
	print("╚══════════════════════════════════════╝")

	# Wait for scene tree
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("❌ ERROR: Player not found!")
		return
	print("✓ Player found")

	# Find BiomeGenerator
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if not biome_generator:
		print("⚠️ WARNING: BiomeGenerator not found! Boss spawning disabled.")
		return
	print("✓ BiomeGenerator found")

	# Connect to entered_boss_zone signal
	if biome_generator.has_signal("entered_boss_zone"):
		biome_generator.entered_boss_zone.connect(_on_entered_boss_zone)
		print("✓ Connected to entered_boss_zone signal")
	else:
		print("⚠️ WARNING: BiomeGenerator missing entered_boss_zone signal!")

	# Initialize tracking dictionaries
	for biome_type in BiomeGenerator.BiomeType.values():
		boss_spawned_flags[biome_type] = false
		boss_defeated_flags[biome_type] = false

	# Load boss scenes if not assigned
	load_boss_scenes()

	print("══════════════════════════════════════")
	print("")

func load_boss_scenes():
	# Fire Dragon
	if not fire_dragon_scene:
		print("Loading Fire Dragon scene...")
		fire_dragon_scene = load("res://scenes/bosses/fire_dragon.tscn")
		if fire_dragon_scene:
			print("✓ Fire Dragon loaded!")
		else:
			print("❌ ERROR: Cannot load Fire Dragon scene!")

	# Vampire Lord (future)
	if not vampire_lord_scene:
		print("Loading Vampire Lord scene...")
		vampire_lord_scene = load("res://scenes/bosses/vampire_lord.tscn")
		if vampire_lord_scene:
			print("✓ Vampire Lord loaded!")
		else:
			print("⚠️ Vampire Lord scene not found (not implemented yet)")

func _process(_delta):
	# Check spawn conditions based on player distance from spawn
	if not player or not biome_generator:
		return

	var current_biome = biome_generator.get_current_biome()
	if not current_biome:
		return

	# Only check for boss zones
	if current_biome.type in BOSS_SPAWN_DISTANCES:
		check_boss_spawn_condition(current_biome.type)

func check_boss_spawn_condition(biome_type: BiomeGenerator.BiomeType):
	# Skip if boss already spawned or defeated this session
	if boss_spawned_flags[biome_type]:
		return
	if boss_defeated_flags[biome_type]:
		return

	# Check distance from world spawn (0, 0)
	var distance_from_spawn = player.global_position.length()
	var required_distance = BOSS_SPAWN_DISTANCES[biome_type]

	if distance_from_spawn >= required_distance:
		spawn_boss_for_biome(biome_type)

func _on_entered_boss_zone(biome_type: BiomeGenerator.BiomeType):
	print("🎯 Player entered boss zone: ", BiomeGenerator.BiomeType.keys()[biome_type])

	# This is called when player enters a boss-capable biome
	# Actual spawning is handled by distance check in _process()

func spawn_boss_for_biome(biome_type: BiomeGenerator.BiomeType):
	match biome_type:
		BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS:
			spawn_fire_dragon()

		BiomeGenerator.BiomeType.BLOOD_TEMPLE:
			spawn_vampire_lord()

func spawn_fire_dragon():
	if not fire_dragon_scene:
		print("❌ ERROR: Fire Dragon scene not loaded!")
		return

	var biome_type = BiomeGenerator.BiomeType.VOLCANIC_DARKLANDS

	# Check one more time
	if boss_spawned_flags[biome_type]:
		return

	print("")
	print("╔══════════════════════════════════════╗")
	print("║   !!! SPAWNING FIRE DRAGON !!!      ║")
	print("╚══════════════════════════════════════╝")

	# Instantiate boss
	var boss = fire_dragon_scene.instantiate()
	var spawn_pos = BOSS_SPAWN_POSITIONS[biome_type]
	boss.global_position = spawn_pos

	# Add to scene
	get_tree().root.add_child(boss)

	# Track boss
	active_bosses[biome_type] = boss
	boss_spawned_flags[biome_type] = true

	print("=== FIRE DRAGON BOSS SPAWNED ===")
	print("Fire Dragon spawned at: ", spawn_pos)

	# Connect to boss signals
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated.bind(biome_type, "Fire Dragon"))
		print("✓ Connected to boss_defeated signal")

	if boss.has_signal("phase_changed"):
		boss.phase_changed.connect(_on_boss_phase_changed.bind(boss))
		print("✓ Connected to phase_changed signal")

	# Emit our signal
	boss_spawned.emit("Fire Dragon", boss)

	print("════════════════════════════════════════")
	print("")

func spawn_vampire_lord():
	# TODO: Implement in future
	print("⚠️ Vampire Lord not implemented yet!")

func _on_boss_defeated(biome_type: BiomeGenerator.BiomeType, boss_name: String):
	print("")
	print("╔══════════════════════════════════════╗")
	print("║  === %s DEFEATED ===  ║" % boss_name.to_upper())
	print("╚══════════════════════════════════════╝")

	# Mark as defeated
	boss_defeated_flags[biome_type] = true

	# Remove from active bosses
	if biome_type in active_bosses:
		active_bosses.erase(biome_type)

	print("Boss defeated in biome: ", BiomeGenerator.BiomeType.keys()[biome_type])

	# Emit signal
	boss_defeated.emit(boss_name)

	print("════════════════════════════════════════")
	print("")

func _on_boss_phase_changed(phase: int, boss: Node):
	print("🔥 Boss phase changed to: ", phase)

	# Emit signal
	boss_phase_changed.emit(boss, phase)

# ========== PUBLIC API ==========

func get_active_boss() -> Node:
	"""Return the currently active boss, or null if none"""
	for boss in active_bosses.values():
		if is_instance_valid(boss):
			return boss
	return null

func is_boss_active() -> bool:
	"""Check if any boss is currently alive"""
	return get_active_boss() != null

func get_boss_for_biome(biome_type: BiomeGenerator.BiomeType) -> Node:
	"""Get the active boss for a specific biome"""
	if biome_type in active_bosses:
		var boss = active_bosses[biome_type]
		if is_instance_valid(boss):
			return boss
	return null

func is_boss_defeated(biome_type: BiomeGenerator.BiomeType) -> bool:
	"""Check if a boss has been defeated this session"""
	return boss_defeated_flags.get(biome_type, false)

func reset_boss_flags():
	"""Reset all boss flags (for testing or new game)"""
	print("🔄 Resetting all boss flags...")
	for biome_type in BiomeGenerator.BiomeType.values():
		boss_spawned_flags[biome_type] = false
		boss_defeated_flags[biome_type] = false
	active_bosses.clear()
	print("✓ Boss flags reset!")
