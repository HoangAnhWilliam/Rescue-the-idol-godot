extends CanvasLayer
## Credits Screen
##
## Features:
## - Auto-scrolling credits
## - Music playback
## - Skip button (any key/click skips)
## - Returns to main menu after finishing

@onready var scroll: ScrollContainer = $ScrollContainer
@onready var credits_text: VBoxContainer = $ScrollContainer/CreditsText
@onready var skip_btn: Button = $SkipButton

var scroll_speed: float = 30.0  # pixels per second
var scroll_position: float = 0.0
var is_scrolling: bool = true

func _ready():
	# Play credits music (golden.ogg)
	if AudioManager:
		AudioManager.play_music("golden")

	# Setup credits content
	setup_credits_text()

	# Start at bottom
	scroll.scroll_vertical = 0

	# Connect skip button
	skip_btn.pressed.connect(_on_skip_pressed)

	print("Credits screen started")

func setup_credits_text():
	# Clear existing
	for child in credits_text.get_children():
		child.queue_free()

	# Add credits content
	add_credit_line("", 60)  # Top spacing

	add_credit_line("KIKU'S DESPAIR", 48, true)
	add_credit_line("Melody of the Dead", 32)
	add_credit_line("", 40)

	add_credit_line("DEVELOPED BY", 28, true)
	add_credit_line("Hoang Anh", 24)
	add_credit_line("", 40)

	add_credit_line("MUSIC", 28, true)
	add_credit_line("Hoang Anh", 24)
	add_credit_line("Generated with Suno AI", 20)
	add_credit_line("", 40)

	add_credit_line("SOUND EFFECTS", 28, true)
	add_credit_line("Freesound.org", 24)
	add_credit_line("", 20)
	add_credit_line("Specific attributions:", 18)
	add_credit_line("dland, spookymodem, Nox_Sound,", 16)
	add_credit_line("ProjectsU012, Leszek_Szary,", 16)
	add_credit_line("Cabeeno Rossley, and others", 16)
	add_credit_line("", 40)

	add_credit_line("SPECIAL THANKS", 28, true)
	add_credit_line("Claude (Anthropic)", 24)
	add_credit_line("For invaluable development assistance", 20)
	add_credit_line("", 20)
	add_credit_line("Godot Engine", 24)
	add_credit_line("Open source game engine", 20)
	add_credit_line("", 40)

	add_credit_line("THANK YOU FOR PLAYING!", 32, true)
	add_credit_line("", 100)  # Bottom spacing

func add_credit_line(text: String, font_size: int = 20, bold: bool = false):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Set font size
	label.add_theme_font_size_override("font_size", font_size)

	# Bold effect
	if bold:
		label.modulate = Color(1.2, 1.2, 1.2)

	credits_text.add_child(label)

func _process(delta):
	if is_scrolling:
		# Auto-scroll
		scroll_position += scroll_speed * delta
		scroll.scroll_vertical = int(scroll_position)

		# Check if reached end
		var max_scroll = credits_text.size.y - scroll.size.y
		if scroll.scroll_vertical >= max_scroll:
			# Finished scrolling
			is_scrolling = false
			await get_tree().create_timer(3.0).timeout
			_on_skip_pressed()

func _on_skip_pressed():
	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func _input(event):
	# Any key/click to skip
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed():
			# Set as handled BEFORE changing scene to avoid null viewport error
			if is_inside_tree():
				get_viewport().set_input_as_handled()
			_on_skip_pressed()
