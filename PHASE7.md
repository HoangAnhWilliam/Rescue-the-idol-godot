# Phase 7: Weapon ATM Gacha System

## Overview
Phase 7 implements a **Weapon ATM Gacha System** - vending machines scattered across the world that allow players to obtain random weapons through a spinning wheel mechanic. This adds an engaging progression system with both free and paid options.

## System Architecture

### 1. WeaponPoolManager (Singleton)
**File:** `scripts/weapon_pool_manager.gd`

Central manager for weapon rarity pools and random selection logic.

**Key Features:**
- Manages 5 rarity tiers: Common, Uncommon, Rare, Epic, Legendary
- 4 ATM tier pools with different drop rate distributions
- Weighted random selection algorithm using cumulative probability
- Generates unique weapon sets for spin wheel display (avoids duplicates)

**ATM Tier Drop Rates:**

| Tier | Common | Uncommon | Rare | Epic | Legendary |
|------|--------|----------|------|------|-----------|
| **BRONZE** (Free) | 90% | 10% | 0% | 0% | 0% |
| **SILVER** (100g) | 40% | 40% | 18% | 2% | 0% |
| **GOLD** (500g) | 0% | 30% | 50% | 18% | 2% |
| **DIVINE** (2000g) | 0% | 0% | 40% | 45% | 15% |

**Weapon Pools:**
- **Common:** Wooden Sword
- **Uncommon:** Earthshatter Staff, Shadow Daggers
- **Rare:** Acid Gauntlets, Frost Bow, Lightning Chain
- **Epic:** Enchanting Flute
- **Legendary:** Miku Sword

### 2. Weapon ATM (Entity)
**File:** `scripts/weapon_atm.gd`
**Scene:** `scenes/atm/weapon_atm.tscn`

Area2D entities that spawn across the world at different tiers.

**ATM Tiers:**

| Tier | Cost | Type | Cooldown | Location |
|------|------|------|----------|----------|
| **BRONZE** | FREE | Reusable | 5 minutes | Common (3-5 per world) |
| **SILVER** | 100 gold | One-time | N/A | Uncommon biomes (1-2 per world) |
| **GOLD** | 500 gold | One-time | N/A | Rare biomes (1 per world) |
| **DIVINE** | 2000 gold | One-time | N/A | Very rare biomes (30% chance) |

**Interaction System:**
- Proximity detection via Area2D (body_entered/exited)
- Shows "Press E" prompt when player is nearby
- Validates gold cost before opening
- Deducts gold via InventorySystem.remove_gold()
- Opens SpinWheelUI with pre-determined result

**State Management:**
- Bronze ATMs track `last_use_time` for cooldown
- Paid ATMs set `is_depleted` flag after use
- Visual feedback for depleted/cooldown states

### 3. Spin Wheel UI
**File:** `scripts/spin_wheel_ui.gd`
**Scene:** `scenes/ui/spin_wheel_ui.tscn`

Animated gacha UI that displays 5 weapons in a circular wheel.

**Animation Sequence:**
1. **Setup:** Generate 5 unique weapons from tier pool
2. **Pre-determine Result:** Select target weapon before spin starts
3. **Spin Animation:** 3-second rotation with quadratic deceleration
4. **Landing Logic:** Arrow lands on pre-determined weapon
5. **Result Display:** Show rarity-colored effects and weapon name
6. **Award:** Add weapon to player's inventory
7. **Close:** 2-second delay before auto-close

**Visual Effects:**
- Rarity-colored backgrounds for weapon slots
- Red arrow pointer at top (fixed position)
- Rotating wheel container with smooth deceleration
- Particle effects on result (color matches rarity)
- Status label showing "Spinning..." → Result text

### 4. BiomeGenerator Integration
**File:** `scripts/biome_generator.gd` (Updated)

ATMs are spawned during world generation via `spawn_atms()` method.

**Spawning Rules:**
- **Bronze ATMs:** 3-5 random positions, 800-2500 units from spawn
- **Silver ATMs:** 1-2 in Desert/Tundra biomes, 1500-4000 units out
- **Gold ATM:** 1 in Volcanic/Tundra biomes, 1500-4000 units out
- **Divine ATM:** 30% chance in Blood Temple/Volcanic, 1500-4000 units out

**Position Selection:**
- Uses `find_atm_position_in_biome()` to ensure biome matching
- 20 attempts to find valid biome position
- Fallback to distant random position if no match found

## Economy Balancing

### Gold Requirements
- **Early Game:** Bronze ATMs provide free weapons (5-min cooldown prevents spam)
- **Mid Game:** Silver (100g) accessible after ~10-15 enemy kills
- **Late Game:** Gold (500g) requires sustained farming or boss kills
- **End Game:** Divine (2000g) is prestige/whale option

