extends Control

# References to UI elements
@onready var hp_bar = $StatsContainer/HPContainer/HPBar
@onready var mana_bar = $StatsContainer/ManaContainer/ManaBar
@onready var xp_bar = $StatsContainer/XPContainer/XPBar
@onready var level_label = $StatsContainer/XPContainer/LevelLabel
@onready var kill_label = $InfoContainer/KillLabel
@onready var time_label = $InfoContainer/TimeLabel

var player: Player
var game_time: float = 0.0

func _ready():
	# Wait 1 frame for player to spawn
	await get_tree().process_frame
	
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print("ERROR: HUD cannot find player!")
		return
	
	print("HUD connected to player!")
	
	# Connect signals
	player.hp_changed.connect(_on_hp_changed)
	player.mana_changed.connect(_on_mana_changed)
	player.xp_gained.connect(_on_xp_gained)
	player.level_up.connect(_on_level_up)
	
	# Initialize bars
	update_hp(player.current_hp, player.stats.max_hp)
	update_mana(player.current_mana, player.stats.max_mana)
	update_xp(player.current_xp, player.xp_to_next_level)
	update_level(player.level)

func _process(delta):
	# Update game time
	game_time += delta
	var minutes = int(game_time / 60)
	var seconds = int(game_time) % 60
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
	
	# Update kill count
	if player:
		kill_label.text = "Kills: %d" % player.total_kills

# Signal handlers
func _on_hp_changed(current: float, maximum: float):
	update_hp(current, maximum)

func _on_mana_changed(current: float, maximum: float):
	update_mana(current, maximum)

func _on_xp_gained(_amount: float):
	if player:
		update_xp(player.current_xp, player.xp_to_next_level)

func _on_level_up(new_level: int):
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
