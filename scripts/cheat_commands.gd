extends Node
## Complete Cheat Commands System (Minecraft-style)
## 40+ commands for debugging and testing
## Activated via ChatBox with "/" prefix

# References
var player: Player
var chat_box: ChatBox

# God mode state
var god_mode_active: bool = false
var god_mode_timer: float = 0.0
var god_mode_infinite: bool = false
var one_shot_kill_active: bool = false

# Invincibility state (separate from god mode)
var invincible_hp: bool = false
var invincible_mana: bool = false

# Enemy scene mappings
var enemy_scenes := {
	"zombie": "res://scenes/enemies/Zombie.tscn",
	"skeleton": "res://scenes/enemies/Skeleton.tscn",
	"anime_ghost": "res://scenes/enemies/AnimeGhost.tscn",
	"dark_miku": "res://scenes/enemies/DarkMiku.tscn",
	"fire_dragon": "res://scenes/bosses/FireDragon.tscn",
	"vampire_lord": "res://scenes/bosses/VampireLord.tscn",
	"despair_miku": "res://scenes/bosses/DespairMiku.tscn",
}

# Debug toggles
var debug_fps: bool = false
var debug_hitbox: bool = false
var debug_enemy_ai: bool = false

func _ready():
	print("=== CheatCommands System Initializing ===")
	await get_tree().process_frame

	# Get references
	player = get_tree().get_first_node_in_group("player")
	chat_box = get_tree().get_first_node_in_group("chat_box")

	if not player:
		print("❌ ERROR: Player not found!")
	else:
		print("✓ Player reference acquired")

	if not chat_box:
		print("❌ ERROR: ChatBox not found!")
	else:
		print("✓ ChatBox reference acquired")

	print("=== CheatCommands System Ready ===")

func _process(delta):
	# Update god mode timer
	if god_mode_active and not god_mode_infinite and god_mode_timer > 0:
		god_mode_timer -= delta
		if god_mode_timer <= 0:
			deactivate_god_mode()

func process_command(command_text: String) -> void:
	"""Main command processor - called from ChatBox"""

	# Remove leading slash and trim
	var text = command_text.strip_edges()
	if text.begins_with("/"):
		text = text.substr(1)

	# Parse command and arguments
	var parts = text.split(" ", false)
	if parts.is_empty():
		send_error("Empty command")
		return

	var cmd = parts[0].to_lower()
	var args = parts.slice(1)

	print("♪ Processing command: ", cmd, " ", args)

	# Execute command
	match cmd:
		# CATEGORY 1: GAME CONTROL
		"pause": cmd_pause()
		"continue": cmd_continue()
		"suicide": cmd_suicide()

		# CATEGORY 2: GOD MODE
		"god": cmd_god(args)
		"ungod": cmd_ungod()

		# CATEGORY 3: STATS MANIPULATION
		"hp": cmd_hp(args)
		"mana": cmd_mana(args)
		"addxp": cmd_addxp(args)
		"level": cmd_level(args)
		"stats": cmd_stats(args)
		"damage": cmd_damage(args)

		# CATEGORY 4: COMBAT
		"kill": cmd_kill(args)
		"killall": cmd_killall()

		# CATEGORY 5: INVENTORY
		"clearinv": cmd_clearinv(args)
		"give": cmd_give(args)

		# CATEGORY 6: MOVEMENT
		"tp": cmd_tp(args)
		"tprandom": cmd_tprandom(args)

		# CATEGORY 7: SPAWN ENEMIES
		"summon": cmd_summon(args)

		# CATEGORY 8: REVIVE
		"revive": cmd_revive(false)
		"revivegod": cmd_revivegod(args)

		# CATEGORY 9: TIME & SPEED
		"time": cmd_time(args)
		"speed": cmd_speed(args)

		# CATEGORY 10: WEAPONS
		"weapon": cmd_weapon(args)

		# CATEGORY 11: BIOMES
		"biome": cmd_biome(args)

		# CATEGORY 12: MIKU SYSTEM
		"miku": cmd_miku(args)

		# CATEGORY 13: DEBUG & INFO
		"debug": cmd_debug(args)
		"info": cmd_info(args)

		# CATEGORY 14: SAVE/LOAD
		"save": cmd_save(args)
		"load": cmd_load()

		# CATEGORY 15: HELP
		"help": cmd_help(args)

		_:
			send_error("Unknown command: /" + cmd + ". Type /help for command list")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 1: GAME CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_pause():
	"""Pause the game"""
	get_tree().paused = true
	send_response("Game paused")

