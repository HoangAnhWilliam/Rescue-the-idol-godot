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

# Enemy scene mappings (all lowercase keys for easy matching)
var enemy_scenes := {
	# Basic enemies
	"zombie": "res://scenes/enemies/Zombie.tscn",
	"skeleton_bad": "res://scenes/enemies/skeleton_bad.tscn",
	"skeleton_buff": "res://scenes/enemies/skeleton_buff.tscn",
	"anime_ghost": "res://scenes/enemies/anime_ghost.tscn",
	"dark_kiku": "res://scenes/enemies/dark_kiku.tscn",

	# Biome-specific enemies
	"desert_nomad": "res://scenes/enemies/desert_nomad.tscn",
	"skeleton_camel": "res://scenes/enemies/skeleton_camel.tscn",
	"ice_golem": "res://scenes/enemies/ice_golem.tscn",
	"snowdwarf_traitor": "res://scenes/enemies/snowdwarf_traitor.tscn",
	"snowman_warrior": "res://scenes/enemies/snowman_warrior.tscn",
	"lava_elemental": "res://scenes/enemies/lava_elemental.tscn",
	"magma_slime": "res://scenes/enemies/magma_slime.tscn",
	"vampire_bat": "res://scenes/enemies/vampire_bat.tscn",

	# Bosses (lowercase paths - FIXED)
	"fire_dragon": "res://scenes/bosses/fire_dragon.tscn",
	"vampire_lord": "res://scenes/bosses/vampire_lord.tscn",
	"despair_kiku": "res://scenes/bosses/despair_kiku.tscn",
}

# Debug toggles
var debug_fps: bool = false
var debug_hitbox: bool = false
var debug_enemy_ai: bool = false

