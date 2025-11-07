extends ColorRect

var biome_generator: BiomeGenerator
var tween: Tween

func _ready():
	# Set to back
	z_index = -10
	
	# Wait for biome generator
	await get_tree().process_frame
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	
	if biome_generator:
		biome_generator.biome_changed.connect(_on_biome_changed)
		
		# Set initial color
		var current = biome_generator.get_current_biome()
		if current:
			color = current.color.darkened(0.7)  # Tối hơn để không chói
		
		print("BiomeBackground ready!")

func _on_biome_changed(old_biome, new_biome):
	if not new_biome:
		return
	
	# Smooth color transition
	var target_color = new_biome.color.darkened(0.7)
	
	# Stop old tween
	if tween:
		tween.kill()
	
	# Create new tween
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "color", target_color, 1.0)
	
	print("Background changing to: ", new_biome.name)
