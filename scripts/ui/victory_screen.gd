extends CanvasLayer
## Victory Screen
##
## Features:
## - Shows when player defeats final boss (Despair Kiku)
## - Displays final stats
## - Unlocks New Game+ mode
## - Credits / New Game+ / Main Menu buttons

@onready var credits_btn: Button = $Panel/VBox/CreditsButton
@onready var new_game_plus_btn: Button = $Panel/VBox/NewGamePlusButton
@onready var main_menu_btn: Button = $Panel/VBox/MainMenuButton

@onready var time_stat: Label = $Panel/VBox/StatsContainer/TimeStat
@onready var kills_stat: Label = $Panel/VBox/StatsContainer/KillsStat
@onready var level_stat: Label = $Panel/VBox/StatsContainer/LevelStat

var stats: Dictionary = {}

func _ready():
	# Play victory music
	if AudioManager:
		AudioManager.play_music("victory")

	# Display stats
	display_victory_stats()

	# Unlock New Game+
	if SaveSystem:
		if not "new_game_plus" in SaveSystem.save_data.unlocks:
			SaveSystem.save_data.unlocks.new_game_plus = true
		else:
			SaveSystem.save_data.unlocks.new_game_plus = true
		SaveSystem.save_game()

	# Connect buttons
	credits_btn.pressed.connect(_on_credits_pressed)
	new_game_plus_btn.pressed.connect(_on_new_game_plus_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)

	print("Victory screen displayed")

func set_stats(game_stats: Dictionary):
	stats = game_stats

func display_victory_stats():
	time_stat.text = "⏱️ Total Time: %s" % format_time(stats.get("time", 0))
	kills_stat.text = "💀 Total Kills: %d" % stats.get("kills", 0)
	level_stat.text = "⭐ Final Level: %d" % stats.get("level", 1)

func format_time(seconds: float) -> String:
	var m = int(seconds / 60)
	var s = int(seconds) % 60
	return "%d:%02d" % [m, s]

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")

func _on_new_game_plus_pressed():
	# Start New Game+ (harder difficulty, keep some stats)
	if SaveSystem:
		SaveSystem.save_data.game_mode = "new_game_plus"
		SaveSystem.save_game()

	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_main_menu_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