# Music system state
var song_loop_count: int = 0
var song_loop_max: int = 0
var is_song_looping: bool = false
var current_loop_song: String = ""
var song_queue: Array[String] = []
var is_shuffling: bool = false

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

	# BUG FIX: Refresh references every time (CheatCommands loads before game scene)
	if not player or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	if not chat_box or not is_instance_valid(chat_box):
		chat_box = get_tree().get_first_node_in_group("chat_box")

	# Verify references
	if not player:
		print("❌ CheatCommands: Player not found!")
		if chat_box:
			chat_box.add_message("System", "ERROR: Player not found - commands unavailable", "System")
		return

	if not chat_box:
		print("❌ CheatCommands: ChatBox not found - commands will work but no feedback shown")

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
		"kiku": cmd_kiku(args)

		# CATEGORY 13: DEBUG & INFO
		"debug": cmd_debug(args)
		"info": cmd_info(args)

		# CATEGORY 14: SAVE/LOAD
		"save": cmd_save(args)
		"load": cmd_load()

		# CATEGORY 15: HELP
		"help": cmd_help(args)

		# CATEGORY 16: MUSIC SYSTEM
		"song": cmd_song(args)
		"music": cmd_music(args)
		"sfx": cmd_sfx(args)
		"playlist": cmd_playlist(args)
		"queue": cmd_queue(args)
		"shuffle": cmd_shuffle()
		"skip": cmd_skip()

		# CATEGORY 17: BOSS COMMANDS
		"boss": cmd_boss(args)

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

	# Check if format is "to reach lvl X" or "reach to lvl X"
	var full_text = " ".join(args).to_lower()
	if "to reach lvl" in full_text or "to reach level" in full_text or "reach to lvl" in full_text or "reach to level" in full_text:
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
	var upgrade_menu = get_tree().get_first_node_in_group("upgrade_menu")
	if not upgrade_menu:
		send_error("Upgrade menu not found - cannot show level up menus")
		return

	while player.level < target_level:
		# Force level up
		player.level += 1
		player.current_xp = 0.0
		player.xp_to_next_level = player.get_xp_for_next_level()

		# Emit level up signal
		player.level_up.emit(player.level)

		# Show upgrade menu for this level
		player.show_level_up_menu()

		# Wait for player to choose an upgrade before continuing
		# Menu emits upgrade_chosen signal when player selects
		await upgrade_menu.upgrade_chosen

		# Small delay before next level
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

	# Emit signal to update HUD
	player.level_up.emit(player.level)

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
		var old_gold = player.gold
		player.add_gold(amount)
		send_response("Gave %d gold (Total: %d)" % [amount, player.gold])
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
	Usage: /tp <x> <y> OR /tp <biome_name> OR /tp boss <boss_name>"""
	if not player:
		send_error("Player not found")
		return

	if args.size() < 1:
		send_error("Usage: /tp <x> <y> OR /tp <biome_name> OR /tp boss <boss_name>")
		return

	# Check if "tp boss <name>" command
	if args[0].to_lower() == "boss" and args.size() >= 2:
		tp_to_boss(args[1].to_lower())
		return

	# Check if coordinates (2 numbers)
	if args.size() >= 2 and args[0].is_valid_float() and args[1].is_valid_float():
		var x = args[0].to_float()
		var y = args[1].to_float()
		player.global_position = Vector2(x, y)
		send_response("Teleported to (%.0f, %.0f)" % [x, y])

		# Update biome and music after teleport
		await get_tree().process_frame
		var biome_generator = get_tree().get_first_node_in_group("biome_generator")
		if biome_generator and biome_generator.has_method("force_update_biome"):
			biome_generator.force_update_biome(player.global_position)
	else:
		# Biome name - SEARCH for actual biome
		var biome_name = " ".join(args).to_lower()
		var pos = search_for_biome(biome_name)

		if pos == Vector2.ZERO:
			send_error("Could not find biome: " + biome_name)
			send_response("[HINT] Try: forest, desert, tundra, volcanic, darklands, blood temple")
			send_response("[HINT] Or use /tp boss <name> for exact boss positions")
			return

		player.global_position = pos
		send_response("Teleported to " + biome_name.capitalize() + " at (%.0f, %.0f)" % [pos.x, pos.y])

		# Update biome and music after teleport
		await get_tree().process_frame
		var biome_generator = get_tree().get_first_node_in_group("biome_generator")
		if biome_generator and biome_generator.has_method("force_update_biome"):
			biome_generator.force_update_biome(player.global_position)

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

	var spawn_pos: Vector2
	var enemy_name: String
	var count: int
	var lifetime: float = -1.0  # -1 means permanent

	# Parse format
	if args.size() >= 3 and args[0].to_lower() == "@player":
		# Format: @player <enemy> <count> [time]
		spawn_pos = player.global_position + Vector2(100, 0)
		enemy_name = args[1].to_lower()
		count = args[2].to_int()

		if args.size() >= 4:
			lifetime = parse_time_string(args[3])
	elif args.size() >= 4 and args[0].begins_with("@"):
		# Format: @<x> <y> <enemy> <count> [time]
		var x = args[0].substr(1).to_float()
		var y = args[1].to_float()
		spawn_pos = Vector2(x, y)
		enemy_name = args[2].to_lower()
		count = args[3].to_int()

		if args.size() >= 5:
			lifetime = parse_time_string(args[4])
	else:
		send_error("Usage: /summon @player <enemy> <count> [time] OR /summon @<x> <y> <enemy> <count> [time]")
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
	var is_boss = is_boss_enemy(enemy_name)

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

	# Play boss music if it's a boss
	if is_boss and spawned_count > 0:
		await get_tree().process_frame
		play_boss_music(enemy_name)

	# Response
	var response = "Summoned %d %s" % [spawned_count, enemy_name]
	if lifetime > 0:
		response += " for " + format_time(lifetime)
	if is_boss:
		response += " (Boss music started)"

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

func cmd_kiku(args: Array):
	"""Miku system cheats
	Usage: /kiku spawn OR /kiku timer set <minutes> OR /kiku fragment add <count> OR /kiku unlock"""
	if args.size() < 1:
		send_error("Usage: /kiku spawn OR /kiku timer set <mins> OR /kiku fragment add <count> OR /kiku unlock")
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
				send_error("Usage: /kiku timer set <minutes>")

		"fragment":
			if args.size() >= 3 and args[1].to_lower() == "add":
				var count = args[2].to_int()
				send_response("Added %d Miku fragments (not fully implemented)" % count)
			else:
				send_error("Usage: /kiku fragment add <count>")

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
	Usage: /help OR /help <command> OR /help <category>"""
	if args.size() == 0:
		# Show compact command list
		send_response("=== CHEAT COMMANDS ===")
		send_response("📌 POPULAR:")
		send_response("  /god - God mode | /stats max - Max stats")
		send_response("  /give $ 999999 - Get gold | /tp <biome>")
		send_response("  /kill <enemy> <radius> | /summon")
		send_response("")
		send_response("📂 CATEGORIES: (use /help <category>)")
		send_response("  game | god | stats | combat | inventory")
		send_response("  movement | spawn | revive | time | info")
		send_response("")
		send_response("💡 Examples:")
		send_response("  /help god - Show god mode commands")
		send_response("  /help tp - Show teleport help")
	else:
		# Show detailed help for specific command or category
		var arg = args[0].to_lower()
		show_command_help(arg)


