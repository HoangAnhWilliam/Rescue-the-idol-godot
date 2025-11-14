extends Node2D
class_name BiomeGenerator

# Biome types
enum BiomeType {
	STARTING_FOREST,
	DESERT_WASTELAND,
	FROZEN_TUNDRA,
	VOLCANIC_DARKLANDS,
	BLOOD_TEMPLE,
	TRANSITION  # Vùng chuyển tiếp giữa các biomes
}

# Biome data
class BiomeData:
	var name: String
	var type: BiomeType
	var color: Color
	var enemy_spawn_multiplier: float
	var special_effects: Array[String]
	var temperature: float  # -1.0 to 1.0 (cold to hot)
	var moisture: float     # -1.0 to 1.0 (dry to wet)
	
	func _init(p_name: String, p_type: BiomeType, p_color: Color, p_temp: float, p_moist: float):
		name = p_name
		type = p_type
		color = p_color
		temperature = p_temp
		moisture = p_moist
		enemy_spawn_multiplier = 1.0
		special_effects = []

# Generation settings
@export var seed_value: int = 0  # 0 = random seed
@export var chunk_size: float = 500.0  # Size of each biome chunk
@export var noise_scale: float = 0.0008  # Lower = bigger biomes (reduced for larger biomes)
@export var temperature_scale: float = 0.0006  # Reduced for larger temperature zones
@export var moisture_scale: float = 0.0008  # Reduced for larger moisture zones

# Noise generators
var temperature_noise: FastNoiseLite
var moisture_noise: FastNoiseLite
var variation_noise: FastNoiseLite

# Biome definitions
var biome_definitions: Dictionary = {}
var current_biome: BiomeData = null

# Cache system
var biome_cache: Dictionary = {}  # Vector2i -> BiomeData
var cache_radius: int = 5  # Cache chunks around player

# References
var player: CharacterBody2D

# ATM spawning
var atm_scene: PackedScene = preload("res://scenes/atm/weapon_atm.tscn")
var spawned_atms: Array[Node2D] = []

# Signals
signal biome_changed(old_biome: BiomeData, new_biome: BiomeData)
signal entered_boss_zone(biome_type: BiomeType)

func _ready():
	print("=== BiomeGenerator Init ===")
	initialize_noise()
	initialize_biomes()

	# Wait for player
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if player:
		print("✓ Player found")
		current_biome = get_biome_at_position(player.global_position)
		print("Starting biome: ", current_biome.name)
		print("Seed: ", seed_value)

		# Spawn ATMs across the world
		spawn_atms()
	else:
		print("ERROR: No player found!")

func _process(_delta):
	if not player:
		return
	
	update_current_biome()
	update_cache()

func initialize_noise():
	# Generate or use provided seed
	if seed_value == 0:
		seed_value = randi()
	
	print("World Seed: ", seed_value)
	
	# Temperature noise (hot/cold regions)
	temperature_noise = FastNoiseLite.new()
	temperature_noise.seed = seed_value
	temperature_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	temperature_noise.frequency = temperature_scale
	temperature_noise.fractal_octaves = 4
	
	# Moisture noise (wet/dry regions)
	moisture_noise = FastNoiseLite.new()
	moisture_noise.seed = seed_value + 1000
	moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	moisture_noise.frequency = moisture_scale
	moisture_noise.fractal_octaves = 3
	
	# Variation noise (adds randomness)
	variation_noise = FastNoiseLite.new()
	variation_noise.seed = seed_value + 2000
	variation_noise.noise_type = FastNoiseLite.TYPE_CELLULAR
	variation_noise.frequency = noise_scale * 2
	
	print("✓ Noise initialized")

