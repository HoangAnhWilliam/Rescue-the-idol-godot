extends CanvasLayer
## World Creation Settings Dialog (Minecraft-style)
##
## Features:
## - Game Mode selection (Survival, Adventure, Creative, New Game+)
## - Difficulty selection (Easy, Normal, Hard, Nightmare)
## - Starting Biome selection
## - Cheats toggle
## - World Modifiers (Fast XP, More Gold, etc.)
## - World Seed for procedural generation

signal world_created(world_settings: Dictionary)

# Node references
@onready var panel = $Panel
@onready var title_label = $Panel/VBox/Title
@onready var subtitle_label = $Panel/VBox/Subtitle
@onready var game_mode_option = $Panel/VBox/SettingsGrid/GameModeOption
@onready var difficulty_option = $Panel/VBox/SettingsGrid/DifficultyOption
@onready var biome_option = $Panel/VBox/SettingsGrid/BiomeOption
@onready var seed_input = $Panel/VBox/SettingsGrid/SeedInput
@onready var cheats_check = $Panel/VBox/ModifiersGrid/CheatsCheck
@onready var fast_xp_check = $Panel/VBox/ModifiersGrid/FastXPCheck
@onready var more_gold_check = $Panel/VBox/ModifiersGrid/MoreGoldCheck
@onready var extra_lives_check = $Panel/VBox/ModifiersGrid/ExtraLivesCheck
@onready var no_death_check = $Panel/VBox/ModifiersGrid/NoDeathCheck
@onready var infinite_mana_check = $Panel/VBox/ModifiersGrid/InfiniteManaCheck
@onready var create_btn = $Panel/VBox/Buttons/CreateButton
@onready var cancel_btn = $Panel/VBox/Buttons/CancelButton

# For editing existing world
var edit_mode: bool = false
var slot_number: int = -1