func cmd_continue():
	"""Resume the game"""
	get_tree().paused = false
	send_response("Game resumed")

func cmd_suicide():
	"""Kill player instantly"""
	if not player:
		send_error("Player not found")
		return

	player.current_hp = 0
	player.die()
	send_response("You died")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 2: GOD MODE
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_god(args: Array):
	"""Enable god mode with optional duration"""
	if not player:
		send_error("Player not found")
		return

	# Parse duration
	var duration_seconds: float = 60.0  # Default 60 seconds
	var is_infinite: bool = false

	if args.size() > 0:
		var time_arg = args[0].to_lower()
		if time_arg == "infinite":
			is_infinite = true
		else:
			duration_seconds = parse_time_string(time_arg)

	# Activate god mode
	activate_god_mode(duration_seconds, is_infinite)

	# Response
	if is_infinite:
		send_response("God mode activated (INFINITE)")
	else:
		send_response("God mode activated for " + format_time(duration_seconds))

func cmd_ungod():
	"""Disable god mode"""
	if not player:
		send_error("Player not found")
		return

	deactivate_god_mode()
	send_response("God mode deactivated")

func activate_god_mode(duration: float, infinite: bool):
	"""Activate god mode on player"""
	god_mode_active = true
	god_mode_infinite = infinite
	one_shot_kill_active = true

	if not infinite:
		god_mode_timer = duration

	# Set player properties
	player.god_mode = true
	player.one_shot_kill = true

	print("God mode activated: infinite=%s, duration=%.1f" % [infinite, duration])

func deactivate_god_mode():
	"""Deactivate god mode"""
	god_mode_active = false
	god_mode_infinite = false
	one_shot_kill_active = false
	god_mode_timer = 0.0

	# Clear player properties
	if player:
		player.god_mode = false
		player.one_shot_kill = false

	send_response("God mode expired!")
	print("God mode deactivated")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 3: STATS MANIPULATION
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_hp(args: Array):
	"""Set player HP with optional invincibility
	Usage: /hp <amount> <true/false>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /hp <amount> <true/false>")
		return

	var amount = args[0].to_float()
	var invincible = false

	if args.size() >= 2:
		var inv_arg = args[1].to_lower()
		invincible = (inv_arg == "true" or inv_arg == "1")

	# Set HP
	player.stats.max_hp = amount
	player.current_hp = amount
	player.hp_changed.emit(player.current_hp, player.stats.max_hp)

	# Set invincibility
	player.invincible_hp = invincible
	invincible_hp = invincible

	# Response
	if invincible:
		send_response("HP set to %.0f (INVINCIBLE)" % amount)
	else:
		send_response("HP set to %.0f" % amount)

func cmd_mana(args: Array):
	"""Set player Mana with optional invincibility
	Usage: /mana <amount> <true/false>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /mana <amount> <true/false>")
		return

	var amount = args[0].to_float()
	var invincible = false

	if args.size() >= 2:
		var inv_arg = args[1].to_lower()
		invincible = (inv_arg == "true" or inv_arg == "1")

	# Set Mana
	player.stats.max_mana = amount
	player.current_mana = amount
	player.mana_changed.emit(player.current_mana, player.stats.max_mana)

	# Set invincibility
	player.invincible_mana = invincible
	invincible_mana = invincible

	# Response
	if invincible:
		send_response("Mana set to %.0f (INVINCIBLE)" % amount)
	else:
		send_response("Mana set to %.0f" % amount)