func initialize_biomes():
	# Starting Forest (Moderate temp, moderate moisture)
	var forest = BiomeData.new(
		"Starting Forest",
		BiomeType.STARTING_FOREST,
		Color(0.2, 0.8, 0.3),
		0.0,   # temperature: moderate
		0.0    # moisture: moderate
	)
	forest.enemy_spawn_multiplier = 1.0
	biome_definitions[BiomeType.STARTING_FOREST] = forest
	
	# Desert Wasteland (Hot, dry)
	var desert = BiomeData.new(
		"Desert Wasteland",
		BiomeType.DESERT_WASTELAND,
		Color(0.9, 0.8, 0.4),
		0.7,   # temperature: hot
		-0.7   # moisture: dry
	)
	desert.enemy_spawn_multiplier = 1.3
	desert.special_effects.append("sandstorm")
	biome_definitions[BiomeType.DESERT_WASTELAND] = desert
	
	# Frozen Tundra (Cold, dry)
	var tundra = BiomeData.new(
		"Frozen Tundra",
		BiomeType.FROZEN_TUNDRA,
		Color(0.7, 0.9, 1.0),
		-0.8,  # temperature: very cold
		-0.3   # moisture: somewhat dry
	)
	tundra.enemy_spawn_multiplier = 1.5
	tundra.special_effects.append("snow") 
	tundra.special_effects.append("slow_effect")
	biome_definitions[BiomeType.FROZEN_TUNDRA] = tundra
	
	# Volcanic Darklands (Very hot, dry)
	var volcanic = BiomeData.new(
		"Volcanic Darklands",
		BiomeType.VOLCANIC_DARKLANDS,
		Color(1.0, 0.3, 1.0),
		1.0,   # temperature: extreme heat
		-0.9   # moisture: very dry
	)
	volcanic.enemy_spawn_multiplier = 2.0
	volcanic.special_effects.append("lava_pools") 
	volcanic.special_effects.append("fire_damage")
	biome_definitions[BiomeType.VOLCANIC_DARKLANDS] = volcanic
	
	# Blood Temple (Cold, wet - cursed lands)
	var temple = BiomeData.new(
		"Blood Temple",
		BiomeType.BLOOD_TEMPLE,
		Color(0.7, 0.1, 0.2),
		-0.5,  # temperature: cold
		0.8    # moisture: wet (blood rain)
	)
	temple.enemy_spawn_multiplier = 2.5
	temple.special_effects.append("blood_rain")
	temple.special_effects.append("curse")
	biome_definitions[BiomeType.BLOOD_TEMPLE] = temple
	
	print("✓ Initialized ", biome_definitions.size(), " biome types")

func get_biome_at_position(pos: Vector2) -> BiomeData:
	# Check cache first
	var chunk_pos = world_to_chunk(pos)
	if biome_cache.has(chunk_pos):
		return biome_cache[chunk_pos]
	
	# Generate biome for this position
	var temp = temperature_noise.get_noise_2dv(pos)
	var moist = moisture_noise.get_noise_2dv(pos)
	var variation = variation_noise.get_noise_2dv(pos) * 0.3
	
	# Starting area protection (spawn always in forest) - Smaller to allow other biomes to be larger
	var distance_from_spawn = pos.length()
	if distance_from_spawn < 600.0:
		var biome = biome_definitions[BiomeType.STARTING_FOREST]
		biome_cache[chunk_pos] = biome
		return biome
	
	# Add variation to noise
	temp += variation
	moist += variation
	
	# Determine biome based on temperature and moisture
	var biome_type = determine_biome_type(temp, moist)
	var biome = biome_definitions[biome_type]
	
	# Cache it
	biome_cache[chunk_pos] = biome
	
	return biome

func determine_biome_type(temperature: float, moisture: float) -> BiomeType:
	# Temperature ranges:
	# Very cold: < -0.6
	# Cold: -0.6 to -0.2
	# Moderate: -0.2 to 0.2
	# Hot: 0.2 to 0.6
	# Very hot: > 0.6
	
	# Moisture ranges:
	# Very dry: < -0.6
	# Dry: -0.6 to -0.2
	# Moderate: -0.2 to 0.2
	# Wet: 0.2 to 0.6
	# Very wet: > 0.6
	
	# Volcanic Darklands (extreme heat, very dry)
	if temperature > 0.7 and moisture < -0.5:
		return BiomeType.VOLCANIC_DARKLANDS
	
	# Desert Wasteland (hot, dry)
	if temperature > 0.3 and moisture < -0.3:
		return BiomeType.DESERT_WASTELAND
	
	# Frozen Tundra (very cold)
	if temperature < -0.5:
		return BiomeType.FROZEN_TUNDRA
	
	# Blood Temple (cold, wet - rare combination)
	if temperature < -0.2 and moisture > 0.5:
		return BiomeType.BLOOD_TEMPLE
	
	# Default: Starting Forest (moderate conditions)
	return BiomeType.STARTING_FOREST

func world_to_chunk(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(pos.x / chunk_size),
		int(pos.y / chunk_size)
	)

func chunk_to_world(chunk: Vector2i) -> Vector2:
	return Vector2(
		chunk.x * chunk_size + chunk_size / 2,
		chunk.y * chunk_size + chunk_size / 2
	)

func update_current_biome():
	var new_biome = get_biome_at_position(player.global_position)
	
	if new_biome.type != current_biome.type:
		var old_biome = current_biome
		current_biome = new_biome
		
		print("=== Biome Changed ===")
		print("From: ", old_biome.name)
		print("To: ", new_biome.name)
		print("Temp: %.2f, Moisture: %.2f" % [
			temperature_noise.get_noise_2dv(player.global_position),
			moisture_noise.get_noise_2dv(player.global_position)
		])
		
		biome_changed.emit(old_biome, new_biome)
		check_boss_zone()