func show_command_help(cmd: String):
	"""Show detailed help for a specific command or category"""
	match cmd:
		# === CATEGORIES ===
		"game":
			send_response("=== GAME CONTROL ===")
			send_response("/pause - Pause game")
			send_response("/continue - Resume game")
			send_response("/suicide - Kill yourself")

		"god":
			send_response("=== GOD MODE ===")
			send_response("/god [time] - Enable god mode")
			send_response("  Examples: /god, /god 5mins, /god infinite")
			send_response("/ungod - Disable god mode")

		"stats":
			send_response("=== STATS ===")
			send_response("/hp <amt> <true/false> - Set HP + invincibility")
			send_response("/mana <amt> <true/false> - Set Mana")
			send_response("/addxp <amt> - Add XP")
			send_response("/addxp to reach lvl <X> - Level up")
			send_response("/level set <X> - Set level")
			send_response("/stats reset|max - Reset or max stats")
			send_response("/damage set <X> - Set damage")

		"combat":
			send_response("=== COMBAT ===")
			send_response("/kill <enemy> <radius> - Kill enemies")
			send_response("  /kill zombie 20 - Kill zombies in radius")
			send_response("  /kill 50 - Kill all in radius")
			send_response("/killall - Kill all enemies")

		"inventory":
			send_response("=== INVENTORY ===")
			send_response("/clearinv [slot] - Clear inventory")
			send_response("/give $ <amount> - Give gold")
			send_response("/give <weapon> <amt> - Give weapon")

		"movement":
			send_response("=== MOVEMENT ===")
			send_response("/tp <x> <y> - Teleport to coords")
			send_response("/tp <biome> - Teleport to biome area")
			send_response("  Biomes: forest, desert, tundra, volcanic, temple")
			send_response("  ⚠️ Biomes use procedural generation - positions vary by seed")
			send_response("  TIP: Use /biome info after teleport to check biome")
			send_response("/tprandom <radius> - Random teleport")

		"spawn":
			send_response("=== SPAWN ENEMIES ===")
			send_response("/summon @player <enemy> <count> [time]")
			send_response("  Basic: zombie, skeleton_bad, skeleton_buff")
			send_response("  anime_ghost, dark_kiku")
			send_response("  Desert: desert_nomad, skeleton_camel")
			send_response("  Tundra: ice_golem, snowdwarf_traitor, snowman_warrior")
			send_response("  Volcanic: lava_elemental, magma_slime")
			send_response("  Temple: vampire_bat")
			send_response("  Bosses: fire_dragon, vampire_lord, despair_kiku")

		"revive":
			send_response("=== REVIVE ===")
			send_response("/revive - Revive with full HP/Mana")
			send_response("/revivegod [time] - Revive with god mode")

		"time":
			send_response("=== TIME & SPEED ===")
			send_response("/time set <sec> - Set game time")
			send_response("/time add <sec> - Add time")
			send_response("/speed <X> - Change game speed (0.1-5.0)")
			send_response("/speed normal - Reset speed")

		"info":
			send_response("=== INFO & DEBUG ===")
			send_response("/info player - Show player stats")
			send_response("/biome info - Show current biome")
			send_response("/biome list - List all biomes")
			send_response("/debug fps|hitbox|enemy - Toggle debug")
			send_response("/save - Save game")
			send_response("/load - Load game")

		# === SPECIFIC COMMANDS ===
		"tp", "teleport":
			send_response("/tp <x> <y> OR /tp <biome> - Teleport")
			send_response("Examples: /tp 4500 0, /tp blood temple")

		"hp":
			send_response("/hp <amount> <true/false> - Set HP")
			send_response("  true = invincible, false = normal")
			send_response("Examples: /hp 1000 true, /hp 500 false")

		"kill":
			send_response("/kill <enemy> <radius> - Kill enemies")
			send_response("Examples:")
			send_response("  /kill zombie 20 - Zombies in radius 20")
			send_response("  /kill 50 - All enemies in radius 50")
			send_response("  /kill anime ghost - All anime ghosts (no limit)")

		"summon":
			send_response("/summon @player <enemy> <count> [time]")
			send_response("Examples:")
			send_response("  /summon @player zombie 10")
			send_response("  /summon @player zombie 10 30sec")
			send_response("  /summon @4500 0 fire_dragon 1")

		"give":
			send_response("/give $ <amount> OR /give <weapon> <amount>")
			send_response("Examples:")
			send_response("  /give $ 1000000 - Give gold")
			send_response("  /give kiku_sword 1 - Give weapon")

		_:
			send_error("Unknown command/category: " + cmd)
			send_response("Try: /help (show all categories)")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 16: MUSIC SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_song(args: Array):
	"""Song control commands
	Usage: /song <name> [loop] [count] OR /song list OR /song random OR /song break"""
	if args.size() < 1:
		send_error("Usage: /song <name|list|random|break> [loop] [count]")
		return

	var subcommand = args[0].to_lower()

	match subcommand:
		"list":
			show_song_list()

		"random":
			play_random_song()

		"break":
			stop_song_loop()

		_:
			# /song <name> [loop] [count]
			var song_name = args[0].to_lower()
			var is_loop = false
			var loop_count = 0

			# Check for "loop" parameter
			if args.size() >= 2 and args[1].to_lower() == "loop":
				is_loop = true

				# Check for loop count
				if args.size() >= 3:
					loop_count = args[2].to_int()
					if loop_count <= 0:
						send_error("Loop count must be > 0")
						return

			play_song(song_name, is_loop, loop_count)

