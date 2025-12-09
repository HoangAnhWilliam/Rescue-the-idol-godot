extends Control

# References to UI elements
@onready var hp_bar = $StatsContainer/HPContainer/HPBar
@onready var mana_bar = $StatsContainer/ManaContainer/ManaBar
@onready var xp_bar = $StatsContainer/XPContainer/XPBar
@onready var level_label = $StatsContainer/XPContainer/LevelLabel
@onready var gold_label = $InfoContainer/GoldLabel
@onready var kill_label = $InfoContainer/KillLabel
@onready var time_label = $InfoContainer/TimeLabel
@onready var biome_label = $InfoContainer/BiomeLabel
@onready var coords_label = $InfoContainer/CoordsLabel
@onready var effect_label = $InfoContainer/EffectLabel if has_node("InfoContainer/EffectLabel") else null

var player: CharacterBody2D
var game_time: float = 0.0
var biome_generator: BiomeGenerator
var environmental_effects: EnvironmentalEffects
var boss_manager: BossManager

# Boss health bar references
@onready var boss_health_bar = $BossHealthBar if has_node("BossHealthBar") else null
@onready var boss_name_label = $BossHealthBar/VBoxContainer/BossNameLabel if has_node("BossHealthBar/VBoxContainer/BossNameLabel") else null
@onready var boss_hp_bar = $BossHealthBar/VBoxContainer/HPBarContainer/BossHPBar if has_node("BossHealthBar/VBoxContainer/HPBarContainer/BossHPBar") else null
@onready var boss_hp_label = $BossHealthBar/VBoxContainer/HPBarContainer/HPLabel if has_node("BossHealthBar/VBoxContainer/HPBarContainer/HPLabel") else null
@onready var boss_phase_label = $BossHealthBar/VBoxContainer/PhaseLabel if has_node("BossHealthBar/VBoxContainer/PhaseLabel") else null

# Kiku Quest UI
@onready var chat_box = $ChatBox if has_node("ChatBox") else null
@onready var chat_indicator = $ChatIndicator if has_node("ChatIndicator") else null
@onready var kiku_fragment_bar = $KikuFragmentBar if has_node("KikuFragmentBar") else null

var current_boss: Node = null

func _ready():
	print("=== HUD INITIALIZATION ===")

	# Wait 1 frame for player to spawn
	await get_tree().process_frame

	# Find player
	player = get_tree().get_first_node_in_group("player")

	# Find biome manager
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	if biome_generator:
		biome_generator.biome_changed.connect(_on_biome_changed)
		print("HUD connected to BiomeManager")

	# Find environmental effects
	environmental_effects = get_tree().get_first_node_in_group("environmental_effects")
	if environmental_effects:
		environmental_effects.effect_added.connect(_on_effect_added)
		environmental_effects.effect_removed.connect(_on_effect_removed)
		print("HUD connected to EnvironmentalEffects")

	# Find boss manager
	boss_manager = get_tree().get_first_node_in_group("boss_manager")
	if boss_manager:
		boss_manager.boss_spawned.connect(_on_boss_spawned)
		boss_manager.boss_defeated.connect(_on_boss_defeated)
		boss_manager.boss_phase_changed.connect(_on_boss_phase_changed)
		print("HUD connected to BossManager")

	# Hide boss health bar initially
	if boss_health_bar:
		boss_health_bar.visible = false

	# Setup chat indicator click handler
	if chat_indicator:
		chat_indicator.gui_input.connect(_on_chat_indicator_input)

	# Find inventory system (Phase 5.5.8)
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory:
		inventory.slot_changed.connect(_on_inventory_slot_changed)
		print("HUD connected to InventorySystem")
		# Initial gold update
		update_gold_display()

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

	if player.has_signal("gold_changed"):
		player.gold_changed.connect(_on_gold_changed)
		print("✅ Connected gold_changed signal")
	else:
		print("❌ Player missing gold_changed signal!")

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

	if "gold" in player:
		update_gold(player.gold)
		print("✅ Initialized Gold: ", player.gold)

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

	# NOTE: Gold display now handled by inventory system (update_gold_display)
	# Removed old player.gold code that was overwriting inventory gold

	# Update coordinates
	if player:
		var pos = player.global_position
		coords_label.text = "Pos: %.0f, %.0f" % [pos.x, pos.y]

		# Update biome (nếu chưa có signal)
		if biome_generator:
			var current_biome = biome_generator.get_current_biome()
			if current_biome:
				biome_label.text = "Biome: " + current_biome.name
				biome_label.modulate = current_biome.color

	# Update boss health bar
	if current_boss and is_instance_valid(current_boss):
		update_boss_health_bar()

	# Update chat indicator visibility
	if chat_box and chat_indicator:
		# Hide indicator when chat is open
		chat_indicator.visible = not chat_box.is_chat_open

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