func update_cache():
	# Only cache chunks near player
	var player_chunk = world_to_chunk(player.global_position)
	
	# Remove far chunks
	var chunks_to_remove = []
	for chunk in biome_cache.keys():
		var distance = (chunk - player_chunk).length()
		if distance > cache_radius * 2:
			chunks_to_remove.append(chunk)
	
	for chunk in chunks_to_remove:
		biome_cache.erase(chunk)

func check_boss_zone():
	# Boss zones spawn in dangerous biomes after certain distance
	if current_biome.type == BiomeType.VOLCANIC_DARKLANDS or \
	   current_biome.type == BiomeType.BLOOD_TEMPLE:
		
		var distance_from_spawn = player.global_position.length()
		if distance_from_spawn > 3000.0:
			print("!!! Entering Boss Zone in ", current_biome.name)
			entered_boss_zone.emit(current_biome.type)

func get_current_biome() -> BiomeData:
	return current_biome

func get_spawn_multiplier() -> float:
	return current_biome.enemy_spawn_multiplier if current_biome else 1.0

func get_biome_color() -> Color:
	return current_biome.color if current_biome else Color.WHITE

# Debug: Get biome map visualization
func get_biome_map_texture(size: int, pixel_size: float) -> ImageTexture:
	var image = Image.create(size, size, false, Image.FORMAT_RGB8)

	var half_size = size / 2
	for x in range(size):
		for y in range(size):
			var world_pos = Vector2(
				(x - half_size) * pixel_size,
				(y - half_size) * pixel_size
			)

			var biome = get_biome_at_position(world_pos)
			image.set_pixel(x, y, biome.color)

	return ImageTexture.create_from_image(image)

# Phase 7: Spawn Weapon ATMs across the map
func spawn_atms():
	print("=== Spawning Weapon ATMs ===")

	# BRONZE ATMs (3-5) - Free with cooldown, spread across all biomes
	var bronze_count = randi_range(3, 5)
	for i in range(bronze_count):
		var angle = randf() * TAU
		var distance = randf_range(800.0, 2500.0)
		var pos = Vector2(cos(angle), sin(angle)) * distance
		spawn_atm(pos, 0)  # Tier 0 = BRONZE

	print("✓ Spawned ", bronze_count, " Bronze ATMs")

	# SILVER ATMs (1-2) - 100 gold, in uncommon/rare biomes
	var silver_count = randi_range(1, 2)
	for i in range(silver_count):
		var pos = find_atm_position_in_biome([BiomeType.DESERT_WASTELAND, BiomeType.FROZEN_TUNDRA])
		if pos != Vector2.ZERO:
			spawn_atm(pos, 1)  # Tier 1 = SILVER

	print("✓ Spawned ", silver_count, " Silver ATMs")

	# GOLD ATM (1) - 500 gold, in rare biome
	var gold_pos = find_atm_position_in_biome([BiomeType.VOLCANIC_DARKLANDS, BiomeType.FROZEN_TUNDRA])
	if gold_pos != Vector2.ZERO:
		spawn_atm(gold_pos, 2)  # Tier 2 = GOLD
		print("✓ Spawned 1 Gold ATM")

	# DIVINE ATM (0-1) - 2000 gold, in very rare biome (30% chance)
	if randf() < 0.3:
		var divine_pos = find_atm_position_in_biome([BiomeType.BLOOD_TEMPLE, BiomeType.VOLCANIC_DARKLANDS])
		if divine_pos != Vector2.ZERO:
			spawn_atm(divine_pos, 3)  # Tier 3 = DIVINE
			print("✓ Spawned 1 Divine ATM")

	print("=== Total ATMs spawned: ", spawned_atms.size(), " ===")

func spawn_atm(pos: Vector2, tier: int):
	var atm = atm_scene.instantiate()
	atm.global_position = pos
	atm.tier = tier

	# Set cost based on tier
	match tier:
		0: atm.cost = 0     # BRONZE - Free
		1: atm.cost = 100   # SILVER - 100 gold
		2: atm.cost = 500   # GOLD - 500 gold
		3: atm.cost = 2000  # DIVINE - 2000 gold

	get_parent().add_child(atm)
	spawned_atms.append(atm)

	print("  ATM spawned at ", pos, " (Tier: ", tier, ", Cost: ", atm.cost, ")")

func find_atm_position_in_biome(target_biomes: Array) -> Vector2:
	# Try to find a position in one of the target biomes
	for attempt in range(20):
		var angle = randf() * TAU
		var distance = randf_range(1500.0, 4000.0)
		var pos = Vector2(cos(angle), sin(angle)) * distance

		var biome = get_biome_at_position(pos)
		if biome.type in target_biomes:
			return pos

	# Fallback: return any distant position
	var angle = randf() * TAU
	var distance = randf_range(2000.0, 3500.0)
	return Vector2(cos(angle), sin(angle)) * distance
