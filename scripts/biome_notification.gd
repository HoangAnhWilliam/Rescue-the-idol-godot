extends Label

var biome_generator: BiomeGenerator
var visited_biomes: Dictionary = {}  # Track which biomes have been visited

func _ready():
	# Hide initially
	modulate.a = 0.0

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

	# Update text with colored text
	text = "Entered: " + new_biome.name

	# Set text color based on biome
	modulate = new_biome.color

	# Animate
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)

	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)

	# Wait 5 seconds instead of 2
	tween.tween_interval(5.0)

	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
