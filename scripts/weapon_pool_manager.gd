extends Node

## Weapon Pool Manager - Phase 7 ATM System
## Manages weapon rarity pools and weighted random selection for gacha

# Weapon pools by rarity
const COMMON_WEAPONS = ["wooden_sword"]
const UNCOMMON_WEAPONS = ["earthshatter_staff", "shadow_daggers"]
const RARE_WEAPONS = ["acid_gauntlets", "frost_bow", "lightning_chain"]
const EPIC_WEAPONS = ["enchanting_flute"]
const LEGENDARY_WEAPONS = ["kiku_sword"]

# ATM tier enum (must match WeaponATM.ATMTier)
enum ATMTier { BRONZE, SILVER, GOLD, DIVINE }

# ATM tier probabilities
const BRONZE_POOL = {
	"common": 0.90,
	"uncommon": 0.10,
	"rare": 0.0,
	"epic": 0.0,
	"legendary": 0.0
}

const SILVER_POOL = {
	"common": 0.40,
	"uncommon": 0.40,
	"rare": 0.18,
	"epic": 0.02,
	"legendary": 0.0
}

const GOLD_POOL = {
	"common": 0.0,
	"uncommon": 0.30,
	"rare": 0.50,
	"epic": 0.18,
	"legendary": 0.02
}

const DIVINE_POOL = {
	"common": 0.0,
	"uncommon": 0.0,
	"rare": 0.40,
	"epic": 0.45,
	"legendary": 0.15
}

func get_random_weapon(tier: int) -> String:
	"""Get random weapon based on ATM tier"""
	var pool = get_pool_for_tier(tier)
	var rarity = roll_rarity(pool)
	var weapon_id = get_random_weapon_of_rarity(rarity)

	print("🎰 Rolled ", rarity, " weapon: ", weapon_id)
	return weapon_id

func get_pool_for_tier(tier: int) -> Dictionary:
	"""Get probability pool for ATM tier"""
	match tier:
		ATMTier.BRONZE:
			return BRONZE_POOL
		ATMTier.SILVER:
			return SILVER_POOL
		ATMTier.GOLD:
			return GOLD_POOL
		ATMTier.DIVINE:
			return DIVINE_POOL
		_:
			return BRONZE_POOL

func roll_rarity(pool: Dictionary) -> String:
	"""Roll rarity based on weighted probabilities"""
	var roll = randf()
	var cumulative = 0.0

	for rarity in ["common", "uncommon", "rare", "epic", "legendary"]:
		cumulative += pool.get(rarity, 0.0)
		if roll <= cumulative:
			return rarity

	return "common"

func get_random_weapon_of_rarity(rarity: String) -> String:
	"""Get random weapon from specific rarity pool"""
	var weapons = []

	match rarity:
		"common":
			weapons = COMMON_WEAPONS
		"uncommon":
			weapons = UNCOMMON_WEAPONS
		"rare":
			weapons = RARE_WEAPONS
		"epic":
			weapons = EPIC_WEAPONS
		"legendary":
			weapons = LEGENDARY_WEAPONS

	if weapons.is_empty():
		return "wooden_sword"  # Fallback

	return weapons[randi() % weapons.size()]

func generate_spin_wheel_weapons(tier: int, count: int = 5) -> Array:
	"""Generate array of weapons for spin wheel (avoid duplicates)"""
	var weapons = []
	var attempts = 0
	var max_attempts = count * 3

	while weapons.size() < count and attempts < max_attempts:
		var weapon_id = get_random_weapon(tier)

		# Avoid duplicates in same wheel
		if weapon_id not in weapons:
			weapons.append(weapon_id)

		attempts += 1

	# Fill remaining with random if needed
	while weapons.size() < count:
		weapons.append(get_random_weapon(tier))

	print("🎰 Generated wheel: ", weapons)
	return weapons

func get_weapon_display_name(weapon_id: String) -> String:
	"""Get display name for weapon"""
	match weapon_id:
		"wooden_sword": return "Wooden Sword"
		"kiku_sword": return "Kiku Sword"
		"earthshatter_staff": return "Earthshatter Staff"
		"acid_gauntlets": return "Acid Storm Gauntlets"
		"enchanting_flute": return "Enchanting Flute"
		"shadow_daggers": return "Shadow Daggers"
		"frost_bow": return "Frost Bow"
		"lightning_chain": return "Lightning Chain"
		_: return "Unknown Weapon"

func get_weapon_rarity(weapon_id: String) -> int:
	"""Get rarity tier (0-4) for weapon"""
	if weapon_id in COMMON_WEAPONS:
		return 0  # Common
	elif weapon_id in UNCOMMON_WEAPONS:
		return 1  # Uncommon
	elif weapon_id in RARE_WEAPONS:
		return 2  # Rare
	elif weapon_id in EPIC_WEAPONS:
		return 3  # Epic
	elif weapon_id in LEGENDARY_WEAPONS:
		return 4  # Legendary
	return 0

func get_rarity_color(rarity: int) -> Color:
	"""Get color for rarity tier"""
	match rarity:
		0: return Color(0.8, 0.8, 0.8)     # Common - White
		1: return Color(0.0, 1.0, 0.0)     # Uncommon - Green
		2: return Color(0.0, 0.5, 1.0)     # Rare - Blue
		3: return Color(0.8, 0.0, 1.0)     # Epic - Purple
		4: return Color(1.0, 0.84, 0.0)    # Legendary - Gold
		_: return Color.WHITE

func get_rarity_name(rarity: int) -> String:
	"""Get name for rarity tier"""
	match rarity:
		0: return "Common"
		1: return "Uncommon"
		2: return "Rare"
		3: return "Epic"
		4: return "Legendary"
		_: return "Unknown"