func cmd_addxp(args: Array):
	"""Add XP or level up to target level
	Usage: /addxp <amount> OR /addxp to reach lvl <level>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /addxp <amount> OR /addxp to reach lvl <level>")
		return

	# Check if format is "to reach lvl X"
	var full_text = " ".join(args).to_lower()
	if "to reach lvl" in full_text or "to reach level" in full_text:
		# Extract target level
		var target_level = 0
		for arg in args:
			if arg.is_valid_int():
				target_level = arg.to_int()
				break

		if target_level <= player.level:
			send_error("Target level must be higher than current level (%d)" % player.level)
			return

		# Level up multiple times
		var old_level = player.level
		level_up_to_target(target_level)
		send_response("Leveled up from %d to %d!" % [old_level, player.level])
	else:
		# Simple XP add
		var amount = args[0].to_float()
		player.add_xp(amount)
		send_response("Added %.0f XP" % amount)

func level_up_to_target(target_level: int):
	"""Level up player to target level, showing upgrade menus"""
	while player.level < target_level:
		# Force level up
		player.level += 1
		player.current_xp = 0.0
		player.xp_to_next_level = player.get_xp_for_next_level()

		# Emit level up signal
		player.level_up.emit(player.level)

		# Show upgrade menu for each level
		player.show_level_up_menu()

		# Wait a bit for upgrade menu to process
		await get_tree().create_timer(0.1).timeout

func cmd_level(args: Array):
	"""Set player level directly
	Usage: /level set <number>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 2 or args[0].to_lower() != "set":
		send_error("Usage: /level set <number>")
		return

	var new_level = args[1].to_int()
	if new_level < 1:
		send_error("Level must be at least 1")
		return

	player.level = new_level
	player.current_xp = 0.0
	player.xp_to_next_level = player.get_xp_for_next_level()

	send_response("Level set to %d" % new_level)

