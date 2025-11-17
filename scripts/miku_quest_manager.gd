extends Node
class_name MikuQuestManager

## Manages the entire Miku Rescue Quest System
## Coordinates: Dark Miku → Cages → Fragments → Ritual → Despair Miku → Permanent Miku

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
var dark_miku_scene: PackedScene = preload("res://scenes/enemies/dark_miku.tscn")
var crystal_cage_scene: PackedScene = preload("res://scenes/miku/crystal_cage.tscn")
var ritual_circle_scene: PackedScene = preload("res://scenes/miku/ritual_circle.tscn")

# Signals
signal quest_state_changed(new_state: QuestState)
signal dark_miku_defeated
signal cage_rescued(cage_number: int)
signal all_fragments_collected
signal ritual_unlocked
signal despair_miku_summoned
signal quest_completed

func _ready() -> void:
	add_to_group("miku_quest_manager")

	# Find player
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D

	# Wait a frame for everything to initialize
	await get_tree().process_frame

	print("=== Miku Quest System Initialized ===")

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
	"""Start the Miku Rescue Quest"""

	if current_state != QuestState.NOT_STARTED:
		return

	print("=== MIKU RESCUE QUEST STARTED ===")

	# Spawn Dark Miku
	spawn_dark_miku()

	# Change state
	current_state = QuestState.DARK_MIKU_ACTIVE
	quest_state_changed.emit(current_state)


func spawn_dark_miku() -> void:
	"""Spawn Dark Miku mini-boss"""

	# Find Blood Temple position (center of map for now)
	var spawn_position := Vector2(0, 0)

	# Try to find Blood Temple node
	var blood_temple := get_tree().get_first_node_in_group("blood_temple")
	if blood_temple:
		spawn_position = blood_temple.global_position

	# Spawn Dark Miku
	var dark_miku := dark_miku_scene.instantiate()
	dark_miku.global_position = spawn_position
	get_tree().root.add_child(dark_miku)

	# Connect defeat signal
	if dark_miku.has_signal("boss_defeated"):
		dark_miku.boss_defeated.connect(on_dark_miku_defeated)

	print("Dark Miku spawned at %s" % spawn_position)


func on_dark_miku_defeated() -> void:
	"""Called when Dark Miku is defeated"""

	print("=== DARK MIKU DEFEATED ===")

	current_state = QuestState.DARK_MIKU_DEFEATED
	quest_state_changed.emit(current_state)
	dark_miku_defeated.emit()

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

	ChatBox.send_chat_message("System", "Crystal cages have appeared! Find them to rescue Miku!", "System", get_tree())


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

	# Connect to Miku companion vanish signal
	var miku_companion := get_tree().get_first_node_in_group("miku_companion")
	if miku_companion and miku_companion.has_signal("miku_vanished"):
		miku_companion.miku_vanished.connect(on_miku_vanished)


func on_miku_vanished(vanish_position: Vector2) -> void:
	"""Called when Miku companion vanishes"""

	print("Miku vanished at %s" % vanish_position)

	# Collect fragment
	fragments_collected += 1

	# Add fragment to UI
	var fragment_bar := get_tree().get_first_node_in_group("miku_fragment_bar") as MikuFragmentBar
	if fragment_bar:
		# Show bar on first fragment
		if fragments_collected == 1 and not fragment_bar.is_revealed:
			fragment_bar.show_fragment_bar_first_time()
			await get_tree().create_timer(1.0).timeout

		# Add fragment animation
		fragment_bar.add_miku_fragment(vanish_position)

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
		ritual_circle.boss_spawned.connect(on_despair_miku_spawned)

	# Notify player
	ChatBox.send_chat_message("System", "A ritual circle has awakened!", "System", get_tree())
	ChatBox.send_chat_message("System", "Go to the center to summon Despair Miku!", "System", get_tree())

	ritual_unlocked.emit()


func on_despair_miku_spawned() -> void:
	"""Called when Despair Miku boss is summoned"""

	print("=== DESPAIR MIKU SUMMONED ===")

	current_state = QuestState.DESPAIR_MIKU_ACTIVE
	quest_state_changed.emit(current_state)
	despair_miku_summoned.emit()

	# Connect to boss defeat
	await get_tree().create_timer(0.5).timeout

	var despair_miku := get_tree().get_first_node_in_group("despair_miku")
	if despair_miku and despair_miku.has_signal("boss_defeated"):
		despair_miku.boss_defeated.connect(on_despair_miku_defeated)


func on_despair_miku_defeated() -> void:
	"""Called when Despair Miku is defeated"""

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
	var fragment_bar := get_tree().get_first_node_in_group("miku_fragment_bar") as MikuFragmentBar
	if fragment_bar:
		fragment_bar.reset_fragments()

	print("Quest reset complete")


# Debug helpers

func force_spawn_dark_miku() -> void:
	"""Debug: Force spawn Dark Miku"""
	spawn_dark_miku()


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