func _on_gold_changed(current_gold: int):
	print("💰 Gold changed: ", current_gold)
	update_gold(current_gold)

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

func update_gold(gold: int):
	if gold_label:
		gold_label.text = "Gold: %d" % gold

# Thêm hàm mới:
func _on_biome_changed(old_biome, new_biome):
	if new_biome:
		biome_label.text = "Biome: " + new_biome.name
		biome_label.modulate = new_biome.color

		# Flash effect
		var tween = create_tween()
		tween.tween_property(biome_label, "scale", Vector2(1.2, 1.2), 0.2)
		tween.tween_property(biome_label, "scale", Vector2(1.0, 1.0), 0.2)

# NEW: Environmental effect handlers
func _on_effect_added(effect_name: String):
	print("✨ Effect added to HUD: ", effect_name)
	update_effect_display()

func _on_effect_removed(effect_name: String):
	print("✨ Effect removed from HUD: ", effect_name)
	update_effect_display()

func update_effect_display():
	if not effect_label or not environmental_effects:
		return

	var active_effects = environmental_effects.get_active_effects()

	if active_effects.is_empty():
		effect_label.text = ""
		effect_label.visible = false
		return

	# Build effect display string
	var effect_text = "Effects: "
	var effect_descriptions = []

	for effect in active_effects:
		var desc = environmental_effects.get_effect_description(effect)
		if desc != "":
			effect_descriptions.append(desc)

	effect_text += " | ".join(effect_descriptions)

	effect_label.text = effect_text
	effect_label.visible = true

	print("📊 Effect display updated: ", effect_text)

# ========== BOSS HEALTH BAR FUNCTIONS ==========

func _on_boss_spawned(boss_type: String, boss: Node):
	print("👹 Boss spawned: ", boss_type)
	current_boss = boss

	# Show boss health bar
	if boss_health_bar:
		boss_health_bar.visible = true

	# Set boss name
	if boss_name_label:
		boss_name_label.text = boss_type

	# Initialize boss HP bar
	if boss_hp_bar and "max_hp" in boss:
		boss_hp_bar.max_value = boss.max_hp
		boss_hp_bar.value = boss.current_hp

	# Set initial phase
	if boss_phase_label and "current_phase" in boss:
		var phase_num = boss.current_phase + 1
		boss_phase_label.text = "Phase %d" % phase_num

	print("✅ Boss health bar initialized")

func _on_boss_defeated(boss_type: String):
	print("💀 Boss defeated: ", boss_type)
	current_boss = null

	# Hide boss health bar with fade out
	if boss_health_bar:
		var tween = create_tween()
		tween.tween_property(boss_health_bar, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): boss_health_bar.visible = false)
		tween.tween_callback(func(): boss_health_bar.modulate.a = 1.0)

func _on_boss_phase_changed(boss: Node, phase: int):
	print("🔥 Boss phase changed to: ", phase)

	# Update phase label
	if boss_phase_label:
		boss_phase_label.text = "Phase %d" % phase

		# Flash effect
		var tween = create_tween()
		tween.tween_property(boss_phase_label, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(boss_phase_label, "scale", Vector2(1.0, 1.0), 0.2)

func update_boss_health_bar():
	if not current_boss or not boss_health_bar or not boss_health_bar.visible:
		return

	# Update HP bar
	if boss_hp_bar and "current_hp" in current_boss and "max_hp" in current_boss:
		boss_hp_bar.value = current_boss.current_hp

		# Update HP label
		if boss_hp_label:
			boss_hp_label.text = "%.0f/%.0f" % [current_boss.current_hp, current_boss.max_hp]

# ========== INVENTORY GOLD DISPLAY (Phase 5.5.8) ==========

func _on_inventory_slot_changed(slot_index: int):
	# Update gold display when any inventory slot changes
	print("💰 Inventory slot %d changed, updating gold display" % slot_index)
	update_gold_display()

func update_gold_display():
	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		print("⚠️ HUD: Cannot find inventory system!")
		return

	if not gold_label:
		print("⚠️ HUD: gold_label not found!")
		return

	var total_gold = inventory.get_total_gold()
	gold_label.text = "Gold: %d" % total_gold
	print("💰 HUD gold display updated: %d gold" % total_gold)


# ========== CHAT INDICATOR TOUCH HANDLER ==========

func _on_chat_indicator_input(event: InputEvent) -> void:
	"""Handle touch/click on chat indicator to toggle chat"""
	# Handle touch events (mobile)
	if event is InputEventScreenTouch and event.pressed:
		_toggle_chat()
		return

	# Handle mouse events (PC)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_toggle_chat()


func _toggle_chat() -> void:
	"""Toggle chat box visibility"""
	if chat_box and chat_box.has_method("toggle_chat"):
		chat_box.toggle_chat()
		print("💬 Chat toggled via indicator tap")
