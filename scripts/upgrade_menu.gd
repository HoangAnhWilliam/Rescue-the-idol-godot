extends CanvasLayer

# References
@onready var level_label = $Background/MenuPanel/Layout/LevelLabel
@onready var button1 = $Background/MenuPanel/Layout/UpgradeButton1
@onready var button2 = $Background/MenuPanel/Layout/UpgradeButton2
@onready var button3 = $Background/MenuPanel/Layout/UpgradeButton3

# Upgrade types - EXPANDED!
enum UpgradeType {
	WEAPON_LEVEL,
	MAX_HP,
	ATTACK_SPEED,
	MAX_MANA,
	MOVE_SPEED,
	HP_REGEN,
	CRIT_CHANCE,
	CRIT_DAMAGE,
	DAMAGE_BOOST,
	PICKUP_RANGE,
	COOLDOWN_REDUCTION,
	LIFESTEAL
}

# Current upgrades shown
var current_upgrades: Array[UpgradeType] = []
var player: CharacterBody2D

signal upgrade_chosen(type: UpgradeType)

func _ready():
	print("=== UPGRADE MENU INITIALIZATION ===")
	print("Node path: ", get_path())
	print("Is visible: ", visible)
	print("Process mode: ", process_mode)

	# Hide by default
	hide()
	print("Called hide() - Is visible: ", visible)

	# Connect button signals
	if button1:
		button1.pressed.connect(_on_button1_pressed)
		print("✅ Button1 connected")
	else:
		print("❌ Button1 is null!")

	if button2:
		button2.pressed.connect(_on_button2_pressed)
		print("✅ Button2 connected")
	else:
		print("❌ Button2 is null!")

	if button3:
		button3.pressed.connect(_on_button3_pressed)
		print("✅ Button3 connected")
	else:
		print("❌ Button3 is null!")

	print("✅ UpgradeMenu ready!")
	print("===================================")

func show_menu(player_ref: CharacterBody2D, level: int):
	print("")
	print("╔════════════════════════════════════╗")
	print("║   🎯 SHOWING UPGRADE MENU          ║")
	print("╚════════════════════════════════════╝")
	print("Level: ", level)
	print("Before show() - Is visible: ", visible)

	player = player_ref

	# Update level text
	if level_label:
		level_label.text = "Level %d" % level
		print("✅ Updated level label to: ", level_label.text)
	else:
		print("❌ level_label is null!")

	# Generate 3 random upgrades
	current_upgrades = generate_random_upgrades(3)
	print("✅ Generated upgrades: ", current_upgrades.size())

	# Update button texts
	if button1 and button2 and button3:
		button1.text = get_upgrade_text(current_upgrades[0])
		button2.text = get_upgrade_text(current_upgrades[1])
		button3.text = get_upgrade_text(current_upgrades[2])

		print("📋 Options:")
		print("  1. ", button1.text)
		print("  2. ", button2.text)
		print("  3. ", button3.text)
	else:
		print("❌ One or more buttons are null!")

	# FORCE SHOW - Try multiple methods
	visible = true
	print("Set visible = true")

	show()
	print("Called show()")

	print("After show() - Is visible: ", visible)
	print("Modulate: ", modulate)

	# PAUSE GAME
	get_tree().paused = true
	print("⏸️ Game PAUSED")
	print("╚════════════════════════════════════╝")
	print("")

func generate_random_upgrades(count: int) -> Array[UpgradeType]:
	var available = [
		UpgradeType.WEAPON_LEVEL,
		UpgradeType.MAX_HP,
		UpgradeType.ATTACK_SPEED,
		UpgradeType.MAX_MANA,
		UpgradeType.MOVE_SPEED,
		UpgradeType.HP_REGEN,
		UpgradeType.CRIT_CHANCE,
		UpgradeType.CRIT_DAMAGE,
		UpgradeType.DAMAGE_BOOST,
		UpgradeType.PICKUP_RANGE,
		UpgradeType.COOLDOWN_REDUCTION,
		UpgradeType.LIFESTEAL
	]

	# Shuffle and take first N
	available.shuffle()

	var result: Array[UpgradeType] = []
	for i in range(count):
		result.append(available[i])

	return result

