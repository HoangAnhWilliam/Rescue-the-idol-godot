extends Node
class_name InventorySystem

## Minecraft-Style Hotbar Inventory System
## 9 slots, stackable items, weapons, potions, gold

# Constants
const MAX_SLOTS: int = 9
const MAX_STACK_SIZE: int = 64
const MAX_GOLD_PER_SLOT: int = 1000000

# Item Types
enum ItemType {
	NONE,
	WEAPON,
	HEALTH_POTION,
	MANA_POTION,
	GOLD,
	MATERIAL
}

# Signals
signal slot_changed(slot_index: int)
signal inventory_full
signal item_dropped(item_type: ItemType, item_id: String, quantity: int, position: Vector2)

# Singleton
static var instance: InventorySystem = null

# Inventory slots
var slots: Array[InventorySlot] = []

# Inner class for inventory slots
class InventorySlot:
	var item_type: ItemType = ItemType.NONE
	var item_id: String = ""
	var quantity: int = 0
	var item_data: Dictionary = {}

	func is_empty() -> bool:
		return item_type == ItemType.NONE or quantity <= 0

	func can_stack_with(other_type: ItemType, other_id: String) -> bool:
		if is_empty():
			return true
		return item_type == other_type and item_id == other_id

	func get_max_stack() -> int:
		if item_type == ItemType.GOLD:
			return 1000000
		return 64

	func clear():
		item_type = ItemType.NONE
		item_id = ""
		quantity = 0
		item_data = {}

func _ready():
	instance = self
	add_to_group("inventory")

	# Initialize slots
	for i in range(MAX_SLOTS):
		slots.append(InventorySlot.new())

	print("📦 InventorySystem ready: %d slots" % MAX_SLOTS)

# ========== ADD ITEM ==========

func add_item(type: ItemType, item_id: String, amount: int, data: Dictionary = {}) -> bool:
	print("📦 Adding to inventory: %s x%d (%s)" % [ItemType.keys()[type], amount, item_id])

	var remaining = amount

	# First pass: Try to stack with existing items
	for i in range(MAX_SLOTS):
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot.can_stack_with(type, item_id) and not slot.is_empty():
			var space_available = slot.get_max_stack() - slot.quantity
			var amount_to_add = min(remaining, space_available)

			if amount_to_add > 0:
				slot.quantity += amount_to_add
				remaining -= amount_to_add
				print("  → Added %d to slot %d (total: %d)" % [amount_to_add, i, slot.quantity])
				slot_changed.emit(i)

	# Second pass: Fill empty slots
	for i in range(MAX_SLOTS):
		if remaining <= 0:
			break

		var slot = slots[i]
		if slot.is_empty():
			var amount_to_add = min(remaining, slot.get_max_stack() if type == ItemType.GOLD else MAX_STACK_SIZE)

			slot.item_type = type
			slot.item_id = item_id
			slot.quantity = amount_to_add
			slot.item_data = data.duplicate()
			remaining -= amount_to_add

			print("  → Added %d to slot %d (new slot)" % [amount_to_add, i])
			slot_changed.emit(i)

	# Check if all items were added
	if remaining > 0:
		print("  ⚠️ Inventory full! %d items not added" % remaining)
		inventory_full.emit()
		return false

	return true

# ========== REMOVE ITEM ==========

func remove_item(slot_index: int, amount: int = 1) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}

	var slot = slots[slot_index]
	if slot.is_empty():
		return {}

	var amount_to_remove = min(amount, slot.quantity)

	var removed_data = {
		"type": slot.item_type,
		"id": slot.item_id,
		"quantity": amount_to_remove,
		"data": slot.item_data.duplicate()
	}

	slot.quantity -= amount_to_remove

	if slot.quantity <= 0:
		slot.clear()

	print("📦 Removed %d from slot %d" % [amount_to_remove, slot_index])
	slot_changed.emit(slot_index)

	return removed_data

# ========== DROP ITEM ==========

func drop_item(slot_index: int, drop_position: Vector2, amount: int = 1):
	var removed = remove_item(slot_index, amount)

	if removed.is_empty():
		return

	print("📦 Dropping %d x %s at %v" % [removed.quantity, removed.id, drop_position])

	item_dropped.emit(removed.type, removed.id, removed.quantity, drop_position)

# ========== GET SLOT ==========

func get_slot(index: int) -> InventorySlot:
	if index < 0 or index >= MAX_SLOTS:
		return null
	return slots[index]

# ========== GET ALL WEAPONS ==========

func get_all_weapons() -> Array[Dictionary]:
	var weapons: Array[Dictionary] = []

	for i in range(MAX_SLOTS):
		var slot = slots[i]
		if slot.item_type == ItemType.WEAPON and not slot.is_empty():
			weapons.append({
				"slot_index": i,
				"weapon_id": slot.item_id,
				"quantity": slot.quantity,
				"data": slot.item_data.duplicate()
			})

	return weapons

# ========== GET TOTAL GOLD ==========

func get_total_gold() -> int:
	var total = 0

	for slot in slots:
		if slot.item_type == ItemType.GOLD:
			total += slot.quantity

	return total

# ========== HAS ITEM ==========

func has_item(type: ItemType, item_id: String, amount: int) -> bool:
	var count = 0

	for slot in slots:
		if slot.item_type == type and slot.item_id == item_id:
			count += slot.quantity

	return count >= amount

# ========== USE ITEM ==========

func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false

	var slot = slots[slot_index]
	if slot.is_empty():
		return false

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return false

	match slot.item_type:
		ItemType.HEALTH_POTION:
			# Heal player
			var heal_amount = slot.item_data.get("heal_amount", 20.0)

			if "current_hp" in player and "stats" in player:
				player.current_hp = min(player.current_hp + heal_amount, player.stats.max_hp)
				if player.has_signal("hp_changed"):
					player.hp_changed.emit(player.current_hp, player.stats.max_hp)

				print("💚 Used health potion: +%.0f HP" % heal_amount)

				# Particle effect
				ParticleManager.create_hit_effect(player.global_position, Color(1, 0, 0))

				# Remove from inventory
				remove_item(slot_index, 1)
				return true

		ItemType.MANA_POTION:
			# Restore mana
			var mana_amount = slot.item_data.get("mana_amount", 15.0)

			if "current_mana" in player and "stats" in player:
				player.current_mana = min(player.current_mana + mana_amount, player.stats.max_mana)
				if player.has_signal("mana_changed"):
					player.mana_changed.emit(player.current_mana, player.stats.max_mana)

				print("💙 Used mana potion: +%.0f Mana" % mana_amount)

				# Particle effect
				ParticleManager.create_hit_effect(player.global_position, Color(0, 0.5, 1))

				# Remove from inventory
				remove_item(slot_index, 1)
				return true

		ItemType.WEAPON:
			# Weapons are passive (no action on use)
			print("⚔️ Weapons are passively equipped")
			return false

		ItemType.GOLD:
			# Gold cannot be "used"
			print("💰 Gold cannot be used")
			return false

	return false

# ========== DEBUG PRINT ==========

func print_inventory():
	print("=== INVENTORY ===")
	for i in range(MAX_SLOTS):
		var slot = slots[i]
		if not slot.is_empty():
			print("  Slot %d: %s x%d (%s)" % [i, ItemType.keys()[slot.item_type], slot.quantity, slot.item_id])
	print("=================")