func _ready():
	# BUG FIX: Set high priority for visibility
	if self is CanvasLayer:
		layer = 10
	z_index = 200

	# Populate dropdowns
	setup_game_modes()
	setup_difficulties()
	setup_biomes()

	# Connect buttons
	create_btn.pressed.connect(_on_create_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Connect cheats checkbox to enable/disable modifiers
	cheats_check.toggled.connect(_on_cheats_toggled)

	# Initially disable modifiers if cheats are off
	_on_cheats_toggled(false)

	print("World Creation Settings ready, edit_mode: ", edit_mode)

func setup_game_modes():
	game_mode_option.clear()
	game_mode_option.add_item("🗡️ Survival - Classic roguelite experience", 0)
	game_mode_option.add_item("🗺️ Adventure - Explore without permadeath", 1)
	game_mode_option.add_item("🎨 Creative - Unlimited resources, no enemies", 2)
	game_mode_option.add_item("⭐ New Game+ - Harder, keep some stats", 3)
	game_mode_option.selected = 0

func setup_difficulties():
	difficulty_option.clear()
	difficulty_option.add_item("😊 Easy - 150% HP, 75% enemy damage", 0)
	difficulty_option.add_item("⚔️ Normal - Balanced experience", 1)
	difficulty_option.add_item("💀 Hard - 75% HP, 125% enemy damage", 2)
	difficulty_option.add_item("👹 Nightmare - 50% HP, 200% enemy damage", 3)
	difficulty_option.selected = 1

func setup_biomes():
	biome_option.clear()
	biome_option.add_item("🌲 Starting Forest - Beginner friendly", 0)
	biome_option.add_item("🩸 Blood Temple - Medium difficulty", 1)
	biome_option.add_item("🌑 Darkland - High difficulty", 2)
	biome_option.add_item("🎲 Random - Surprise me!", 3)
	biome_option.selected = 0

## BUG FIX #2: Edit existing world settings
func edit_world(slot_id: int):
	slot_number = slot_id
	edit_mode = true

	print("📝 Opening Edit World Settings for slot ", slot_id)

	# Load world settings from SaveSystem
	var slot_key = "slot_%d" % slot_id

	# Try to get settings from SaveSystem
	var settings = null

	if SaveSystem.save_data.has(slot_key):
		settings = SaveSystem.save_data[slot_key].get("world_settings", null)

	# If no settings found, CREATE DEFAULT
	if not settings:
		print("⚠️ No world settings found for slot ", slot_id)
		print("📝 Creating default settings...")

		settings = {
			"game_mode": "survival",
			"difficulty": "normal",
			"starting_biome": "Starting Forest",
			"world_seed": str(randi()),
			"cheats_enabled": false,
			"modifiers": {
				"fast_xp": false,
				"more_gold": false,
				"extra_lives": false,
				"no_death": false,
				"infinite_mana": false
			},
			"created_at": Time.get_unix_time_from_system()
		}

		# Save default settings
		if not SaveSystem.save_data.has(slot_key):
			SaveSystem.save_data[slot_key] = {}

		SaveSystem.save_data[slot_key]["world_settings"] = settings
		SaveSystem.save_game()

	# Load settings into UI
	load_world_settings(settings)

	# BUG FIX: Force dialog to be visible
	visible = true
	show()

	# Set high z-index to appear above other UI
	if self is CanvasLayer:
		layer = 10
	z_index = 200

	# Debug visibility
	print("🔍 Dialog visible:", visible)
	print("🔍 Dialog z_index:", z_index)
	if self is CanvasLayer:
		print("🔍 Dialog layer:", layer)

	print("✅ World Creation Settings ready for editing")

func _on_cheats_toggled(enabled: bool):
	# Enable/disable all modifier checkboxes based on cheats
	fast_xp_check.disabled = !enabled
	more_gold_check.disabled = !enabled
	extra_lives_check.disabled = !enabled
	no_death_check.disabled = !enabled
	infinite_mana_check.disabled = !enabled

	# Uncheck all modifiers if cheats disabled
	if !enabled:
		fast_xp_check.button_pressed = false
		more_gold_check.button_pressed = false
		extra_lives_check.button_pressed = false
		no_death_check.button_pressed = false
		infinite_mana_check.button_pressed = false

func _on_create_pressed():
	print("🌍 Creating world with settings...")

	# Gather all settings
	var world_settings = {
		"game_mode": get_game_mode_string(),
		"difficulty": get_difficulty_string(),
		"starting_biome": get_biome_string(),
		"world_seed": seed_input.text if seed_input.text != "" else str(randi()),
		"cheats_enabled": cheats_check.button_pressed,
		"modifiers": {
			"fast_xp": fast_xp_check.button_pressed,
			"more_gold": more_gold_check.button_pressed,
			"extra_lives": extra_lives_check.button_pressed,
			"no_death": no_death_check.button_pressed,
			"infinite_mana": infinite_mana_check.button_pressed
		},
		"created_at": Time.get_unix_time_from_system()
	}

	print("   Settings: ", world_settings)

	# Emit signal with settings
	world_created.emit(world_settings)

	# Close dialog
	queue_free()

func _on_cancel_pressed():
	print("❌ World creation cancelled")

	# Hide before removing
	hide()

	queue_free()

func get_game_mode_string() -> String:
	match game_mode_option.selected:
		0: return "survival"
		1: return "adventure"
		2: return "creative"
		3: return "new_game_plus"
	return "survival"

func get_difficulty_string() -> String:
	match difficulty_option.selected:
		0: return "easy"
		1: return "normal"
		2: return "hard"
		3: return "nightmare"
	return "normal"

func get_biome_string() -> String:
	match biome_option.selected:
		0: return "Starting Forest"
		1: return "Blood Temple"
		2: return "Darkland"
		3: return ["Starting Forest", "Blood Temple", "Darkland"][randi() % 3]
	return "Starting Forest"

## Load existing world settings for editing
func load_world_settings(settings: Dictionary):
	edit_mode = true

	# Update UI for edit mode
	title_label.text = "✏️ EDIT WORLD SETTINGS"
	subtitle_label.text = "Modify your world configuration"
	create_btn.text = "SAVE CHANGES"

	# Set game mode
	var mode = settings.get("game_mode", "survival")
	match mode:
		"survival": game_mode_option.selected = 0
		"adventure": game_mode_option.selected = 1
		"creative": game_mode_option.selected = 2
		"new_game_plus": game_mode_option.selected = 3

	# Set difficulty
	var diff = settings.get("difficulty", "normal")
	match diff:
		"easy": difficulty_option.selected = 0
		"normal": difficulty_option.selected = 1
		"hard": difficulty_option.selected = 2
		"nightmare": difficulty_option.selected = 3

	# Set biome
	var biome = settings.get("starting_biome", "Starting Forest")
	match biome:
		"Starting Forest": biome_option.selected = 0
		"Blood Temple": biome_option.selected = 1
		"Darkland": biome_option.selected = 2

	# Set seed (read-only in edit mode)
	seed_input.text = settings.get("world_seed", "")
	seed_input.editable = false

	# Set cheats
	cheats_check.button_pressed = settings.get("cheats_enabled", false)

	# Set modifiers
	var mods = settings.get("modifiers", {})
	fast_xp_check.button_pressed = mods.get("fast_xp", false)
	more_gold_check.button_pressed = mods.get("more_gold", false)
	extra_lives_check.button_pressed = mods.get("extra_lives", false)
	no_death_check.button_pressed = mods.get("no_death", false)
	infinite_mana_check.button_pressed = mods.get("infinite_mana", false)

	# Update button text
	create_btn.text = "SAVE CHANGES"

	print("Loaded world settings for editing")
