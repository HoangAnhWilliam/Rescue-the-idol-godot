extends Node

const SAVE_PATH = "user://save_game.dat"
const SAVE_VERSION = "1.0"
const TOTAL_SLOTS = 3

var current_slot: int = 1  # Currently selected save slot

var save_data: Dictionary = {
	"version": SAVE_VERSION,
	"player": {
		"permanent_hp_upgrades": 0,
		"permanent_luck_upgrades": 0,
		"permanent_mana_threshold": 0,
		"total_kills": 0,
		"total_playtime": 0.0,
	},
	"progress": {
		"blood_temple_cleared": false,
		"darkland_cleared": false,
		"kiku_rescues": 0,
		"highest_wave": 0,
		"games_played": 0,
	},
	"unlocks": {
		"weapons": [],
		"endings": [],
	},
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"difficulty": "normal"
	}
}

func _ready():
	load_game()

func save_game():
	# Save to current slot
	save_to_slot(current_slot)
	return true

func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, using default data")
		return save_data
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var loaded_data = file.get_var()
		file.close()
		
		# Verify version
		if loaded_data.get("version", "") == SAVE_VERSION:
			save_data = loaded_data
			print("Game loaded successfully")
		else:
			print("Save version mismatch, using default data")
		
		return save_data
	else:
		push_error("Failed to load game")
		return save_data

func reset_save():
	save_data = {
		"version": SAVE_VERSION,
		"player": {
			"permanent_hp_upgrades": 0,
			"permanent_luck_upgrades": 0,
			"permanent_mana_threshold": 0,
			"total_kills": 0,
			"total_playtime": 0.0,
		},
		"progress": {
			"blood_temple_cleared": false,
			"darkland_cleared": false,
			"kiku_rescues": 0,
			"highest_wave": 0,
			"games_played": 0,
		},
		"unlocks": {
			"weapons": [],
			"endings": [],
		},
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"difficulty": "normal"
		}
	}
	save_game()

# Permanent upgrades
func add_hp_upgrade():
	save_data.player.permanent_hp_upgrades += 1
	save_game()

func add_luck_upgrade():
	save_data.player.permanent_luck_upgrades += 1
	save_game()

func add_kills(amount: int):
	save_data.player.total_kills += amount
	
	# Check for mana upgrades
	var old_threshold = save_data.player.permanent_mana_threshold
	var new_threshold = int(save_data.player.total_kills / 100000)
	
	if new_threshold > old_threshold:
		save_data.player.permanent_mana_threshold = new_threshold
		# Notify player of mana upgrade
	
	save_game()

func add_playtime(seconds: float):
	save_data.player.total_playtime += seconds
	save_game()

# Progress tracking
func mark_blood_temple_cleared():
	save_data.progress.blood_temple_cleared = true
	save_game()

func mark_darkland_cleared():
	save_data.progress.darkland_cleared = true
	save_game()

func add_kiku_rescue():
	save_data.progress.kiku_rescues += 1
	save_game()

func update_highest_wave(wave: int):
	if wave > save_data.progress.highest_wave:
		save_data.progress.highest_wave = wave
		save_game()

func increment_games_played():
	save_data.progress.games_played += 1
	save_game()

# Unlocks
func unlock_weapon(weapon_name: String):
	if not weapon_name in save_data.unlocks.weapons:
		save_data.unlocks.weapons.append(weapon_name)
		save_game()

func is_weapon_unlocked(weapon_name: String) -> bool:
	return weapon_name in save_data.unlocks.weapons

func unlock_ending(ending_name: String):
	if not ending_name in save_data.unlocks.endings:
		save_data.unlocks.endings.append(ending_name)
		save_game()

func is_ending_unlocked(ending_name: String) -> bool:
	return ending_name in save_data.unlocks.endings

# Settings
func set_master_volume(value: float):
	save_data.settings.master_volume = clamp(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	save_game()

func set_music_volume(value: float):
	save_data.settings.music_volume = clamp(value, 0.0, 1.0)
	# Apply to music bus
	save_game()

func set_sfx_volume(value: float):
	save_data.settings.sfx_volume = clamp(value, 0.0, 1.0)
	# Apply to SFX bus
	save_game()

func set_difficulty(difficulty: String):
	save_data.settings.difficulty = difficulty
	save_game()

# Statistics
func get_total_kills() -> int:
	return save_data.player.total_kills

func get_total_playtime() -> float:
	return save_data.player.total_playtime

func get_playtime_formatted() -> String:
	var total_seconds = int(save_data.player.total_playtime)
	var hours = total_seconds / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_kiku_rescues() -> int:
	return save_data.progress.kiku_rescues

func get_permanent_hp() -> int:
	return 100 + (save_data.player.permanent_hp_upgrades * 50)

func get_permanent_lucky() -> float:
	return 1.0 + (save_data.player.permanent_luck_upgrades * 0.3)

func get_permanent_mana() -> int:
	return 50 + (save_data.player.permanent_mana_threshold * 25)

# === SAVE SLOT SYSTEM ===

## Check if any save slot has data
func has_any_save() -> bool:
	for i in range(1, TOTAL_SLOTS + 1):
		if FileAccess.file_exists(get_slot_path(i)):
			return true
	return false

## Get the file path for a specific slot
func get_slot_path(slot: int) -> String:
	return "user://save_slot_%d.dat" % slot

## Load save data from a specific slot
func load_slot(slot: int) -> Dictionary:
	var path = get_slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}

	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return data
	return {}

## Save to a specific slot
func save_to_slot(slot: int):
	var path = get_slot_path(slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("Game saved to slot ", slot)

## Create a new save in the current slot
func create_new_save():
	# Reset save_data to defaults
	save_data = {
		"version": SAVE_VERSION,
		"level": 1,
		"playtime": 0.0,
		"current_biome": "Starting Forest",
		"player": {
			"permanent_hp_upgrades": 0,
			"permanent_luck_upgrades": 0,
			"permanent_mana_threshold": 0,
			"total_kills": 0,
			"total_playtime": 0.0,
		},
		"progress": {
			"blood_temple_cleared": false,
			"darkland_cleared": false,
			"kiku_rescues": 0,
			"highest_wave": 0,
			"games_played": 0,
		},
		"unlocks": {
			"weapons": [],
			"endings": [],
			"new_game_plus": false
		},
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.7,
			"sfx_volume": 1.0,
			"joystick_size": 100,
			"button_size": 100,
			"touch_sensitivity": 1.0,
			"button_opacity": 100,
			"fps_counter": false,
			"screen_shake": true,
			"blood_effects": true,
			"pause_mode": 0,
			"damage_numbers": true,
			"auto_pause": true,
			"colorblind_mode": 0,
			"text_size": 100,
			"high_contrast": false
		}
	}
	save_to_slot(current_slot)
