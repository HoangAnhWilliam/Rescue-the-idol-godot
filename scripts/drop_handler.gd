extends Node
class_name DropHandler

## DropHandler - Spawns pickups when items dropped from inventory
## Listens to inventory.item_dropped signal

var inventory: InventorySystem = null

# Preload pickup scenes
var health_pickup_scene = preload("res://scenes/pickups/health_pickup.tscn")
var mana_pickup_scene = preload("res://scenes/pickups/mana_pickup.tscn")
var gold_coin_scene = preload("res://scenes/pickups/gold_coin.tscn")
var weapon_pickup_scene = preload("res://scenes/pickups/weapon_pickup.tscn")

func _ready():
	print("📦 DropHandler ready!")

	# Wait one frame for inventory to initialize
	await get_tree().process_frame

	# Find and connect to inventory
	inventory = get_tree().get_first_node_in_group("inventory")

	if inventory:
		inventory.item_dropped.connect(_on_item_dropped)
		print("✅ DropHandler connected to InventorySystem")
	else:
		push_warning("⚠️ DropHandler: No inventory found!")

func _on_item_dropped(item_type: int, item_id: String, quantity: int, position: Vector2):
	print("📦 Dropping %d x %s at %v" % [quantity, item_id, position])

	match item_type:
		InventorySystem.ItemType.WEAPON:
			spawn_weapon_drop(item_id, position)

		InventorySystem.ItemType.HEALTH_POTION:
			for i in range(quantity):
				var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
				spawn_health_drop(position + offset)
				await get_tree().create_timer(0.05).timeout  # Slight delay between spawns

		InventorySystem.ItemType.MANA_POTION:
			for i in range(quantity):
				var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
				spawn_mana_drop(position + offset)
				await get_tree().create_timer(0.05).timeout

		InventorySystem.ItemType.GOLD:
			spawn_gold_drop(quantity, position)

func spawn_weapon_drop(weapon_id: String, pos: Vector2):
	var weapon = weapon_pickup_scene.instantiate()
	weapon.weapon_id = weapon_id
	weapon.global_position = pos
	get_tree().root.add_child(weapon)
	print("  ⚔️ Spawned weapon pickup: %s" % weapon_id)

func spawn_health_drop(pos: Vector2):
	var pickup = health_pickup_scene.instantiate()
	pickup.global_position = pos
	get_tree().root.add_child(pickup)

func spawn_mana_drop(pos: Vector2):
	var pickup = mana_pickup_scene.instantiate()
	pickup.global_position = pos
	get_tree().root.add_child(pickup)

func spawn_gold_drop(amount: int, pos: Vector2):
	# Spawn multiple coins for large amounts
	var coins_to_spawn = ceili(amount / 10.0)  # Each coin = ~10 gold
	var gold_per_coin = amount / coins_to_spawn

	for i in range(coins_to_spawn):
		var coin = gold_coin_scene.instantiate()
		coin.gold_value = int(gold_per_coin)

		# Spread coins around position
		var offset = Vector2(randf_range(-30, 30), randf_range(-30, 30))
		coin.global_position = pos + offset

		get_tree().root.add_child(coin)

		if coins_to_spawn > 1:
			await get_tree().create_timer(0.05).timeout  # Delay for visual effect

	print("  💰 Spawned %d gold coins (total: %d gold)" % [coins_to_spawn, amount])
