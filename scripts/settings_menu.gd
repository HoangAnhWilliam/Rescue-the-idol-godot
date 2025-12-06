extends CanvasLayer
## Settings Menu with Audio Volume Controls
##
## This menu provides sliders for adjusting:
## - Master Volume
## - Music Volume
## - SFX Volume
##
## Settings are automatically saved to SaveSystem.

# UI References (assign these in the scene)
@onready var master_slider: HSlider = $Panel/VBoxContainer/MasterVolumeSlider
@onready var music_slider: HSlider = $Panel/VBoxContainer/MusicVolumeSlider
@onready var sfx_slider: HSlider = $Panel/VBoxContainer/SFXVolumeSlider
@onready var close_button: Button = $Panel/CloseButton

func _ready():
	print("=== SettingsMenu Init ===")

	# Hide by default
	hide()

	# Connect slider signals (if nodes exist)
	if master_slider:
		master_slider.value_changed.connect(_on_master_volume_changed)
		print("✓ Master volume slider connected")

	if music_slider:
		music_slider.value_changed.connect(_on_music_volume_changed)
		print("✓ Music volume slider connected")

	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_volume_changed)
		print("✓ SFX volume slider connected")

	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		print("✓ Close button connected")

	# Load current volume settings
	load_current_volumes()

	print("✓ SettingsMenu ready!")

## Load current volume values from AudioManager
func load_current_volumes():
	if not AudioManager:
		push_warning("AudioManager not found!")
		return

	# Set slider values (0-100 range)
	if master_slider:
		master_slider.value = AudioManager.master_volume * 100.0

	if music_slider:
		music_slider.value = AudioManager.music_volume * 100.0

	if sfx_slider:
		sfx_slider.value = AudioManager.sfx_volume * 100.0

	print("Loaded volume settings:")
	print("  Master: ", AudioManager.master_volume)
	print("  Music: ", AudioManager.music_volume)
	print("  SFX: ", AudioManager.sfx_volume)

## Show the settings menu
func show_menu():
	# ← AUDIO: Play menu open sound
	AudioManager.play_sfx("menu_open")

	# Reload current volumes in case they changed
	load_current_volumes()

	# Show menu
	show()

	# Pause game (optional - remove if you don't want pause)
	get_tree().paused = true

## Hide the settings menu
func hide_menu():
	# ← AUDIO: Play menu close sound
	AudioManager.play_sfx("menu_close")

	# Hide menu
	hide()

	# Resume game
	get_tree().paused = false

# === SLIDER CALLBACKS ===

func _on_master_volume_changed(value: float):
	# Update AudioManager (converts 0-100 to 0.0-1.0)
	AudioManager.set_master_volume(value / 100.0)

	print("Master volume: ", value, "%")

func _on_music_volume_changed(value: float):
	# Update AudioManager
	AudioManager.set_music_volume(value / 100.0)

	print("Music volume: ", value, "%")

func _on_sfx_volume_changed(value: float):
	# Update AudioManager
	AudioManager.set_sfx_volume(value / 100.0)

	# Play test sound
	AudioManager.play_sfx("button_click")

	print("SFX volume: ", value, "%")

func _on_close_pressed():
	# ← AUDIO: Play button click
	AudioManager.play_sfx("button_click")

	hide_menu()

# === INPUT HANDLING ===

func _input(event):
	# Close settings with ESC key
	if event.is_action_pressed("ui_cancel") and visible:
		hide_menu()
		get_viewport().set_input_as_handled()