func cmd_stats(args: Array):
	"""Reset or max all stats
	Usage: /stats reset OR /stats max"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /stats reset OR /stats max")
		return

	var action = args[0].to_lower()

	match action:
		"reset":
			# Reset to default stats
			player.stats.max_hp = 100
			player.stats.max_mana = 50
			player.stats.attack_damage = 10
			player.stats.move_speed = 200
			player.stats.attack_speed = 1.0
			player.stats.crit_chance = 0.05
			player.stats.crit_multiplier = 2.0

			player.current_hp = player.stats.max_hp
			player.current_mana = player.stats.max_mana

			player.hp_changed.emit(player.current_hp, player.stats.max_hp)
			player.mana_changed.emit(player.current_mana, player.stats.max_mana)

			send_response("Stats reset to default")

		"max":
			# Max all stats
			player.stats.max_hp = 10000
			player.stats.max_mana = 1000
			player.stats.attack_damage = 1000
			player.stats.move_speed = 500
			player.stats.attack_speed = 5.0
			player.stats.crit_chance = 0.5
			player.stats.crit_multiplier = 3.0

			player.current_hp = player.stats.max_hp
			player.current_mana = player.stats.max_mana

			player.hp_changed.emit(player.current_hp, player.stats.max_hp)
			player.mana_changed.emit(player.current_mana, player.stats.max_mana)

			send_response("Stats maxed!")

		_:
			send_error("Unknown action: " + action + ". Use 'reset' or 'max'")

func cmd_damage(args: Array):
	"""Set player attack damage
	Usage: /damage set <amount>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 2 or args[0].to_lower() != "set":
		send_error("Usage: /damage set <amount>")
		return

	var amount = args[1].to_float()
	player.stats.attack_damage = amount

	send_response("Damage set to %.0f" % amount)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 4: COMBAT
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_kill(args: Array):
	"""Kill enemies (multiple formats)
	Usage:
	  /kill zombie 20      - Kill zombies within radius 20
	  /kill 50             - Kill all enemies within radius 50
	  /kill anime ghost    - Kill all anime ghosts on entire map"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /kill <enemy> <radius> OR /kill <radius> OR /kill <enemy>")
		return

	var enemy_name = ""
	var radius = -1.0  # -1 means entire map

	# Parse arguments
	if args.size() == 1:
		# Either enemy name or radius
		if args[0].is_valid_float():
			radius = args[0].to_float()
		else:
			enemy_name = args[0].to_lower()
	elif args.size() >= 2:
		# Check if last arg is a number (radius)
		if args[args.size() - 1].is_valid_float():
			radius = args[args.size() - 1].to_float()
			enemy_name = " ".join(args.slice(0, args.size() - 1)).to_lower()
		else:
			# All args are enemy name
			enemy_name = " ".join(args).to_lower()

	# Get enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	var killed_count = 0

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		# Check enemy name filter
		if enemy_name != "":
			var enemy_class_name = enemy.get_class().to_lower()
			var enemy_node_name = enemy.name.to_lower()

			if not (enemy_name in enemy_class_name or enemy_name in enemy_node_name):
				continue

		# Check radius filter
		if radius > 0:
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance > radius:
				continue

		# Kill enemy
		if enemy.has_method("die"):
			enemy.die()
		else:
			enemy.queue_free()

		killed_count += 1

	# Response
	var response_parts = ["Killed %d" % killed_count]
	if enemy_name != "":
		response_parts.append(enemy_name)
	else:
		response_parts.append("enemies")
	if radius > 0:
		response_parts.append("in radius %.0f" % radius)
	else:
		response_parts.append("(entire map)")

	send_response(" ".join(response_parts))

func cmd_killall():
	"""Kill ALL enemies on entire map"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()

	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.has_method("die"):
				enemy.die()
			else:
				enemy.queue_free()

	send_response("Killed all enemies (%d)" % count)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 5: INVENTORY
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_clearinv(args: Array):
	"""Clear inventory slots
	Usage: /clearinv OR /clearinv <slot_number>"""
	if not player:
		send_error("Player not found")
		return

	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		send_error("Inventory system not found")
		return

	if args.size() == 0:
		# Clear all slots
		inventory.clear_all_items()
		send_response("Inventory cleared")
	else:
		# Clear specific slot
		var slot = args[0].to_int() - 1  # Convert to 0-indexed
		if slot < 0 or slot > 8:
			send_error("Invalid slot number. Use 1-9")
			return

		inventory.remove_item_at_slot(slot)
		send_response("Cleared slot %d" % (slot + 1))

func cmd_give(args: Array):
	"""Give items/gold to player
	Usage: /give $ <amount> OR /give <weapon_name> <amount>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 2:
		send_error("Usage: /give $ <amount> OR /give <weapon_name> <amount>")
		return

	# Check if giving gold
	if args[0] == "$":
		var amount = args[1].to_int()
		player.add_gold(amount)
		send_response("Gave %d gold" % amount)
		return

	# Give weapon/item
	var weapon_name = args[0].to_lower()
	var amount = args[1].to_int() if args.size() >= 2 else 1

	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		send_error("Inventory system not found")
		return

	# Add weapon to inventory multiple times
	for i in range(amount):
		inventory.add_item(
			inventory.ItemType.WEAPON,
			weapon_name,
			1,
			{
				"weapon_name": weapon_name.capitalize(),
				"rarity": 3,  # LEGENDARY
				"damage": 100.0,
				"attack_speed": 2.0
			}
		)

	send_response("Gave %d %s" % [amount, weapon_name])


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 6: MOVEMENT
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_tp(args: Array):
	"""Teleport player
	Usage: /tp <x> <y> OR /tp <biome_name>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /tp <x> <y> OR /tp <biome_name>")
		return

	# Check if coordinates (2 numbers)
	if args.size() >= 2 and args[0].is_valid_float() and args[1].is_valid_float():
		var x = args[0].to_float()
		var y = args[1].to_float()
		player.global_position = Vector2(x, y)
		send_response("Teleported to (%.0f, %.0f)" % [x, y])
	else:
		# Biome name
		var biome_name = " ".join(args).to_lower()
		var pos = get_biome_position(biome_name)

		if pos == Vector2.ZERO and not ("forest" in biome_name or "starting" in biome_name):
			send_error("Unknown biome: " + biome_name)
			return

		player.global_position = pos
		send_response("Teleported to " + biome_name.capitalize())

