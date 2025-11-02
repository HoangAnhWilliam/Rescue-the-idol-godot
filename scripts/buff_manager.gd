extends Node
class_name BuffManager

# Buff types
enum BuffType {
	HP_REGEN,
	SPEED_BOOST,
	DAMAGE_BOOST,
	INVISIBILITY
}

# Active buffs storage
var active_buffs: Dictionary = {}

# Buff configurations
const BUFF_CONFIG = {
	BuffType.HP_REGEN: {
		"name": "HP Regeneration",
		"duration": 0.0,  # Instant effect
		"heal_amount": 50.0,
		"icon": "💚"
	},
	BuffType.SPEED_BOOST: {
		"name": "Speed Boost",
		"duration": 10.0,
		"multiplier": 1.5,
		"icon": "⚡"
	},
	BuffType.DAMAGE_BOOST: {
		"name": "Damage Boost",
		"duration": 15.0,
		"multiplier": 1.3,
		"icon": "🗡️"
	},
	BuffType.INVISIBILITY: {
		"name": "Invisibility",
		"duration": 10.0,
		"icon": "👻"
	}
}

# Reference to player
var player: CharacterBody2D

# Signals
signal buff_applied(buff_type: BuffType)
signal buff_expired(buff_type: BuffType)

func _ready():
	# Get player reference
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

	if not player:
		push_error("BuffManager: No player found!")

func _process(delta):
	# Update buff timers
	for buff_type in active_buffs.keys():
		active_buffs[buff_type] -= delta

		if active_buffs[buff_type] <= 0:
			remove_buff(buff_type)

func apply_buff(buff_type: BuffType):
	if not player:
		return

	var config = BUFF_CONFIG[buff_type]

	print(config["icon"], " Applied: ", config["name"])

	match buff_type:
		BuffType.HP_REGEN:
			apply_hp_regen(config)

		BuffType.SPEED_BOOST:
			apply_speed_boost(config)

		BuffType.DAMAGE_BOOST:
			apply_damage_boost(config)

		BuffType.INVISIBILITY:
			apply_invisibility(config)

	buff_applied.emit(buff_type)

func apply_hp_regen(config: Dictionary):
	# Instant heal
	if player.has_method("heal"):
		player.heal(config["heal_amount"])
	else:
		# Fallback: direct HP modification
		if "current_hp" in player and "stats" in player:
			player.current_hp = min(
				player.current_hp + config["heal_amount"],
				player.stats.max_hp
			)
			if player.has_signal("hp_changed"):
				player.hp_changed.emit(player.current_hp, player.stats.max_hp)

	print("✓ Healed ", config["heal_amount"], " HP")

func apply_speed_boost(config: Dictionary):
	# Add/refresh buff
	active_buffs[BuffType.SPEED_BOOST] = config["duration"]

	# Apply multiplier to player
	if "buff_speed_multiplier" in player:
		player.buff_speed_multiplier = config["multiplier"]

	print("✓ Speed boost active for ", config["duration"], "s")

func apply_damage_boost(config: Dictionary):
	# Add/refresh buff
	active_buffs[BuffType.DAMAGE_BOOST] = config["duration"]

	# Apply multiplier to player
	if "buff_damage_multiplier" in player:
		player.buff_damage_multiplier = config["multiplier"]

	print("✓ Damage boost active for ", config["duration"], "s")

func apply_invisibility(config: Dictionary):
	# Add/refresh buff
	active_buffs[BuffType.INVISIBILITY] = config["duration"]

	# Set invisibility flag
	if "is_invisible" in player:
		player.is_invisible = true

	# Visual feedback - make player semi-transparent
	if "sprite" in player and player.sprite:
		player.sprite.modulate.a = 0.3

	print("✓ Invisibility active for ", config["duration"], "s")

func remove_buff(buff_type: BuffType):
	active_buffs.erase(buff_type)

	var config = BUFF_CONFIG[buff_type]
	print("✗ ", config["name"], " expired")

	match buff_type:
		BuffType.SPEED_BOOST:
			if "buff_speed_multiplier" in player:
				player.buff_speed_multiplier = 1.0

		BuffType.DAMAGE_BOOST:
			if "buff_damage_multiplier" in player:
				player.buff_damage_multiplier = 1.0

		BuffType.INVISIBILITY:
			if "is_invisible" in player:
				player.is_invisible = false

			# Restore visibility
			if "sprite" in player and player.sprite:
				player.sprite.modulate.a = 1.0

	buff_expired.emit(buff_type)

func is_buff_active(buff_type: BuffType) -> bool:
	return buff_type in active_buffs

func get_buff_time_remaining(buff_type: BuffType) -> float:
	if buff_type in active_buffs:
		return active_buffs[buff_type]
	return 0.0

func clear_all_buffs():
	for buff_type in active_buffs.keys():
		remove_buff(buff_type)
