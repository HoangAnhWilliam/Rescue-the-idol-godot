extends CanvasLayer
## Pause Menu
##
## Features:
## - Pauses the game when shown
## - Resume / Settings / Main Menu / Quit buttons
## - Auto-saves before returning to menu or quitting

@onready var resume_btn: Button = $Panel/VBox/ResumeButton
@onready var settings_btn: Button = $Panel/VBox/SettingsButton
@onready var main_menu_btn: Button = $Panel/VBox/MainMenuButton
@onready var quit_btn: Button = $Panel/VBox/QuitButton

func _ready():
	# Pause game
	get_tree().paused = true

	# Play menu sound
	if AudioManager:
		AudioManager.play_sfx("menu_open")

	# Connect buttons
	resume_btn.pressed.connect(_on_resume_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	print("Game paused")

func _on_resume_pressed():
	if AudioManager:
		AudioManager.play_sfx("menu_close")

	get_tree().paused = false
	queue_free()

func _on_settings_pressed():
	# Hide gameplay UI elements before opening settings
	hide_gameplay_ui()

	# Open settings as child (maintains pause)
	var settings = load("res://scenes/ui/settings_menu_new.tscn").instantiate()

	# CRITICAL: Settings must run even when game is paused
	settings.process_mode = Node.PROCESS_MODE_ALWAYS

	# Mark that settings was opened from pause menu
	settings.from_pause_menu = true

	# Hide pause menu while settings is open
	visible = false

	# Add settings as child
	add_child(settings)

	# When settings is closed, show pause menu AND gameplay UI again
	settings.tree_exited.connect(func():
		visible = true
		show_gameplay_ui()
		print("Settings closed, pause menu visible again")
	)

func _on_main_menu_pressed():
	# Auto-save before quit
	if SaveSystem:
		SaveSystem.save_game()
		print("Game saved before returning to menu")

	# Unpause
	get_tree().paused = false

	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_quit_pressed():
	# Auto-save before quit
	if SaveSystem:
		SaveSystem.save_game()
		print("Game saved before quitting")

	# Quit
	get_tree().quit()

func _input(event):
	# ESC or Back to resume
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		# Set as handled BEFORE resuming to avoid potential null viewport error
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_on_resume_pressed()

# === GAMEPLAY UI VISIBILITY HELPERS ===

func hide_gameplay_ui():
	"""Hide HUD, Hotbar, and Mobile Controls when settings opens"""
	var main_scene = get_tree().current_scene

	# Hide HUD
	if main_scene.has_node("UI/HUD"):
		main_scene.get_node("UI/HUD").visible = false
		print("HUD hidden")

	# Hide Hotbar
	if main_scene.has_node("UI/HotbarUI"):
		main_scene.get_node("UI/HotbarUI").visible = false
		print("Hotbar hidden")

	# Hide Mobile Controls
	if main_scene.has_node("MobileControls"):
		main_scene.get_node("MobileControls").visible = false
		print("Mobile controls hidden")

func show_gameplay_ui():
	"""Show HUD, Hotbar, and Mobile Controls when settings closes"""
	var main_scene = get_tree().current_scene

	# Show HUD
	if main_scene.has_node("UI/HUD"):
		main_scene.get_node("UI/HUD").visible = true
		print("HUD shown")

	# Show Hotbar
	if main_scene.has_node("UI/HotbarUI"):
		main_scene.get_node("UI/HotbarUI").visible = true
		print("Hotbar shown")

	# Show Mobile Controls
	if main_scene.has_node("MobileControls"):
		main_scene.get_node("MobileControls").visible = true
		print("Mobile controls shown")
