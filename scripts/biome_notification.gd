extends Label

var biome_generator: BiomeGenerator
var visited_biomes: Dictionary = {}  # Track which biomes have been visited
var current_tween: Tween = null  # Track current tween

func _ready():
	# Hide initially
	modulate = Color(1, 1, 1, 0)  # White color, transparent

	# Wait for biome generator
	await get_tree().process_frame
	biome_generator = get_tree().get_first_node_in_group("biome_generator")

	if biome_generator:
		biome_generator.biome_changed.connect(_on_biome_changed)
		print("BiomeNotification ready!")

func _on_biome_changed(old_biome, new_biome):
	if not new_biome:
		return

	# Check if this biome has been visited before
	if visited_biomes.has(new_biome.type):
		print("Already visited ", new_biome.name, " - skipping notification")
		return

	# Mark as visited
	visited_biomes[new_biome.type] = true
	print("First time entering ", new_biome.name, " - showing notification")

	# Kill old tween if exists
	if current_tween:
		current_tween.kill()
		print("Killed old tween")

	# Update text
	text = "Entered: " + new_biome.name
	print("Updated text to: ", text)

	# Set color (RGB only, keep alpha at 0 for fade in)
	var biome_color = new_biome.color
	modulate = Color(biome_color.r, biome_color.g, biome_color.b, 0.0)
	print("Set color to: ", biome_color)

	# Animate
	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_BOUNCE)
	current_tween.set_ease(Tween.EASE_OUT)

	# Fade in
	current_tween.tween_property(self, "modulate:a", 1.0, 0.3)
	current_tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	current_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

	# Wait 5 seconds
	current_tween.tween_interval(5.0)

	# Fade out
	current_tween.tween_property(self, "modulate:a", 0.0, 0.5)

	print("Tween started - will hide after 5.7 seconds")