### Reward Value
- Bronze: Mostly Common (90%), occasional Uncommon (10%)
- Silver: Balanced Common/Uncommon (40%/40%), small Rare chance (18%)
- Gold: High Rare chance (50%), good Epic chance (18%), first Legendary access (2%)
- Divine: Guaranteed Epic+ (85%), best Legendary chance (15%)

### Risk vs Reward
- Free Bronze provides steady progression
- Paid tiers offer one-time investment for better odds
- Divine ATM is rare spawn (30%) adding exploration incentive

## How to Use

### For Players
1. **Find ATM:** Look for brown rectangular machines with tier labels
2. **Approach:** Walk near ATM until "Press E" prompt appears
3. **Interact:** Press E key to open
4. **Check Cost:** Ensure you have enough gold (or wait for Bronze cooldown)
5. **Spin:** Watch the 3-second wheel animation
6. **Receive Weapon:** Weapon is added to your inventory automatically
7. **Equip:** Open inventory and equip the new weapon to a hotbar slot

### For Developers

**Adding New Weapon to Pool:**
1. Add weapon_id to appropriate rarity array in `weapon_pool_manager.gd`:
   ```gdscript
   const RARE_WEAPONS = ["acid_gauntlets", "frost_bow", "lightning_chain", "new_weapon"]
   ```
2. Create weapon scene file in `scenes/weapons/`
3. Add weapon data to `get_weapon_data()` method

**Adjusting Drop Rates:**
Edit the tier pool dictionaries in `weapon_pool_manager.gd`:
```gdscript
const GOLD_POOL = {
    "common": 0.0,
    "uncommon": 0.30,
    "rare": 0.50,      # Increase this
    "epic": 0.18,      # Decrease this
    "legendary": 0.02
}
```

**Changing ATM Costs:**
Edit the `spawn_atm()` method in `biome_generator.gd`:
```gdscript
match tier:
    0: atm.cost = 0      # BRONZE
    1: atm.cost = 150    # SILVER (was 100)
    2: atm.cost = 700    # GOLD (was 500)
    3: atm.cost = 3000   # DIVINE (was 2000)
```

**Adjusting Spawn Rates:**
Edit the `spawn_atms()` method in `biome_generator.gd`:
```gdscript
var bronze_count = randi_range(5, 8)  # Was 3-5
var silver_count = randi_range(2, 3)  # Was 1-2
```

## Technical Implementation

### Weighted Random Algorithm
Uses cumulative probability for fair distribution:
```gdscript
func roll_rarity(pool: Dictionary) -> String:
    var roll = randf()  # 0.0 to 1.0
    var cumulative = 0.0

    for rarity in ["common", "uncommon", "rare", "epic", "legendary"]:
        cumulative += pool.get(rarity, 0.0)
        if roll <= cumulative:
            return rarity

    return "common"  # Fallback
```

### Cooldown System
Bronze ATMs use timestamp comparison:
```gdscript
var current_time = Time.get_ticks_msec() / 1000.0
var time_since_use = current_time - last_use_time
var cooldown_remaining = cooldown_duration - time_since_use

if cooldown_remaining > 0:
    show_error_message()  # "Available in X minutes"
    return
```

### Depletion State
Paid ATMs become permanently disabled:
```gdscript
if tier != ATMTier.BRONZE:
    is_depleted = true
    # Visual feedback: gray out, show "SOLD OUT"
```

### Gold Deduction
Multi-slot removal with validation:
```gdscript
func remove_gold(amount: int) -> bool:
    var total_gold = get_total_gold()
    if total_gold < amount:
        return false  # Not enough gold

    # Remove from slots (start from last)
    for i in range(MAX_SLOTS - 1, -1, -1):
        if slot.item_type == ItemType.GOLD:
            var remove = min(remaining, slot.quantity)
            slot.quantity -= remove
            remaining -= remove

    return true
```

### Spin Animation
Smooth deceleration using quadratic curve:
```gdscript
func _process(delta):
    if not is_spinning:
        return

    spin_timer += delta
    var progress = spin_timer / spin_duration
    var decel_curve = 1.0 - pow(progress, 2.0)  # Quadratic
    spin_speed = 20.0 * decel_curve

    if progress > 0.7:
        # Last 30%: lerp to target
        var target_angle = calculate_target_rotation()
        spin_rotation = lerp(spin_rotation, target_angle, delta * 5.0)
    else:
        spin_rotation += spin_speed * delta
```

## Files Modified/Created

