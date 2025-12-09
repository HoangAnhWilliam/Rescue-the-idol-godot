extends Node
class_name KikuQuestManager

## Manages the entire Kiku Rescue Quest System
## Coordinates: Dark Kiku → Cages → Fragments → Ritual → Despair Kiku → Permanent Kiku

# Quest state
enum QuestState {
	NOT_STARTED,
	DARK_MIKU_ACTIVE,
	DARK_MIKU_DEFEATED,
	CAGES_ACTIVE,
	RITUAL_UNLOCKED,
	DESPAIR_MIKU_ACTIVE,
	QUEST_COMPLETE
}

var current_state: QuestState = QuestState.NOT_STARTED

# References
var player: CharacterBody2D = null
var blood_temple_biome: Node2D = null

# Crystal cages
var crystal_cages: Array[CrystalCage] = []
var current_cage_index: int = 0
var cages_spawned: bool = false

# Fragment tracking
var fragments_collected: int = 0
const TOTAL_FRAGMENTS: int = 5

# Ritual
var ritual_circle: RitualCircle = null

# Scenes
var dark_kiku_scene: PackedScene = preload("res://scenes/enemies/dark_kiku.tscn")
var crystal_cage_scene: PackedScene = preload("res://scenes/kiku/crystal_cage.tscn")
var ritual_circle_scene: PackedScene = preload("res://scenes/kiku/ritual_circle.tscn")

# Signals
signal quest_state_changed(new_state: QuestState)
signal dark_kiku_defeated
signal cage_rescued(cage_number: int)
signal all_fragments_collected
signal ritual_unlocked
signal despair_kiku_summoned
signal quest_completed

func _ready() -> void:
	add_to_group("kiku_quest_manager")

	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	# Wait a frame for everything to initialize
	await get_tree().process_frame

	print("=== Kiku Quest System Initialized ===")

	# Check if player is in Blood Temple to start quest
	call_deferred("check_start_conditions")


func check_start_conditions() -> void:
	"""Check if conditions are met to start the quest"""

	if current_state != QuestState.NOT_STARTED:
		return

	# Check if player has entered Blood Temple
	# For now, start automatically after 5 seconds (testing)
	await get_tree().create_timer(5.0).timeout

	start_quest()


func start_quest() -> void:
	"""Start the Kiku Rescue Quest"""

	if current_state != QuestState.NOT_STARTED:
		return

	print("=== MIKU RESCUE QUEST STARTED ===")

	# Spawn Dark Kiku
	spawn_dark_kiku()

	# Change state
	current_state = QuestState.DARK_MIKU_ACTIVE
	quest_state_changed.emit(current_state)


func spawn_dark_kiku() -> void:
	"""Spawn Dark Kiku mini-boss"""

	# Find Blood Temple position (center of map for now)
	var spawn_position := Vector2(0, 0)

	# Try to find Blood Temple node
	var blood_temple := get_tree().get_first_node_in_group("blood_temple")
	if blood_temple:
		spawn_position = blood_temple.global_position

	# Spawn Dark Kiku
	var dark_kiku := dark_kiku_scene.instantiate()
	dark_kiku.global_position = spawn_position
	get_tree().root.add_child(dark_kiku)

	# Connect defeat signal
	if dark_kiku.has_signal("boss_defeated"):
		dark_kiku.boss_defeated.connect(on_dark_kiku_defeated)

	print("Dark Kiku spawned at %s" % spawn_position)


func on_dark_kiku_defeated() -> void:
	"""Called when Dark Kiku is defeated"""

	print("=== DARK MIKU DEFEATED ===")

	current_state = QuestState.DARK_MIKU_DEFEATED
	quest_state_changed.emit(current_state)
	dark_kiku_defeated.emit()

	# Spawn crystal cages
	await get_tree().create_timer(2.0).timeout
	spawn_crystal_cages()


func spawn_crystal_cages() -> void:
	"""Spawn 5 crystal cages in Blood Temple"""

	if cages_spawned:
		return

	print("=== SPAWNING CRYSTAL CAGES ===")

	# Generate 5 positions in Blood Temple
	var cage_positions: Array[Vector2] = generate_cage_positions()

	for i in range(5):
		var cage := crystal_cage_scene.instantiate() as CrystalCage
		cage.cage_number = i + 1
		cage.global_position = cage_positions[i]

		# Connect signals
		cage.rescue_completed.connect(on_cage_rescued.bind(i))

		get_tree().root.add_child(cage)
		crystal_cages.append(cage)

	# Set first cage as active
	if crystal_cages.size() > 0:
		crystal_cages[0].set_active()

	cages_spawned = true
	current_state = QuestState.CAGES_ACTIVE
	quest_state_changed.emit(current_state)

	ChatBox.send_chat_message("System", "Crystal cages have appeared! Find them to rescue Kiku!", "System", get_tree())


func generate_cage_positions() -> Array[Vector2]:
	"""Generate 5 random positions for cages"""

	var positions: Array[Vector2] = []

	# Generate in a circle around center
	var center := Vector2(0, 0)
	var radius := 400.0

	for i in range(5):
		var angle := (TAU / 5) * i + randf_range(-0.3, 0.3)
		var offset := Vector2(cos(angle), sin(angle)) * (radius + randf_range(-100, 100))
		positions.append(center + offset)

	return positions