func show_song_list():
	"""Show all available songs"""
	if not AudioManager:
		send_error("AudioManager not found")
		return

	send_response("=== AVAILABLE SONGS ===")

	var songs = AudioManager.music_tracks.keys()
	songs.sort()

	for i in range(songs.size()):
		var song = songs[i]
		var number = i + 1
		send_response("%d. %s" % [number, song])

	send_response("Total: %d songs" % songs.size())
	send_response("Usage: /song <name> [loop] [count]")

func play_song(song_name: String, is_loop: bool = false, loop_count: int = 0):
	"""Play a song with optional looping"""
	if not AudioManager:
		send_error("AudioManager not found")
		return

	# Check if song exists
	if not song_name in AudioManager.music_tracks:
		send_error("Song not found: " + song_name)
		send_response("[HINT] Use /song list to see all songs")
		return

	# Stop current loop if any
	if is_song_looping:
		stop_song_loop()

	# Play song
	AudioManager.play_music(song_name)
	send_response("[♪] Playing: " + song_name)

	# Setup looping
	if is_loop:
		is_song_looping = true
		current_loop_song = song_name
		song_loop_count = 0
		song_loop_max = loop_count

		if loop_count > 0:
			send_response("[♪] Looping %d times" % loop_count)
		else:
			send_response("[♪] Looping infinitely (use /song break to stop)")

		# Start loop monitoring
		start_song_loop()