### Created Files
- `scripts/weapon_pool_manager.gd` (175 lines) - Rarity pool manager
- `scripts/weapon_atm.gd` (265 lines) - ATM entity logic
- `scripts/spin_wheel_ui.gd` (270 lines) - Gacha UI animation
- `scenes/atm/weapon_atm.tscn` - ATM scene with Area2D
- `scenes/ui/spin_wheel_ui.tscn` - Spin wheel UI scene

### Modified Files
- `scripts/inventory_system.gd` - Added `remove_gold()` method (33 lines)
- `scripts/biome_generator.gd` - Added `spawn_atms()` method (70 lines)
- `project.godot` - Added WeaponPoolManager autoload

## Testing Checklist

### Basic Functionality
- [ ] Bronze ATMs spawn in world (3-5 visible)
- [ ] Silver/Gold/Divine ATMs spawn in correct biomes
- [ ] "Press E" prompt appears when near ATM
- [ ] Spin wheel opens when pressing E
- [ ] Wheel spins for exactly 3 seconds
- [ ] Arrow lands on a weapon slot
- [ ] Weapon is added to inventory after spin
- [ ] Gold is deducted for paid ATMs

### Bronze ATM (Free)
- [ ] Can use immediately after world load
- [ ] Shows cooldown timer after use
- [ ] Cannot use during 5-minute cooldown
- [ ] Can reuse after cooldown expires
- [ ] Drop rates match Bronze pool (90% Common, 10% Uncommon)

### Silver ATM (100g)
- [ ] Requires 100 gold to use
- [ ] Shows error if player has < 100 gold
- [ ] Deducts exactly 100 gold on use
- [ ] Becomes depleted after single use
- [ ] Cannot be reused (shows "SOLD OUT")
- [ ] Drop rates match Silver pool

### Gold ATM (500g)
- [ ] Requires 500 gold to use
- [ ] Spawns in rare biomes only
- [ ] One-time use, then depleted
- [ ] Drop rates favor Rare (50%) and Epic (18%)

### Divine ATM (2000g)
- [ ] Only 30% chance to spawn
- [ ] Spawns in Blood Temple or Volcanic biomes
- [ ] Requires 2000 gold
- [ ] Guarantees Epic+ weapons (85% Epic, 15% Legendary)
- [ ] One-time use

### Edge Cases
- [ ] Cannot interact with depleted ATM
- [ ] Cannot interact during cooldown
- [ ] Cannot use ATM while SpinWheelUI is open
- [ ] Game pauses during spin (no enemy damage)
- [ ] Closing UI mid-spin still awards weapon
- [ ] Multiple players cannot use same ATM simultaneously
- [ ] ATMs persist across save/load (depletion state saved)

### Visual Polish
- [ ] ATM color changes by tier (Bronze = brown, Silver = gray, Gold = gold, Divine = purple)
- [ ] Rarity colors on weapon slots match weapon rarity
- [ ] Particle effects appear on spin result
- [ ] Result text shows weapon name and rarity
- [ ] Status label updates ("Spinning..." → "You got X!")

## Known Limitations

1. **No Duplicate Protection:** Player can receive weapons they already own
2. **No Pity System:** No guaranteed rare drops after X spins
3. **Static Spawn:** ATMs don't respawn or move after world generation
4. **No Animations:** ATMs are static (no idle animations/VFX)
5. **No Sound:** Spin wheel is silent (needs SFX for spin/result)

## Future Enhancements

### Potential Features
1. **Pity System:** Guaranteed Epic after 10 Silver spins
2. **Daily Free Spin:** One free Gold-tier spin per day
3. **Duplicate Conversion:** Turn duplicate weapons into upgrade materials
4. **ATM Quests:** "Find the Divine ATM" map markers
5. **Cosmetic Variants:** Different ATM skins per biome
6. **Sound Effects:** Spinning sound, result jingles, coin SFX
7. **Particle VFX:** Ambient sparkles on high-tier ATMs
8. **Animation:** Idle bobbing, screen glow effects
9. **Minimap Icons:** Show ATM locations on minimap
10. **Save/Load Support:** Persist depletion/cooldown states

### Balancing Tweaks
- Monitor player gold accumulation vs ATM costs
- Adjust drop rates based on player feedback
- Consider adding "bad luck protection" for Legendary drops
- Evaluate Bronze cooldown (too short/long?)

## Conclusion

Phase 7 adds a complete gacha monetization-style system (using in-game gold) that:
- Encourages exploration (find rare ATMs)
- Rewards farming (gold for better tiers)
- Adds excitement (spinning wheel animation)
- Balances free and paid options
- Integrates seamlessly with existing systems

The system is modular and easy to extend with new weapons, tiers, or mechanics.

---

**Implementation Date:** November 2025
**Total Lines of Code:** ~750 lines (scripts) + 2 scene files
**Dependencies:** Phase 6 Weapon System, InventorySystem, BiomeGenerator
