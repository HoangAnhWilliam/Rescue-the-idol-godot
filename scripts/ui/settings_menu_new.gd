extends CanvasLayer
## Settings Menu with 6 tabs
##
## Tabs:
## 1. Audio - Volume controls
## 2. Controls - Mobile control customization
## 3. Graphics - Visual options
## 4. Gameplay - Game behavior
## 5. Accessibility - Accessibility features
## 6. About - Game info + Reset

# Flag to track if opened from pause menu
var from_pause_menu: bool = false

# Audio tab
@onready var master_slider: HSlider = $Panel/VBox/TabContainer/Audio/MasterVolume/Slider
@onready var master_value: Label = $Panel/VBox/TabContainer/Audio/MasterVolume/ValueLabel
@onready var master_test: Button = $Panel/VBox/TabContainer/Audio/MasterVolume/TestButton

@onready var music_slider: HSlider = $Panel/VBox/TabContainer/Audio/MusicVolume/Slider
@onready var music_value: Label = $Panel/VBox/TabContainer/Audio/MusicVolume/ValueLabel
@onready var music_test: Button = $Panel/VBox/TabContainer/Audio/MusicVolume/TestButton

@onready var sfx_slider: HSlider = $Panel/VBox/TabContainer/Audio/SFXVolume/Slider
@onready var sfx_value: Label = $Panel/VBox/TabContainer/Audio/SFXVolume/ValueLabel
@onready var sfx_test: Button = $Panel/VBox/TabContainer/Audio/SFXVolume/TestButton

# Controls tab
@onready var joystick_size: HSlider = $Panel/VBox/TabContainer/Controls/JoystickSize/Slider
@onready var joystick_value: Label = $Panel/VBox/TabContainer/Controls/JoystickSize/ValueLabel

@onready var button_size: HSlider = $Panel/VBox/TabContainer/Controls/ButtonSize/Slider
@onready var button_value: Label = $Panel/VBox/TabContainer/Controls/ButtonSize/ValueLabel

@onready var touch_sens: HSlider = $Panel/VBox/TabContainer/Controls/TouchSensitivity/Slider
@onready var touch_value: Label = $Panel/VBox/TabContainer/Controls/TouchSensitivity/ValueLabel

@onready var button_opacity: HSlider = $Panel/VBox/TabContainer/Controls/ButtonOpacity/Slider
@onready var opacity_value: Label = $Panel/VBox/TabContainer/Controls/ButtonOpacity/ValueLabel

# Graphics tab
@onready var fps_counter: CheckBox = $Panel/VBox/TabContainer/Graphics/FPSCounter/CheckBox
@onready var screen_shake: CheckBox = $Panel/VBox/TabContainer/Graphics/ScreenShake/CheckBox
@onready var blood_effects: CheckBox = $Panel/VBox/TabContainer/Graphics/BloodEffects/CheckBox

# Gameplay tab
@onready var pause_mode: OptionButton = $Panel/VBox/TabContainer/Gameplay/PauseMode/OptionButton
@onready var damage_numbers: CheckBox = $Panel/VBox/TabContainer/Gameplay/DamageNumbers/CheckBox
@onready var auto_pause: CheckBox = $Panel/VBox/TabContainer/Gameplay/AutoPause/CheckBox

# Accessibility tab
@onready var colorblind_mode: OptionButton = $Panel/VBox/TabContainer/Accessibility/ColorblindMode/OptionButton
@onready var text_size: HSlider = $Panel/VBox/TabContainer/Accessibility/TextSize/Slider
@onready var text_size_value: Label = $Panel/VBox/TabContainer/Accessibility/TextSize/ValueLabel
@onready var high_contrast: CheckBox = $Panel/VBox/TabContainer/Accessibility/HighContrast/CheckBox

# Buttons
@onready var back_btn: Button = $Panel/VBox/BackButton
@onready var reset_btn: Button = $Panel/VBox/TabContainer/About/ResetButton

func _ready():
	# Load current settings
	load_settings()

	# Connect audio sliders
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

	# Connect test buttons
	master_test.pressed.connect(func(): AudioManager.play_sfx("button_click") if AudioManager else null)
	music_test.pressed.connect(func(): AudioManager.play_music("menu") if AudioManager else null)
	sfx_test.pressed.connect(func(): AudioManager.play_sfx("hit_impact") if AudioManager else null)

	# Connect controls sliders
	joystick_size.value_changed.connect(_on_joystick_size_changed)
	button_size.value_changed.connect(_on_button_size_changed)
	touch_sens.value_changed.connect(_on_touch_sens_changed)
	button_opacity.value_changed.connect(_on_button_opacity_changed)

	# Connect graphics checkboxes
	fps_counter.toggled.connect(_on_fps_counter_toggled)
	screen_shake.toggled.connect(_on_screen_shake_toggled)
	blood_effects.toggled.connect(_on_blood_effects_toggled)

	# Connect gameplay
	pause_mode.item_selected.connect(_on_pause_mode_changed)
	damage_numbers.toggled.connect(_on_damage_numbers_toggled)
	auto_pause.toggled.connect(_on_auto_pause_toggled)

	# Connect accessibility
	colorblind_mode.item_selected.connect(_on_colorblind_mode_changed)
	text_size.value_changed.connect(_on_text_size_changed)
	high_contrast.toggled.connect(_on_high_contrast_toggled)

	# Connect buttons
	back_btn.pressed.connect(_on_back_pressed)
	reset_btn.pressed.connect(_on_reset_pressed)

	print("Settings Menu loaded")