func start_song_loop():
	"""Start monitoring for song end to loop"""
	if not is_song_looping:
		return

	# Wait for current song to end
	var music_player = AudioManager.current_music_player
	if not music_player:
		return

	# Get song duration
	if music_player.stream:
		var duration = music_player.stream.get_length()

		# Wait for song to finish
		await get_tree().create_timer(duration).timeout

		# Check if still should loop
		if is_song_looping:
			song_loop_count += 1

			# Check loop limit
			if song_loop_max > 0 and song_loop_count >= song_loop_max:
				send_response("[♪] Loop complete (%d times)" % song_loop_max)
				stop_song_loop()
				return

			# Loop again
			AudioManager.play_music(current_loop_song)

			if song_loop_max > 0:
				send_response("[♪] Loop %d/%d" % [song_loop_count + 1, song_loop_max])
			else:
				send_response("[♪] Loop %d" % (song_loop_count + 1))

			# Continue looping
			start_song_loop()

func stop_song_loop():
	"""Stop current song loop"""
	if not is_song_looping:
		send_response("[INFO] No song is looping")
		return

	is_song_looping = false
	send_response("[♪] Stopped looping: " + current_loop_song)
	current_loop_song = ""
	song_loop_count = 0
	song_loop_max = 0

func play_random_song():
	"""Play a random song"""
	if not AudioManager:
		send_error("AudioManager not found")
		return

	var songs = AudioManager.music_tracks.keys()
	if songs.is_empty():
		send_error("No songs available")
		return

	var random_song = songs[randi() % songs.size()]
	play_song(random_song)

func cmd_music(args: Array):
	"""Music volume and control commands
	Usage: /music mute OR /music unmute OR /music volume <0-100>"""
	if args.size() < 1:
		send_error("Usage: /music <mute|unmute|volume>")
		return

	var subcommand = args[0].to_lower()

	match subcommand:
		"mute":
			if AudioManager:
				AudioManager.set_music_volume(0.0)
				send_response("[♪] Music muted")

		"unmute":
			if AudioManager:
				AudioManager.set_music_volume(0.7)  # Default 70%
				send_response("[♪] Music unmuted (70%)")

		"volume":
			if args.size() < 2:
				send_error("Usage: /music volume <0-100>")
				return

			var volume = args[1].to_int()
			if volume < 0 or volume > 100:
				send_error("Volume must be 0-100")
				return

			if AudioManager:
				AudioManager.set_music_volume(volume / 100.0)
				send_response("[♪] Music volume: %d%%" % volume)

		_:
			send_error("Unknown music command: " + subcommand)

func cmd_sfx(args: Array):
	"""SFX volume and control commands
	Usage: /sfx mute OR /sfx unmute OR /sfx volume <0-100>"""
	if args.size() < 1:
		send_error("Usage: /sfx <mute|unmute|volume>")
		return

	var subcommand = args[0].to_lower()

	match subcommand:
		"mute":
			if AudioManager:
				AudioManager.set_sfx_volume(0.0)
				send_response("[🔊] SFX muted")

		"unmute":
			if AudioManager:
				AudioManager.set_sfx_volume(1.0)  # Default 100%
				send_response("[🔊] SFX unmuted")

		"volume":
			if args.size() < 2:
				send_error("Usage: /sfx volume <0-100>")
				return

			var volume = args[1].to_int()
			if volume < 0 or volume > 100:
				send_error("Volume must be 0-100")
				return

			if AudioManager:
				AudioManager.set_sfx_volume(volume / 100.0)
				send_response("[🔊] SFX volume: %d%%" % volume)

		_:
			send_error("Unknown sfx command: " + subcommand)

func cmd_playlist(args: Array):
	"""Playlist management commands
	Usage: /playlist add <song> OR /playlist play OR /playlist clear OR /playlist show"""
	if args.size() < 1:
		send_error("Usage: /playlist <add|play|clear|show>")
		return

	var action = args[0].to_lower()

	match action:
		"add":
			if args.size() < 2:
				send_error("Usage: /playlist add <song>")
				return

			var song = args[1].to_lower()
			if song in AudioManager.music_tracks:
				song_queue.append(song)
				send_response("[♪] Added to queue: " + song)
			else:
				send_error("Song not found: " + song)

		"play":
			play_playlist()

		"clear":
			song_queue.clear()
			send_response("[♪] Queue cleared")

		"show":
			if song_queue.is_empty():
				send_response("[INFO] Queue is empty")
			else:
				send_response("=== QUEUE ===")
				for i in range(song_queue.size()):
					send_response("%d. %s" % [i + 1, song_queue[i]])

		_:
			send_error("Unknown playlist action: " + action)