func get_upgrade_text(type: UpgradeType) -> String:
	match type:
		UpgradeType.WEAPON_LEVEL:
			return "⚔️ Weapon Level +1"
		UpgradeType.MAX_HP:
			return "❤️ Max HP +20"
		UpgradeType.ATTACK_SPEED:
			return "⚡ Attack Speed +10%"
		UpgradeType.MAX_MANA:
			return "💧 Max Mana +10"
		UpgradeType.MOVE_SPEED:
			return "👟 Move Speed +10%"
		UpgradeType.HP_REGEN:
			return "💚 HP Regen +50%"
		UpgradeType.CRIT_CHANCE:
			return "💥 Crit Chance +5%"
		UpgradeType.CRIT_DAMAGE:
			return "💢 Crit Damage +20%"
		UpgradeType.DAMAGE_BOOST:
			return "🗡️ Base Damage +15%"
		UpgradeType.PICKUP_RANGE:
			return "🧲 Pickup Range +50%"
		UpgradeType.COOLDOWN_REDUCTION:
			return "⏱️ Cooldown -10%"
		UpgradeType.LIFESTEAL:
			return "🩸 Lifesteal +5%"

	return "Unknown"

func apply_upgrade(type: UpgradeType):
	if not player:
		print("❌ ERROR: No player reference!")
		return

	print("✨ Applying upgrade: ", UpgradeType.keys()[type])

	match type:
		UpgradeType.WEAPON_LEVEL:
			if "current_weapon" in player and player.current_weapon:
				if player.current_weapon.has_method("upgrade"):
					player.current_weapon.upgrade()
					print("✅ Weapon upgraded!")
				else:
					print("⚠️ Weapon has no upgrade method")

		UpgradeType.MAX_HP:
			if "stats" in player:
				player.stats.max_hp += 20
				if "current_hp" in player:
					player.current_hp += 20
				if player.has_signal("hp_changed"):
					player.hp_changed.emit(player.current_hp, player.stats.max_hp)
				print("✅ Max HP increased to ", player.stats.max_hp)

		UpgradeType.ATTACK_SPEED:
			if "stats" in player:
				player.stats.attack_speed *= 1.1
				print("✅ Attack speed: ", player.stats.attack_speed)

		UpgradeType.MAX_MANA:
			if "stats" in player:
				player.stats.max_mana += 10
				if "current_mana" in player:
					player.current_mana += 10
				if player.has_signal("mana_changed"):
					player.mana_changed.emit(player.current_mana, player.stats.max_mana)
				print("✅ Max mana: ", player.stats.max_mana)

		UpgradeType.MOVE_SPEED:
			if "stats" in player:
				player.stats.move_speed *= 1.1
				print("✅ Move speed: ", player.stats.move_speed)

		UpgradeType.HP_REGEN:
			if "stats" in player:
				player.stats.hp_regen_per_second *= 1.5
				print("✅ HP regen: ", player.stats.hp_regen_per_second)

		UpgradeType.CRIT_CHANCE:
			if "stats" in player:
				player.stats.crit_chance += 0.05
				print("✅ Crit chance: ", player.stats.crit_chance * 100, "%")

		UpgradeType.CRIT_DAMAGE:
			if "stats" in player:
				player.stats.crit_multiplier += 0.2
				print("✅ Crit multiplier: x", player.stats.crit_multiplier)

		UpgradeType.DAMAGE_BOOST:
			if "stats" in player:
				player.stats.base_damage *= 1.15
				print("✅ Base damage: ", player.stats.base_damage)

		UpgradeType.PICKUP_RANGE:
			if "stats" in player:
				player.stats.pickup_range *= 1.5
				print("✅ Pickup range: ", player.stats.pickup_range)

		UpgradeType.COOLDOWN_REDUCTION:
			if "stats" in player:
				player.stats.cooldown_reduction = min(player.stats.cooldown_reduction + 0.1, 0.5)
				print("✅ Cooldown reduction: ", player.stats.cooldown_reduction * 100, "%")

		UpgradeType.LIFESTEAL:
			if "stats" in player:
				player.stats.lifesteal += 0.05
				print("✅ Lifesteal: ", player.stats.lifesteal * 100, "%")

	# Emit signal
	upgrade_chosen.emit(type)

	# Hide menu and resume game
	hide()
	get_tree().paused = false
	print("▶️ Game RESUMED")
	print("========================")

# Button handlers
func _on_button1_pressed():
	print("🔘 Player chose option 1:", get_upgrade_text(current_upgrades[0]))
	apply_upgrade(current_upgrades[0])

func _on_button2_pressed():
	print("🔘 Player chose option 2:", get_upgrade_text(current_upgrades[1]))
	apply_upgrade(current_upgrades[1])

func _on_button3_pressed():
	print("🔘 Player chose option 3:", get_upgrade_text(current_upgrades[2]))
	apply_upgrade(current_upgrades[2])
