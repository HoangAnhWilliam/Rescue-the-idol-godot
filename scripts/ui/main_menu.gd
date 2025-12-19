extends CanvasLayer
## Main Menu - Entry point for the game
##
## Features:
## - Title with glow animation
## - New Game / Continue / Settings / Credits / Quit buttons
## - Continue button only visible if save exists
## - Menu music playback

# Node references
@onready var title = $TitleContainer/GameTitle
@onready var subtitle = $TitleContainer/Subtitle
@onready var new_game_btn = $MenuButtons/NewGameButton
@onready var continue_btn = $MenuButtons/ContinueButton
@onready var settings_btn = $MenuButtons/SettingsButton
@onready var credits_btn = $MenuButtons/CreditsButton
@onready var quit_btn = $MenuButtons/QuitButton
@onready var animation = $TitleContainer/TitleAnimation

func _ready():
	# Play menu music
	if AudioManager:
		AudioManager.play_music("menu")

	# Title animation (fade in + glow)
	play_title_animation()

	# Check for existing save files
	check_save_files()

	# Connect button signals
	new_game_btn.pressed.connect(_on_new_game_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	credits_btn.pressed.connect(_on_credits_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)

	# Add button sounds
	connect_button_sounds()

	print("Main Menu loaded")

func play_title_animation():
	# Fade in title
	title.modulate.a = 0.0
	subtitle.modulate.a = 0.0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(title, "modulate:a", 1.0, 1.5)
	tween.tween_property(subtitle, "modulate:a", 1.0, 1.5)

	# Start glow animation after fade in
	await tween.finished
	if animation:
		animation.play("title_glow")

func check_save_files():
	var has_save = false

	if SaveSystem:
		# Check if any save slot has data
		has_save = SaveSystem.has_any_save()

	# Show/hide CONTINUE button
	continue_btn.visible = has_save

	if has_save:
		print("Save file detected - CONTINUE button visible")
	else:
		print("No save file - CONTINUE button hidden")

func connect_button_sounds():
	# Add to group for easy access
	for button in [new_game_btn, continue_btn, settings_btn, credits_btn, quit_btn]:
		button.add_to_group("menu_buttons")
		button.mouse_entered.connect(func():
			if AudioManager:
				AudioManager.play_sfx("button_hover")
		)
		button.pressed.connect(func():
			if AudioManager:
				AudioManager.play_sfx("button_click")
		)

# Button callbacks
func _on_new_game_pressed():
	show_save_slot_selection(true)  # true = new game

func _on_continue_pressed():
	show_save_slot_selection(false)  # false = continue

func _on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/settings_menu.tscn")

func _on_credits_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/credits.tscn")

func _on_quit_pressed():
	get_tree().quit()

func show_save_slot_selection(is_new_game: bool):
	var save_slot_scene = load("res://scenes/ui/save_slot_selection.tscn")
	if save_slot_scene:
		var save_slot_menu = save_slot_scene.instantiate()
		save_slot_menu.is_new_game = is_new_game
		add_child(save_slot_menu)
	else:
		print("ERROR: Could not load save_slot_selection.tscn")