func play_playlist():
	"""Play queued songs"""
	if song_queue.is_empty():
		send_error("Queue is empty")
		return

	var song = song_queue[0]
	song_queue.remove_at(0)

	AudioManager.play_music(song)
	send_response("[♪] Playing: " + song)
	send_response("[♪] %d songs remaining in queue" % song_queue.size())

	# Auto-play next after song ends
	if not song_queue.is_empty():
		var music_player = AudioManager.current_music_player
		if music_player and music_player.stream:
			var duration = music_player.stream.get_length()
			await get_tree().create_timer(duration).timeout
			if not song_queue.is_empty():
				play_playlist()

func cmd_queue(args: Array):
	"""Quick queue multiple songs
	Usage: /queue <song1> [song2] [song3]..."""
	if args.size() < 1:
		send_error("Usage: /queue <song1> [song2] [song3]...")
		return

	var added = 0
	for i in range(args.size()):
		var song = args[i].to_lower()
		if song in AudioManager.music_tracks:
			song_queue.append(song)
			added += 1

	send_response("[♪] Added %d songs to queue" % added)

	# Auto-play if not playing
	var music_player = AudioManager.current_music_player
	if not music_player.playing:
		play_playlist()

func cmd_shuffle():
	"""Toggle shuffle mode"""
	is_shuffling = !is_shuffling

	if is_shuffling:
		send_response("[♪] Shuffle: ON")
		send_response("[HINT] Songs will play randomly")
	else:
		send_response("[♪] Shuffle: OFF")

func cmd_skip():
	"""Skip current song"""
	if song_queue.is_empty():
		send_error("No songs in queue to skip to")
		return

	play_playlist()
	send_response("[♪] Skipped to next song")


# ═══════════════════════════════════════════════════════════════════════════════
# CATEGORY 17: BOSS COMMANDS
# ═══════════════════════════════════════════════════════════════════════════════

func cmd_boss(args: Array):
	"""Boss management and debugging commands
	Usage: /boss list OR /boss reset OR /boss spawn <name>"""
	if args.size() < 1:
		send_error("Usage: /boss <list|reset|spawn>")
		return

	var action = args[0].to_lower()

	match action:
		"list":
			list_active_bosses()

		"reset":
			reset_boss_flags()

		"spawn":
			if args.size() < 2:
				send_error("Usage: /boss spawn <fire_dragon|vampire_lord>")
				return

			var boss_name = args[1].to_lower()
			force_spawn_boss(boss_name)

		_:
			send_error("Unknown boss command: " + action)

func list_active_bosses():
	"""List all active bosses and their positions"""
	var boss_manager = get_tree().get_first_node_in_group("boss_manager")
	if not boss_manager:
		send_error("BossManager not found")
		return

	send_response("=== ACTIVE BOSSES ===")

	var active_boss = boss_manager.get_active_boss()
	if active_boss:
		send_response("Boss: %s" % active_boss.name)
		send_response("Position: (%.0f, %.0f)" % [active_boss.global_position.x, active_boss.global_position.y])
		send_response("HP: %.0f / %.0f" % [active_boss.current_hp, active_boss.max_hp])

		if player:
			var distance = player.global_position.distance_to(active_boss.global_position)
			send_response("Distance from player: %.0f units" % distance)
	else:
		send_response("No active bosses")

	# Show spawn flags
	send_response("")
	send_response("=== BOSS SPAWN FLAGS ===")
	var flags = boss_manager.boss_spawned_flags
	for biome_type in flags.keys():
		var biome_name = get_biome_type_name(biome_type)
		var spawned = flags[biome_type]
		send_response("%s: %s" % [biome_name, "SPAWNED" if spawned else "NOT SPAWNED"])