func on_cage_rescued(cage_index: int) -> void:
	"""Called when a cage is rescued"""

	print("Cage #%d rescued" % (cage_index + 1))

	cage_rescued.emit(cage_index + 1)

	# Connect to Kiku companion vanish signal
	var kiku_companion := get_tree().get_first_node_in_group("kiku_companion")
	if kiku_companion and kiku_companion.has_signal("kiku_vanished"):
		kiku_companion.kiku_vanished.connect(on_kiku_vanished)


func on_kiku_vanished(vanish_position: Vector2) -> void:
	"""Called when Kiku companion vanishes"""

	print("Kiku vanished at %s" % vanish_position)

	# Collect fragment
	fragments_collected += 1

	# Add fragment to UI
	var fragment_bar := get_tree().get_first_node_in_group("kiku_fragment_bar") as KikuFragmentBar
	if fragment_bar:
		# Show bar on first fragment
		if fragments_collected == 1 and not fragment_bar.is_revealed:
			fragment_bar.show_fragment_bar_first_time()
			await get_tree().create_timer(1.0).timeout

		# Add fragment animation
		fragment_bar.add_kiku_fragment(vanish_position)

	# Check if all fragments collected
	if fragments_collected >= TOTAL_FRAGMENTS:
		on_all_fragments_collected()
	else:
		# Activate next cage
		activate_next_cage()


func activate_next_cage() -> void:
	"""Activate the next cage in sequence"""

	current_cage_index += 1

	if current_cage_index >= crystal_cages.size():
		return

	var next_cage := crystal_cages[current_cage_index]

	# Transition animation
	await get_tree().create_timer(1.0).timeout
	next_cage.transition_to_active()

	ChatBox.send_chat_message("System", "Another crystal cage has appeared!", "System", get_tree())


func on_all_fragments_collected() -> void:
	"""Called when all 5 fragments are collected"""

	print("=== ALL FRAGMENTS COLLECTED ===")

	current_state = QuestState.RITUAL_UNLOCKED
	quest_state_changed.emit(current_state)
	all_fragments_collected.emit()

	# Spawn ritual circle
	await get_tree().create_timer(2.0).timeout
	spawn_ritual_circle()


func spawn_ritual_circle() -> void:
	"""Spawn ritual summoning circle"""

	print("=== SPAWNING RITUAL CIRCLE ===")

	# Spawn at center
	var spawn_position := Vector2(0, 0)

	ritual_circle = ritual_circle_scene.instantiate()
	ritual_circle.global_position = spawn_position
	get_tree().root.add_child(ritual_circle)

	# Connect signals
	if ritual_circle.has_signal("boss_spawned"):
		ritual_circle.boss_spawned.connect(on_despair_kiku_spawned)

	# Notify player
	ChatBox.send_chat_message("System", "A ritual circle has awakened!", "System", get_tree())
	ChatBox.send_chat_message("System", "Go to the center to summon Despair Kiku!", "System", get_tree())

	ritual_unlocked.emit()


func on_despair_kiku_spawned() -> void:
	"""Called when Despair Kiku boss is summoned"""

	print("=== DESPAIR MIKU SUMMONED ===")

	current_state = QuestState.DESPAIR_MIKU_ACTIVE
	quest_state_changed.emit(current_state)
	despair_kiku_summoned.emit()

	# Connect to boss defeat
	await get_tree().create_timer(0.5).timeout

	var despair_kiku := get_tree().get_first_node_in_group("despair_kiku")
	if despair_kiku and despair_kiku.has_signal("boss_defeated"):
		despair_kiku.boss_defeated.connect(on_despair_kiku_defeated)


func on_despair_kiku_defeated() -> void:
	"""Called when Despair Kiku is defeated"""

	print("=== DESPAIR MIKU DEFEATED - QUEST COMPLETE ===")

	current_state = QuestState.QUEST_COMPLETE
	quest_state_changed.emit(current_state)
	quest_completed.emit()

	# Quest complete!
	ChatBox.send_chat_message("System", "╔════════════════════════╗", "System", get_tree())
	ChatBox.send_chat_message("System", "║  QUEST COMPLETE!  ║", "System", get_tree())
	ChatBox.send_chat_message("System", "╚════════════════════════╝", "System", get_tree())


func reset_quest() -> void:
	"""Reset quest (for testing or New Game+)"""

	print("=== RESETTING MIKU QUEST ===")

	# Clear cages
	for cage in crystal_cages:
		if is_instance_valid(cage):
			cage.queue_free()
	crystal_cages.clear()

	# Clear ritual circle
	if ritual_circle and is_instance_valid(ritual_circle):
		ritual_circle.queue_free()
		ritual_circle = null

	# Reset state
	current_state = QuestState.NOT_STARTED
	current_cage_index = 0
	fragments_collected = 0
	cages_spawned = false

	# Reset fragment bar
	var fragment_bar := get_tree().get_first_node_in_group("kiku_fragment_bar") as KikuFragmentBar
	if fragment_bar:
		fragment_bar.reset_fragments()

	print("Quest reset complete")


# Debug helpers

func force_spawn_dark_kiku() -> void:
	"""Debug: Force spawn Dark Kiku"""
	spawn_dark_kiku()


func force_spawn_cages() -> void:
	"""Debug: Force spawn cages"""
	spawn_crystal_cages()


func force_spawn_ritual() -> void:
	"""Debug: Force spawn ritual circle"""
	spawn_ritual_circle()


func skip_to_ritual() -> void:
	"""Debug: Skip to ritual phase"""
	fragments_collected = TOTAL_FRAGMENTS
	spawn_ritual_circle()
