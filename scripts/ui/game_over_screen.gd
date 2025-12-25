extends CanvasLayer
## Game Over Screen
##
## Features:
## - Shows when player dies
## - Displays 11 game statistics
## - Gold is kept after death (roguelite style)
## - Retry or return to main menu

# Stats labels
@onready var time_stat: Label = $Panel/VBox/StatsContainer/TimeStat
@onready var kills_stat: Label = $Panel/VBox/StatsContainer/KillsStat
@onready var level_stat: Label = $Panel/VBox/StatsContainer/LevelStat
@onready var gold_stat: Label = $Panel/VBox/StatsContainer/GoldStat
@onready var wave_stat: Label = $Panel/VBox/StatsContainer/WaveStat
@onready var boss_stat: Label = $Panel/VBox/StatsContainer/BossStat
@onready var damage_dealt_stat: Label = $Panel/VBox/StatsContainer/DamageDealtStat
@onready var damage_taken_stat: Label = $Panel/VBox/StatsContainer/DamageTakenStat
@onready var xp_stat: Label = $Panel/VBox/StatsContainer/XPStat
@onready var weapons_stat: Label = $Panel/VBox/StatsContainer/WeaponsStat
@onready var biome_stat: Label = $Panel/VBox/StatsContainer/BiomeStat

# Buttons
@onready var retry_btn: Button = $Panel/VBox/RetryButton
@onready var main_menu_btn: Button = $Panel/VBox/MainMenuButton

# Stats data
var stats: Dictionary = {}

func _ready():
	# BUG FIX #1: Make sure screen works when paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Play game over music
	if AudioManager:
		AudioManager.play_music("game_over")

	# Display stats
	display_stats()

	# Connect buttons
	retry_btn.pressed.connect(_on_retry_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)

	print("Game Over screen displayed")

func set_stats(game_stats: Dictionary):
	"""Call this before adding to scene tree"""
	stats = game_stats

func display_stats():
	time_stat.text = "⏱️ Time Survived: %s" % format_time(stats.get("time", 0))
	kills_stat.text = "💀 Enemies Killed: %d" % stats.get("kills", 0)
	level_stat.text = "⭐ Level Reached: %d" % stats.get("level", 1)
	gold_stat.text = "💰 Gold Earned: %d (KEPT!)" % stats.get("gold", 0)
	wave_stat.text = "🌊 Highest Wave: %d" % stats.get("wave", 0)
	boss_stat.text = "👹 Bosses Defeated: %s" % get_boss_list(stats.get("bosses", []))
	damage_dealt_stat.text = "⚔️ Damage Dealt: %d" % stats.get("damage_dealt", 0)
	damage_taken_stat.text = "🩸 Damage Taken: %d" % stats.get("damage_taken", 0)
	xp_stat.text = "✨ XP Gained: %d" % stats.get("xp", 0)
	weapons_stat.text = "🗡️ Weapons Used: %s" % get_weapon_list(stats.get("weapons", []))
	biome_stat.text = "🗺️ Biome Reached: %s" % stats.get("biome", "Starting Forest")

func format_time(seconds: float) -> String:
	var m = int(seconds / 60)
	var s = int(seconds) % 60
	return "%d:%02d" % [m, s]

func get_boss_list(bosses: Array) -> String:
	if bosses.is_empty():
		return "None"
	return ", ".join(bosses)

func get_weapon_list(weapons: Array) -> String:
	if weapons.is_empty():
		return "None"
	return ", ".join(weapons)

func _on_retry_pressed():
	print("🔄 RETRY button pressed")

	# BUG FIX #1: Prevent multiple clicks
	retry_btn.disabled = true
	main_menu_btn.disabled = true

	# CRITICAL: Unpause FIRST to avoid freeze
	get_tree().paused = false
	print("▶️ Unpaused game")

	# Stop all audio to prevent conflicts
	if AudioManager:
		# Check if stop_all exists, otherwise just stop music
		if AudioManager.has_method("stop_all"):
			AudioManager.stop_all()
		else:
			# Fallback: stop music manually
			AudioManager.stop_music(0.0)  # Immediate stop, no fade
		print("🔇 Stopped all audio")

	# Small delay to ensure unpause propagates
	await get_tree().create_timer(0.1).timeout

	# Get current scene path for clean reload
	var current_scene = get_tree().current_scene.scene_file_path

	print("🔄 Reloading scene: ", current_scene)

	# Remove game over screen
	queue_free()

	# Reload scene (this will reset everything cleanly)
	var result = get_tree().change_scene_to_file(current_scene)

	if result != OK:
		print("❌ ERROR: Failed to reload scene!")
		# Fallback: reload current scene
		get_tree().reload_current_scene()

func _on_main_menu_pressed():
	print("🏠 Returning to main menu...")

	# Stop all audio first
	if AudioManager:
		if AudioManager.has_method("stop_all"):
			AudioManager.stop_all()
		else:
			AudioManager.stop_music(0.0)
		print("🔇 Stopped all audio")

	# Unpause game before changing scene
	get_tree().paused = false

	# Disable buttons to prevent double-click
	retry_btn.disabled = true
	main_menu_btn.disabled = true

	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