func cmd_tprandom(args: Array):
	"""Random teleport within radius
	Usage: /tprandom <radius>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /tprandom <radius>")
		return

	var radius = args[0].to_float()

	# Random position within radius
	var angle = randf() * TAU
	var distance = randf_range(0, radius)
	var offset = Vector2(cos(angle), sin(angle)) * distance

	player.global_position = player.global_position + offset

	send_response("Teleported randomly within radius %.0f" % radius)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 7: SPAWN ENEMIES
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_summon(args: Array):
	"""Summon enemies/bosses
	Usage:
	  /summon @player <enemy> <count>
	  /summon @player <enemy> <count> <time>
	  /summon @<x> <y> <enemy> <count>
	  /summon @<x> <y> <enemy> <count> <time>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 3:
		send_error("Usage: /summon @player <enemy> <count> [time] OR /summon @<x> <y> <enemy> <count> [time]")
		return

	var spawn_pos: Vector2
	var enemy_name: String
	var count: int
	var lifetime: float = -1.0  # -1 means permanent

	# Parse format
	if args[0].to_lower() == "@player":
		# Format: @player <enemy> <count> [time]
		spawn_pos = player.global_position + Vector2(100, 0)
		enemy_name = args[1].to_lower()
		count = args[2].to_int()

		if args.size() >= 4:
			lifetime = parse_time_string(args[3])
	else:
		# Format: @<x> <y> <enemy> <count> [time]
		if args[0].begins_with("@"):
			var x = args[0].substr(1).to_float()
			var y = args[1].to_float()
			spawn_pos = Vector2(x, y)
			enemy_name = args[2].to_lower()
			count = args[3].to_int()

			if args.size() >= 5:
				lifetime = parse_time_string(args[4])
		else:
			send_error("Invalid format. Use @player or @<x>")
			return

	# Get enemy scene path
	var scene_path = get_enemy_scene_path(enemy_name)
	if scene_path == "":
		send_error("Unknown enemy: " + enemy_name)
		return

	# Check if scene exists
	if not FileAccess.file_exists(scene_path):
		send_error("Enemy scene not found: " + scene_path)
		return

	# Spawn enemies
	var enemy_scene = load(scene_path)
	var spawned_count = 0

	for i in range(count):
		var enemy = enemy_scene.instantiate()

		# Random offset for multiple spawns
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		enemy.global_position = spawn_pos + offset

		# Add to scene
		get_tree().root.add_child(enemy)
		spawned_count += 1

		# Add lifetime timer if specified
		if lifetime > 0:
			var timer = Timer.new()
			timer.wait_time = lifetime
			timer.one_shot = true
			timer.timeout.connect(func(): enemy.queue_free())
			enemy.add_child(timer)
			timer.start()

	# Response
	var response = "Summoned %d %s" % [spawned_count, enemy_name]
	if lifetime > 0:
		response += " for " + format_time(lifetime)

	send_response(response)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 8: REVIVE
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_revive(silent: bool):
	"""Revive player with full HP/Mana"""
	if not player:
		send_error("Player not found")
		return

	# Restore HP and Mana
	player.current_hp = player.stats.max_hp
	player.current_mana = player.stats.max_mana

	# Emit signals
	player.hp_changed.emit(player.current_hp, player.stats.max_hp)
	player.mana_changed.emit(player.current_mana, player.stats.max_mana)

	# Re-enable physics
	player.set_physics_process(true)

	# Reset sprite color
	if player.sprite:
		player.sprite.modulate = Color.WHITE

	if not silent:
		send_response("Revived!")

