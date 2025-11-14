extends Area2D
class_name WeaponATM

## Weapon ATM - Phase 7 Gacha System
## Vending machine that dispenses random weapons for gold

# ATM Tier enum
enum ATMTier { BRONZE, SILVER, GOLD, DIVINE }

# Properties
@export var tier: ATMTier = ATMTier.BRONZE
@export var cost: int = 0
@export var cooldown_duration: float = 300.0  # 5 minutes for Bronze

# State
var is_player_nearby: bool = false
var current_player: CharacterBody2D = null
var last_use_time: float = -999.0
var is_depleted: bool = false  # One-time use for paid ATMs

# Visual references
@onready var background = $Background if has_node("Background") else null
@onready var interaction_prompt = $InteractionPrompt if has_node("InteractionPrompt") else null
@onready var price_label = $PriceLabel if has_node("PriceLabel") else null
@onready var tier_label = $TierLabel if has_node("TierLabel") else null

func _ready():
	# Connect Area2D signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# Setup visual
	setup_visual()

	# Hide prompts initially
	if interaction_prompt:
		interaction_prompt.visible = false
	if price_label:
		price_label.visible = false

	print("🏧 ", get_tier_name(), " ATM ready - Cost: ", cost, " gold")

func setup_visual():
	"""Setup ATM appearance based on tier"""
	if not background:
		return

	# Set color based on tier
	var color = get_tier_color()
	if background is ColorRect:
		background.color = color
	elif background is Sprite2D:
		background.modulate = color

	# Update labels
	if tier_label:
		tier_label.text = get_tier_name() + " ATM"

	if price_label:
		if cost == 0:
			price_label.text = "FREE"
		else:
			price_label.text = str(cost) + " Gold"

func get_tier_color() -> Color:
	"""Get color for ATM tier"""
	match tier:
		ATMTier.BRONZE:
			return Color(0.6, 0.4, 0.2)  # Brown
		ATMTier.SILVER:
			return Color(0.75, 0.75, 0.75)  # Silver
		ATMTier.GOLD:
			return Color(1.0, 0.84, 0.0)  # Gold
		ATMTier.DIVINE:
			return Color(0.8, 0.4, 1.0)  # Purple
		_:
			return Color.WHITE

func get_tier_name() -> String:
	"""Get display name for tier"""
	match tier:
		ATMTier.BRONZE:
			return "BRONZE"
		ATMTier.SILVER:
			return "SILVER"
		ATMTier.GOLD:
			return "GOLD"
		ATMTier.DIVINE:
			return "DIVINE"
		_:
			return "UNKNOWN"

func _process(delta):
	# Rainbow effect for Divine ATM
	if tier == ATMTier.DIVINE and background:
		var hue = fmod(Time.get_ticks_msec() / 2000.0, 1.0)
		var rainbow = Color.from_hsv(hue, 0.7, 1.0)
		if background is ColorRect:
			background.color = rainbow

func _on_body_entered(body):
	"""Player enters ATM range"""
	if body.is_in_group("player"):
		is_player_nearby = true
		current_player = body
		show_prompt()
		print("🏧 Player entered ATM range: ", get_tier_name())

func _on_body_exited(body):
	"""Player exits ATM range"""
	if body.is_in_group("player"):
		is_player_nearby = false
		current_player = null
		hide_prompt()

func show_prompt():
	"""Show interaction prompt"""
	if interaction_prompt:
		interaction_prompt.visible = true

		# Update prompt text based on state
		if is_depleted:
			interaction_prompt.text = "DEPLETED"
			interaction_prompt.modulate = Color.GRAY
		elif can_use():
			if cost == 0:
				interaction_prompt.text = "Press E (FREE)"
			else:
				interaction_prompt.text = "Press E (" + str(cost) + " gold)"
			interaction_prompt.modulate = Color.WHITE
		else:
			# On cooldown or not enough gold
			if tier == ATMTier.BRONZE and is_on_cooldown():
				var remaining = get_cooldown_remaining()
				interaction_prompt.text = "Cooldown: " + format_time(remaining)
			else:
				interaction_prompt.text = "Not enough gold"
			interaction_prompt.modulate = Color.RED

	if price_label:
		price_label.visible = true

func hide_prompt():
	"""Hide interaction prompt"""
	if interaction_prompt:
		interaction_prompt.visible = false
	if price_label:
		price_label.visible = false

func _input(event):
	"""Handle E key press"""
	if not is_player_nearby or not current_player:
		return

	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		try_interact(current_player)
		get_viewport().set_input_as_handled()

func try_interact(player: CharacterBody2D):
	"""Attempt to use ATM"""
	if not player:
		return

	# Check if can use
	if not can_use():
		show_error_message(player)
		return

	# Check gold
	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		print("❌ No inventory system found!")
		return

	var player_gold = inventory.get_total_gold()

	if player_gold < cost:
		print("❌ Not enough gold! Need ", cost, ", have ", player_gold)
		show_error_message(player, "Not enough gold!")
		return

	# Deduct gold
	if cost > 0:
		if not inventory.remove_gold(cost):
			print("❌ Failed to remove gold!")
			return

		print("💰 Deducted ", cost, " gold. Remaining: ", inventory.get_total_gold())

	# Open spin wheel
	open_spin_wheel(player)

	# Mark as used
	if tier != ATMTier.BRONZE:
		# Paid ATMs are one-time use
		is_depleted = true
		if background:
			background.modulate = Color.GRAY
		print("🏧 ", get_tier_name(), " ATM depleted")
	else:
		# Bronze has cooldown
		last_use_time = Time.get_ticks_msec() / 1000.0
		print("🏧 Bronze ATM on cooldown for ", cooldown_duration, " seconds")

func can_use() -> bool:
	"""Check if ATM can be used"""
	if is_depleted:
		return false

	if tier == ATMTier.BRONZE and is_on_cooldown():
		return false

	return true

func is_on_cooldown() -> bool:
	"""Check if on cooldown (Bronze only)"""
	if tier != ATMTier.BRONZE:
		return false

	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - last_use_time

	return elapsed < cooldown_duration

func get_cooldown_remaining() -> float:
	"""Get remaining cooldown time"""
	if not is_on_cooldown():
		return 0.0

	var current_time = Time.get_ticks_msec() / 1000.0
	var elapsed = current_time - last_use_time

	return cooldown_duration - elapsed

func format_time(seconds: float) -> String:
	"""Format time as MM:SS"""
	var minutes = int(seconds / 60)
	var secs = int(seconds) % 60
	return "%02d:%02d" % [minutes, secs]

func open_spin_wheel(player: CharacterBody2D):
	"""Open spin wheel UI"""
	print("🎰 Opening spin wheel for ", get_tier_name(), " ATM")

	# Get spin wheel UI
	var spin_wheel = get_tree().get_first_node_in_group("spin_wheel_ui")

	if not spin_wheel:
		# Try to create it
		var spin_wheel_scene = load("res://scenes/ui/spin_wheel_ui.tscn")
		if spin_wheel_scene:
			spin_wheel = spin_wheel_scene.instantiate()
			get_tree().root.add_child(spin_wheel)
		else:
			print("❌ Could not load spin wheel UI!")
			return

	# Open with tier
	if spin_wheel.has_method("open"):
		spin_wheel.open(tier, player)

func show_error_message(player: CharacterBody2D, message: String = ""):
	"""Show error message to player"""
	# Could implement floating text here
	print("❌ ", message if message != "" else "Cannot use ATM")