func reset_boss_flags():
	"""Reset all boss spawn flags"""
	var boss_manager = get_tree().get_first_node_in_group("boss_manager")
	if not boss_manager:
		send_error("BossManager not found")
		return

	boss_manager.reset_boss_flags()
	send_response("All boss flags reset!")
	send_response("[HINT] Bosses will respawn when you enter their zones")

func force_spawn_boss(boss_name: String):
	"""Force spawn a specific boss"""
	var boss_manager = get_tree().get_first_node_in_group("boss_manager")
	if not boss_manager:
		send_error("BossManager not found")
		return

	# Reset flags first
	boss_manager.reset_boss_flags()

	# Spawn based on name
	match boss_name:
		"fire_dragon", "firedragon", "dragon":
			boss_manager.spawn_fire_dragon()
			send_response("Spawned Fire Dragon at (0, 3500)")

		"vampire_lord", "vampirelord", "vampire":
			boss_manager.spawn_vampire_lord()
			send_response("Spawned Vampire Lord at (-3500, 0)")

		_:
			send_error("Unknown boss: " + boss_name)
			send_response("Available: fire_dragon, vampire_lord")

func get_biome_type_name(biome_type: int) -> String:
	"""Get biome type name from enum value"""
	match biome_type:
		0: return "Starting Forest"
		1: return "Desert Wasteland"
		2: return "Frozen Tundra"
		3: return "Volcanic Darklands"
		4: return "Blood Temple"
		_: return "Unknown"


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

func search_for_biome(biome_name: String) -> Vector2:
	"""Search for the nearest biome of the specified type using BiomeGenerator"""
	var biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if not biome_generator:
		send_error("BiomeGenerator not found")
		return Vector2.ZERO

	var lower = biome_name.to_lower().replace("_", " ")
	var target_biome_type = -1

	# Map biome names to BiomeType enum
	# Note: All biomes are procedurally generated, so we search for nearest instance
	if "forest" in lower or "starting" in lower:
		target_biome_type = 0  # BiomeType.STARTING_FOREST
	elif "desert" in lower or "wasteland" in lower:
		target_biome_type = 1  # BiomeType.DESERT_WASTELAND
	elif "tundra" in lower or "frozen" in lower:
		target_biome_type = 2  # BiomeType.FROZEN_TUNDRA
	elif "volcanic" in lower or "darkland" in lower:
		target_biome_type = 3  # BiomeType.VOLCANIC_DARKLANDS
	elif "blood" in lower or "temple" in lower:
		target_biome_type = 4  # BiomeType.BLOOD_TEMPLE
	else:
		return Vector2.ZERO

	# Start from player position
	var start_pos = player.global_position if player else Vector2.ZERO

	# Search in expanding circles from player
	send_response("[Searching for %s...]" % biome_name)

	for radius in [500, 1000, 1500, 2000, 3000, 4000, 5000, 6000]:
		for angle_deg in range(0, 360, 15):  # Check every 15 degrees
			var angle = deg_to_rad(angle_deg)
			var test_pos = start_pos + Vector2(cos(angle), sin(angle)) * radius
			var biome = biome_generator.get_biome_at_position(test_pos)

			if biome and biome.type == target_biome_type:
				send_response("[Found at distance: %.0f units]" % radius)
				return test_pos

	# If not found near player, search from world center
	send_response("[Expanding search from world center...]")
	for radius in [1000, 2000, 3000, 4000, 5000, 6000, 7000]:
		for angle_deg in range(0, 360, 20):
			var angle = deg_to_rad(angle_deg)
			var test_pos = Vector2(cos(angle), sin(angle)) * radius
			var biome = biome_generator.get_biome_at_position(test_pos)

			if biome and biome.type == target_biome_type:
				send_response("[Found at: (%.0f, %.0f)]" % [test_pos.x, test_pos.y])
				return test_pos

	return Vector2.ZERO