func load_settings():
	if not SaveSystem:
		print("WARNING: SaveSystem not found, using defaults")
		return

	# Ensure settings dict exists
	if not "settings" in SaveSystem.save_data:
		SaveSystem.save_data.settings = {}

	var settings = SaveSystem.save_data.settings

	# Audio (from AudioManager)
	if AudioManager:
		master_slider.value = AudioManager.master_volume * 100
		music_slider.value = AudioManager.music_volume * 100
		sfx_slider.value = AudioManager.sfx_volume * 100

	# Controls
	joystick_size.value = settings.get("joystick_size", 100)
	button_size.value = settings.get("button_size", 100)
	touch_sens.value = settings.get("touch_sensitivity", 1.0)
	button_opacity.value = settings.get("button_opacity", 100)

	# Graphics
	fps_counter.button_pressed = settings.get("fps_counter", false)
	screen_shake.button_pressed = settings.get("screen_shake", true)
	blood_effects.button_pressed = settings.get("blood_effects", true)

	# Gameplay
	pause_mode.selected = settings.get("pause_mode", 0)  # 0=freeze, 1=slow-mo
	damage_numbers.button_pressed = settings.get("damage_numbers", true)
	auto_pause.button_pressed = settings.get("auto_pause", true)

	# Accessibility
	colorblind_mode.selected = settings.get("colorblind_mode", 0)
	text_size.value = settings.get("text_size", 100)
	high_contrast.button_pressed = settings.get("high_contrast", false)

	# Update value labels
	update_all_value_labels()

func update_all_value_labels():
	master_value.text = "%d%%" % master_slider.value
	music_value.text = "%d%%" % music_slider.value
	sfx_value.text = "%d%%" % sfx_slider.value
	joystick_value.text = "%d%%" % joystick_size.value
	button_value.text = "%d%%" % button_size.value
	touch_value.text = "%.1fx" % touch_sens.value
	opacity_value.text = "%d%%" % button_opacity.value
	text_size_value.text = "%d%%" % text_size.value

func save_settings():
	if not SaveSystem:
		return

	var settings = SaveSystem.save_data.settings

	# Controls
	settings.joystick_size = joystick_size.value
	settings.button_size = button_size.value
	settings.touch_sensitivity = touch_sens.value
	settings.button_opacity = button_opacity.value

	# Graphics
	settings.fps_counter = fps_counter.button_pressed
	settings.screen_shake = screen_shake.button_pressed
	settings.blood_effects = blood_effects.button_pressed

	# Gameplay
	settings.pause_mode = pause_mode.selected
	settings.damage_numbers = damage_numbers.button_pressed
	settings.auto_pause = auto_pause.button_pressed

	# Accessibility
	settings.colorblind_mode = colorblind_mode.selected
	settings.text_size = text_size.value
	settings.high_contrast = high_contrast.button_pressed

	SaveSystem.save_game()

# Audio callbacks
func _on_master_changed(value: float):
	if AudioManager:
		AudioManager.set_master_volume(value / 100.0)
	master_value.text = "%d%%" % value

func _on_music_changed(value: float):
	if AudioManager:
		AudioManager.set_music_volume(value / 100.0)
	music_value.text = "%d%%" % value

func _on_sfx_changed(value: float):
	if AudioManager:
		AudioManager.set_sfx_volume(value / 100.0)
	sfx_value.text = "%d%%" % value

# Controls callbacks
func _on_joystick_size_changed(value: float):
	joystick_value.text = "%d%%" % value
	save_settings()

func _on_button_size_changed(value: float):
	button_value.text = "%d%%" % value
	save_settings()

func _on_touch_sens_changed(value: float):
	touch_value.text = "%.1fx" % value
	save_settings()

func _on_button_opacity_changed(value: float):
	opacity_value.text = "%d%%" % value
	save_settings()

# Graphics callbacks
func _on_fps_counter_toggled(enabled: bool):
	save_settings()

func _on_screen_shake_toggled(enabled: bool):
	save_settings()

func _on_blood_effects_toggled(enabled: bool):
	save_settings()

# Gameplay callbacks
func _on_pause_mode_changed(index: int):
	save_settings()

func _on_damage_numbers_toggled(enabled: bool):
	save_settings()

func _on_auto_pause_toggled(enabled: bool):
	save_settings()

# Accessibility callbacks
func _on_colorblind_mode_changed(index: int):
	save_settings()

func _on_text_size_changed(value: float):
	text_size_value.text = "%d%%" % value
	save_settings()

func _on_high_contrast_toggled(enabled: bool):
	save_settings()

# Button callbacks
func _on_back_pressed():
	save_settings()

	if from_pause_menu:
		# Opened from pause menu - just close and show pause menu again
		print("Closing settings, returning to pause menu")
		queue_free()
		# Pause menu will become visible automatically when settings is removed
	else:
		# Opened from main menu - return to main menu
		print("Closing settings, returning to main menu")
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _on_reset_pressed():
	# Show confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to reset ALL save data?\nThis cannot be undone!"
	dialog.ok_button_text = "Reset Everything"
	dialog.cancel_button_text = "Cancel"

	dialog.confirmed.connect(func():
		if SaveSystem:
			SaveSystem.reset_save()
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)

	add_child(dialog)
	dialog.popup_centered()
