extends CanvasLayer

# References
@onready var level_label = $Background/MenuPanel/Layout/LevelLabel
@onready var button1 = $Background/MenuPanel/Layout/UpgradeButton1
@onready var button2 = $Background/MenuPanel/Layout/UpgradeButton2
@onready var button3 = $Background/MenuPanel/Layout/UpgradeButton3

# Upgrade types
enum UpgradeType {
	WEAPON_LEVEL,
	MAX_HP,
	ATTACK_SPEED,
	MAX_MANA,
	MOVE_SPEED,
	HP_REGEN,
	CRIT_CHANCE
}

# Current upgrades shown
var current_upgrades: Array[UpgradeType] = []
var player: Player

signal upgrade_chosen(type: UpgradeType)

func _ready():
	# Hide by default
	hide()
	
	# Connect button signals
	button1.pressed.connect(_on_button1_pressed)
	button2.pressed.connect(_on_button2_pressed)
	button3.pressed.connect(_on_button3_pressed)
	
	print("UpgradeMenu ready!")

func show_menu(player_ref: Player, level: int):
	player = player_ref
	
	# Update level text
	level_label.text = "Level %d" % level
	
	# Generate 3 random upgrades
	current_upgrades = generate_random_upgrades(3)
	
	# Update button texts
	button1.text = get_upgrade_text(current_upgrades[0])
	button2.text = get_upgrade_text(current_upgrades[1])
	button3.text = get_upgrade_text(current_upgrades[2])
	
	# Show menu
	show()
	
	print("Showing upgrade menu for level ", level)

func generate_random_upgrades(count: int) -> Array[UpgradeType]:
	var available = [
		UpgradeType.WEAPON_LEVEL,
		UpgradeType.MAX_HP,
		UpgradeType.ATTACK_SPEED,
		UpgradeType.MAX_MANA,
		UpgradeType.MOVE_SPEED,
		UpgradeType.HP_REGEN,
		UpgradeType.CRIT_CHANCE
	]
	
	# Shuffle and take first 3
	available.shuffle()
	
	var result: Array[UpgradeType] = []
	for i in range(count):
		result.append(available[i])
	
	return result

func get_upgrade_text(type: UpgradeType) -> String:
	match type:
		UpgradeType.WEAPON_LEVEL:
			return "⚔ Weapon Level +1"
		UpgradeType.MAX_HP:
			return "❤ Max HP +20"
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
	
	return "Unknown"

func apply_upgrade(type: UpgradeType):
	if not player:
		print("ERROR: No player reference!")
		return
	
	print("Applying upgrade: ", UpgradeType.keys()[type])
	
	match type:
		UpgradeType.WEAPON_LEVEL:
			if player.current_weapon and player.current_weapon.has_method("upgrade"):
				player.current_weapon.upgrade()
				print("Weapon upgraded!")
		
		UpgradeType.MAX_HP:
			player.stats.max_hp += 20
			player.current_hp += 20
			player.hp_changed.emit(player.current_hp, player.stats.max_hp)
			print("Max HP increased to ", player.stats.max_hp)
		
		UpgradeType.ATTACK_SPEED:
			player.stats.attack_speed *= 1.1
			print("Attack speed increased to ", player.stats.attack_speed)
		
		UpgradeType.MAX_MANA:
			player.stats.max_mana += 10
			player.current_mana += 10
			player.mana_changed.emit(player.current_mana, player.stats.max_mana)
			print("Max mana increased to ", player.stats.max_mana)
		
		UpgradeType.MOVE_SPEED:
			player.stats.move_speed *= 1.1
			print("Move speed increased to ", player.stats.move_speed)
		
		UpgradeType.HP_REGEN:
			player.stats.hp_regen_per_second *= 1.5
			print("HP regen increased to ", player.stats.hp_regen_per_second)
		
		UpgradeType.CRIT_CHANCE:
			player.stats.crit_chance += 0.05
			print("Crit chance increased to ", player.stats.crit_chance * 100, "%")
	
	# Emit signal
	upgrade_chosen.emit(type)
	
	# Hide menu and resume game
	hide()
	get_tree().paused = false

# Button handlers
func _on_button1_pressed():
	apply_upgrade(current_upgrades[0])

func _on_button2_pressed():
	apply_upgrade(current_upgrades[1])

func _on_button3_pressed():
	apply_upgrade(current_upgrades[2])
