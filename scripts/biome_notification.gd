extends Label

var biome_generator: BiomeGenerator

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
	
	# Update text and color
	text = "Entered: " + new_biome.name
	modulate = new_biome.color
	
	# Animate
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BOUNCE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.2)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Wait
	tween.tween_interval(2.0)
	
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