func cmd_revivegod(args: Array):
	"""Revive with god mode
	Usage: /revivegod OR /revivegod <time>"""
	if not player:
		send_error("Player not found")
		return

	# Revive first
	cmd_revive(true)

	# Parse god mode duration
	var duration_seconds: float = 60.0
	var is_infinite: bool = true  # Default to infinite for revivegod

	if args.size() > 0:
		var time_arg = args[0].to_lower()
		if time_arg != "infinite":
			duration_seconds = parse_time_string(time_arg)
			is_infinite = false

	# Activate god mode
	activate_god_mode(duration_seconds, is_infinite)

	# Response
	if is_infinite:
		send_response("Revived with God mode (INFINITE)!")
	else:
		send_response("Revived with God mode for " + format_time(duration_seconds) + "!")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 9: TIME & SPEED
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_time(args: Array):
	"""Manipulate game time
	Usage: /time set <seconds> OR /time add <seconds>"""
	if args.size() < 2:
		send_error("Usage: /time set <seconds> OR /time add <seconds>")
		return

	var action = args[0].to_lower()
	var amount = args[1].to_float()

	# Check if GameManager exists
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager or not game_manager.has("game_time"):
		send_error("Game time system not found")
		return

	match action:
		"set":
			game_manager.game_time = amount
			send_response("Time set to %.0f seconds" % amount)
		"add":
			game_manager.game_time += amount
			send_response("Added %.0f seconds" % amount)
		_:
			send_error("Unknown action: " + action + ". Use 'set' or 'add'")

func cmd_speed(args: Array):
	"""Change game speed
	Usage: /speed <multiplier> OR /speed normal"""
	if args.size() < 1:
		send_error("Usage: /speed <multiplier> OR /speed normal")
		return

	var speed_arg = args[0].to_lower()

	if speed_arg == "normal":
		Engine.time_scale = 1.0
		send_response("Speed reset to normal")
	else:
		var speed = speed_arg.to_float()
		speed = clamp(speed, 0.1, 5.0)
		Engine.time_scale = speed
		send_response("Speed set to %.1fx" % speed)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 10: WEAPONS
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_weapon(args: Array):
	"""Weapon management
	Usage: /weapon upgrade <name> <level> OR /weapon max <name> OR /weapon remove <name>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 2:
		send_error("Usage: /weapon upgrade <name> <level> OR /weapon max <name> OR /weapon remove <name>")
		return

	var action = args[0].to_lower()
	var weapon_name = args[1].to_lower()

	match action:
		"upgrade":
			if args.size() < 3:
				send_error("Usage: /weapon upgrade <name> <level>")
				return
			var level = args[2].to_int()
			send_response("Weapon upgrade system not fully implemented. Target: %s to level %d" % [weapon_name, level])

		"max":
			send_response("Weapon max system not fully implemented. Target: %s" % weapon_name)

		"remove":
			send_response("Weapon remove system not fully implemented. Target: %s" % weapon_name)

		_:
			send_error("Unknown action: " + action)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 11: BIOMES
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_biome(args: Array):
	"""Biome information
	Usage: /biome info OR /biome list"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /biome info OR /biome list")
		return

	var action = args[0].to_lower()

	match action:
		"info":
			var biome = get_biome_at_position(player.global_position)
			send_response("Current biome: " + biome)

		"list":
			send_response("Biomes: Starting Forest, Desert Wasteland, Frozen Tundra, Volcanic Darklands, Blood Temple")

		_:
			send_error("Unknown action: " + action + ". Use 'info' or 'list'")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 12: MIKU SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_miku(args: Array):
	"""Miku system cheats
	Usage: /miku spawn OR /miku timer set <minutes> OR /miku fragment add <count> OR /miku unlock"""
	if args.size() < 1:
		send_error("Usage: /miku spawn OR /miku timer set <mins> OR /miku fragment add <count> OR /miku unlock")
		return

	var action = args[0].to_lower()

	match action:
		"spawn":
			send_response("Miku spawn system not fully implemented")

		"timer":
			if args.size() >= 3 and args[1].to_lower() == "set":
				var minutes = args[2].to_float()
				send_response("Miku timer set to %.0f minutes (not fully implemented)" % minutes)
			else:
				send_error("Usage: /miku timer set <minutes>")

		"fragment":
			if args.size() >= 3 and args[1].to_lower() == "add":
				var count = args[2].to_int()
				send_response("Added %d Miku fragments (not fully implemented)" % count)
			else:
				send_error("Usage: /miku fragment add <count>")

		"unlock":
			send_response("Permanent Miku unlocked (not fully implemented)")

		_:
			send_error("Unknown action: " + action)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 13: DEBUG & INFO
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_debug(args: Array):
	"""Toggle debug features
	Usage: /debug fps OR /debug hitbox OR /debug enemy"""
	if args.size() < 1:
		send_error("Usage: /debug fps OR /debug hitbox OR /debug enemy")
		return

	var feature = args[0].to_lower()

	match feature:
		"fps":
			debug_fps = !debug_fps
			send_response("FPS counter toggled (%s)" % ("ON" if debug_fps else "OFF"))

		"hitbox":
			debug_hitbox = !debug_hitbox
			send_response("Hitbox visibility toggled (%s)" % ("ON" if debug_hitbox else "OFF"))

		"enemy":
			debug_enemy_ai = !debug_enemy_ai
			send_response("Enemy AI display toggled (%s)" % ("ON" if debug_enemy_ai else "OFF"))

		_:
			send_error("Unknown feature: " + feature)

