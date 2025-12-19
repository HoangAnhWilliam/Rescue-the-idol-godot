extends CanvasLayer
## Loading Screen
##
## Features:
## - Shows only if loading takes > 0.5 seconds
## - Displays rotating icon, progress bar, random tip
## - Gameplay hints from predefined list

@onready var progress_bar: ProgressBar = $Content/ProgressBar
@onready var tip_label: Label = $Content/TipLabel
@onready var loading_icon: ColorRect = $Content/LoadingIcon

var tips: Array[String] = [
	"💡 Bosses have 3 phases!",
	"✨ Collect XP orbs to level up",
	"🎵 Each biome has unique music",
	"⏱️ Kiku companion lasts 10 minutes",
	"⚔️ Try all 8 weapons!",
	"👹 Watch for boss phase transitions",
	"💰 Gold is kept even after death",
	"🎰 Upgrade weapons at the ATM",
	"🗡️ Some weapons are better vs bosses",
	"🗺️ Explore all 5 biomes",
	"🔮 Rescue Kiku from the Blood Temple",
	"👻 Dark Kiku boss guards the temple",
	"💀 Despair Kiku is the final challenge",
	"📺 Pam Tung Ken loves anime",
	"🔥 Fire Dragon has three forms",
	"🩸 Vampire Lord can heal in blood pools"
]

var loading_time: float = 0.0
var min_display_time: float = 0.5  # Minimum display time

func _ready():
	# Random tip
	tip_label.text = tips[randi() % tips.size()]

	# Start loading animation
	if loading_icon:
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(loading_icon, "rotation", TAU, 2.0)

	# Start loading
	progress_bar.value = 0

func _process(delta):
	loading_time += delta

	# Simulate loading (or use real progress)
	progress_bar.value += delta * 100

	# Check if done and minimum time passed
	if progress_bar.value >= 100 and loading_time >= min_display_time:
		finish_loading()

func finish_loading():
	queue_free()

func set_progress(value: float):
	"""Call this from external code to update progress"""
	progress_bar.value = value
