extends Control

# References to UI elements
@onready var hp_bar = $StatsContainer/HPContainer/HPBar
@onready var mana_bar = $StatsContainer/ManaContainer/ManaBar
@onready var xp_bar = $StatsContainer/XPContainer/XPBar
@onready var level_label = $StatsContainer/XPContainer/LevelLabel
@onready var kill_label = $InfoContainer/KillLabel
@onready var time_label = $InfoContainer/TimeLabel

var player: CharacterBody2D
var game_time: float = 0.0

func _ready():
	print("=== HUD INITIALIZATION ===")

	# Wait 1 frame for player to spawn
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")

	if not player:
		print("❌ ERROR: HUD cannot find player!")
		return

	print("✅ HUD found player: ", player.name)

	# Connect signals with error checking
	if player.has_signal("hp_changed"):
		player.hp_changed.connect(_on_hp_changed)
		print("✅ Connected hp_changed signal")
	else:
		print("❌ Player missing hp_changed signal!")

	if player.has_signal("mana_changed"):
		player.mana_changed.connect(_on_mana_changed)
		print("✅ Connected mana_changed signal")
	else:
		print("❌ Player missing mana_changed signal!")

	if player.has_signal("xp_gained"):
		player.xp_gained.connect(_on_xp_gained)
		print("✅ Connected xp_gained signal")
	else:
		print("❌ Player missing xp_gained signal!")

	if player.has_signal("level_up"):
		player.level_up.connect(_on_level_up)
		print("✅ Connected level_up signal")
	else:
		print("❌ Player missing level_up signal!")

	# Initialize bars
	if "current_hp" in player and "stats" in player:
		update_hp(player.current_hp, player.stats.max_hp)
		print("✅ Initialized HP: ", player.current_hp, "/", player.stats.max_hp)

	if "current_mana" in player and "stats" in player:
		update_mana(player.current_mana, player.stats.max_mana)
		print("✅ Initialized Mana: ", player.current_mana, "/", player.stats.max_mana)

	if "current_xp" in player and "xp_to_next_level" in player:
		update_xp(player.current_xp, player.xp_to_next_level)
		print("✅ Initialized XP: ", player.current_xp, "/", player.xp_to_next_level)

	if "level" in player:
		update_level(player.level)
		print("✅ Initialized Level: ", player.level)

	print("=========================")

func _process(delta):
	# Update game time
	game_time += delta
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]

	# Update kill count
	if player and "total_kills" in player:
		kill_label.text = "Kills: %d" % player.total_kills

# Signal handlers
func _on_hp_changed(current: float, maximum: float):
	print("📊 HP changed: ", current, "/", maximum)
	update_hp(current, maximum)

func _on_mana_changed(current: float, maximum: float):
	print("📊 Mana changed: ", current, "/", maximum)
	update_mana(current, maximum)

func _on_xp_gained(_amount: float):
	print("📊 XP gained: ", _amount)
	if player:
		update_xp(player.current_xp, player.xp_to_next_level)

func _on_level_up(new_level: int):
	print("⭐ Level up! New level: ", new_level)
	update_level(new_level)
	if player:
		update_xp(player.current_xp, player.xp_to_next_level)

# Update functions
func update_hp(current: float, maximum: float):
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current

func update_mana(current: float, maximum: float):
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current

func update_xp(current: float, maximum: float):
	if xp_bar:
		xp_bar.max_value = maximum
		xp_bar.value = current

func update_level(level: int):
	if level_label:
		level_label.text = "LV %d - XP:" % level