func cmd_info(args: Array):
	"""Display information
	Usage: /info player OR /info enemy <name>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /info player OR /info enemy <name>")
		return

	var target = args[0].to_lower()

	match target:
		"player":
			var info = "Player Info:\n"
			info += "HP: %.0f/%.0f\n" % [player.current_hp, player.stats.max_hp]
			info += "Mana: %.0f/%.0f\n" % [player.current_mana, player.stats.max_mana]
			info += "Level: %d\n" % player.level
			info += "XP: %.0f/%.0f\n" % [player.current_xp, player.xp_to_next_level]
			info += "Gold: %d\n" % player.gold
			info += "Damage: %.0f\n" % player.stats.attack_damage
			info += "Speed: %.0f\n" % player.stats.move_speed
			info += "Crit: %.1f%%" % (player.stats.crit_chance * 100)

			send_response(info)

		"enemy":
			if args.size() < 2:
				send_error("Usage: /info enemy <name>")
				return
			send_response("Enemy info not fully implemented")

		_:
			send_error("Unknown target: " + target)


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 14: SAVE/LOAD
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_save(args: Array):
	"""Save game management
	Usage: /save OR /save reset confirm"""
	if args.size() == 0:
		# Force save
		SaveSystem.save_game()
		send_response("Game saved")
	elif args.size() >= 2 and args[0].to_lower() == "reset" and args[1].to_lower() == "confirm":
		# Reset save data
		SaveSystem.reset_save()
		send_response("Save data reset!")
	else:
		send_error("Usage: /save OR /save reset confirm")

func cmd_load():
	"""Reload game from save"""
	SaveSystem.load_game()
	send_response("Game loaded")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 15: HELP
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_help(args: Array):
	"""Show command help
	Usage: /help OR /help <command>"""
	if args.size() == 0:
		# Show command list by category
		send_response("=== CHEAT COMMANDS ===")
		send_response("GAME: /pause /continue /suicide")
		send_response("GOD: /god /ungod")
		send_response("STATS: /hp /mana /addxp /level /stats /damage")
		send_response("COMBAT: /kill /killall")
		send_response("INVENTORY: /clearinv /give")
		send_response("MOVEMENT: /tp /tprandom")
		send_response("SPAWN: /summon")
		send_response("REVIVE: /revive /revivegod")
		send_response("TIME: /time /speed")
		send_response("WEAPONS: /weapon")
		send_response("BIOMES: /biome")
		send_response("MIKU: /miku")
		send_response("DEBUG: /debug /info")
		send_response("SAVE: /save /load")
		send_response("Type /help <command> for details")
	else:
		# Show detailed help for specific command
		var cmd = args[0].to_lower()
		show_command_help(cmd)


func show_command_help(cmd: String):
	"""Show detailed help for a specific command"""
	match cmd:
		"god":
			send_response("/god [time|infinite] - Enable god mode")
			send_response("Examples: /god, /god 10mins, /god infinite")

		"hp":
			send_response("/hp <amount> <true/false> - Set HP with optional invincibility")
			send_response("Examples: /hp 1000 true, /hp 500 false")

		"kill":
			send_response("/kill <enemy> <radius> - Kill enemies")
			send_response("Examples: /kill zombie 20, /kill 50, /kill anime ghost")

		"tp":
			send_response("/tp <x> <y> OR /tp <biome> - Teleport player")
			send_response("Examples: /tp 4500 0, /tp blood temple")

		"summon":
			send_response("/summon @player <enemy> <count> [time] - Summon enemies")
			send_response("Examples: /summon @player zombie 10, /summon @4500 0 fire_dragon 1")

		_:
			send_error("No detailed help for: " + cmd)


# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

func parse_time_string(text: String) -> float:
	"""Parse time string to seconds
	Supports: 10mins, 10min, 10m, 30sec, 30s, infinite"""
	var lower = text.to_lower()

	if lower == "infinite":
		return -1.0

	# Remove all spaces
	lower = lower.replace(" ", "")

	# Minutes
	if lower.ends_with("mins") or lower.ends_with("min") or lower.ends_with("m"):
		var num_str = lower.replace("mins", "").replace("min", "").replace("m", "")
		var num = num_str.to_float()
		return num * 60.0

	# Seconds
	elif lower.ends_with("sec") or lower.ends_with("s"):
		var num_str = lower.replace("sec", "").replace("s", "")
		var num = num_str.to_float()
		return num

	# Default: treat as seconds
	else:
		return lower.to_float()

func format_time(seconds: float) -> String:
	"""Format seconds to readable string"""
	if seconds < 60:
		return "%.0f seconds" % seconds
	else:
		var minutes = int(seconds / 60)
		return "%d minutes" % minutes

func get_biome_at_position(pos: Vector2) -> String:
	"""Get biome name at position"""
	if pos.x < 1000:
		return "Starting Forest"
	elif pos.x < 2000:
		return "Desert Wasteland"
	elif pos.x < 3000:
		return "Frozen Tundra"
	elif pos.x < 4000:
		return "Volcanic Darklands"
	else:
		return "Blood Temple"

func get_biome_position(biome_name: String) -> Vector2:
	"""Get biome center position"""
	var lower = biome_name.to_lower()

	if "forest" in lower or "starting" in lower:
		return Vector2(500, 0)
	elif "desert" in lower:
		return Vector2(1500, 0)
	elif "tundra" in lower or "frozen" in lower:
		return Vector2(2500, 0)
	elif "volcanic" in lower or "darkland" in lower:
		return Vector2(3500, 0)
	elif "blood" in lower or "temple" in lower:
		return Vector2(4500, 0)
	else:
		return Vector2.ZERO

func get_enemy_scene_path(enemy_name: String) -> String:
	"""Get enemy scene path from name"""
	var lower = enemy_name.to_lower().replace(" ", "_")

	if lower in enemy_scenes:
		return enemy_scenes[lower]

	# Try to find by partial match
	for key in enemy_scenes.keys():
		if key in lower or lower in key:
			return enemy_scenes[key]

	return ""

func send_response(text: String):
	"""Send success response to chat"""
	if chat_box and chat_box.has_method("add_message"):
		chat_box.add_message("System", text, "System")
	print("✓ " + text)

func send_error(text: String):
	"""Send error message to chat"""
	if chat_box and chat_box.has_method("add_message"):
		chat_box.add_message("System", "ERROR: " + text, "System")
	print("❌ ERROR: " + text)