func tp_to_boss(boss_name: String):
	"""Teleport to exact boss spawn position"""
	var pos = Vector2.ZERO
	var boss_full_name = ""

	match boss_name:
		"vampire", "vampirelord", "vampire_lord":
			pos = Vector2(-3500, 0)
			boss_full_name = "Vampire Lord (Blood Temple Boss)"

		"dragon", "firedragon", "fire_dragon":
			pos = Vector2(0, 3500)
			boss_full_name = "Fire Dragon (Volcanic Darklands Boss)"

		_:
			send_error("Unknown boss: " + boss_name)
			send_response("Available bosses: vampire, dragon")
			return

	player.global_position = pos
	send_response("Teleported to %s at (%.0f, %.0f)" % [boss_full_name, pos.x, pos.y])

	# Update biome
	await get_tree().process_frame
	var biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if biome_generator and biome_generator.has_method("force_update_biome"):
		biome_generator.force_update_biome(player.global_position)

	# Check what biome we're actually in
	if biome_generator:
		var actual_biome = biome_generator.get_biome_at_position(pos)
		if actual_biome:
			send_response("[Current biome: %s]" % actual_biome.name)
			if boss_name.begins_with("vampire") and actual_biome.name != "Blood Temple":
				send_response("[WARNING: Boss spawn is NOT in Blood Temple biome in this world seed!]")
			elif boss_name.begins_with("dragon") or boss_name.begins_with("fire") and actual_biome.name != "Volcanic Darklands":
				send_response("[WARNING: Boss spawn is NOT in Volcanic Darklands biome in this world seed!]")

func get_biome_at_position(pos: Vector2) -> String:
	"""Get biome name at position (deprecated - use BiomeGenerator instead)"""
	var biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if biome_generator:
		var biome = biome_generator.get_biome_at_position(pos)
		if biome:
			return biome.name
	return "Unknown"

func get_biome_position(biome_name: String) -> Vector2:
	"""Get biome position - tries multiple locations to find the biome
	NOTE: Biomes are procedurally generated using noise, so positions vary by world seed.
	These coordinates are from boss spawn positions or likely biome areas."""
	var lower = biome_name.to_lower().replace("_", " ")

	# Starting Forest (spawn area - always forest within 600 units)
	if "forest" in lower or "starting" in lower:
		return Vector2(0, 0)

	# Desert Wasteland (hot+dry) - Try multiple far positions
	elif "desert" in lower or "wasteland" in lower:
		# Try southeast - hot dry biomes more common in positive x/y quadrants
		return Vector2(4000, 2000)

	# Frozen Tundra (very cold) - Try far north/northwest
	elif "tundra" in lower or "frozen" in lower:
		# Try north - cold biomes more common in negative y
		return Vector2(-1000, -4000)

	# Volcanic Darklands (extreme heat + very dry) - BOSS SPAWN POSITION
	elif "volcanic" in lower or "darkland" in lower:
		return Vector2(0, 3500)  # Boss spawn position

	# Blood Temple (cold + wet) - BOSS SPAWN POSITION
	elif "blood" in lower or "temple" in lower:
		return Vector2(-3500, 0)  # Boss spawn position

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

func is_boss_enemy(enemy_name: String) -> bool:
	"""Check if enemy is a boss"""
	var boss_names = ["fire_dragon", "vampire_lord", "pam_tung_ken", "despair_kiku", "dark_kiku"]
	var lower = enemy_name.to_lower().replace(" ", "_")
	return lower in boss_names

func play_boss_music(boss_name: String):
	"""Play boss music with random variant selection"""
	if not AudioManager:
		return

	var lower = boss_name.to_lower().replace(" ", "_")
	var music_key = ""

	match lower:
		"fire_dragon":
			music_key = "fire_dragon_boss"

		"vampire_lord":
			music_key = "vampire_lord_boss"

		"pam_tung_ken":
			music_key = "pam_boss"

		"dark_kiku":
			# 50% chance between two tracks
			if randf() < 0.5:
				music_key = "dark_kiku_boss"
			else:
				music_key = "dark_kiku_boss_alt"

		"despair_kiku":
			# 50% chance between two tracks
			if randf() < 0.5:
				music_key = "despair_kiku_boss"
			else:
				music_key = "despair_kiku_boss_alt"

	if music_key:
		AudioManager.play_music(music_key, 1.0)  # Faster fade for boss
		print("Playing boss music: ", music_key)

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
