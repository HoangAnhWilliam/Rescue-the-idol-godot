# 🎰 SPIN WHEEL UI - COMPLETE SETUP & TESTING GUIDE

## ✅ SOLUTION OVERVIEW

This solution fixes the Spin Wheel UI by adding:
- ✅ **Close Button (X)** - Top-right corner, always works to exit UI
- ✅ **Spin Button** - Bottom center with state management (SPIN! → SPINNING... → CLOSE)
- ✅ **Gold Validation** - Checks and deducts gold before spinning
- ✅ **Smooth Animation** - 3-second rotation with 5 full spins (1800°) + alignment
- ✅ **Proper UI Flow** - Open → Spin → Result → Close
- ✅ **Process Mode ALWAYS** - Works when game is paused

---

## 📁 FILE LOCATIONS

### Required Files:
1. **scripts/spin_wheel_ui.gd** - Complete UI controller with gold validation
2. **scenes/ui/spin_wheel_ui.tscn** - UI scene with Close and Spin buttons

### Verify File Placement:
```bash
# Check files exist
ls -la scripts/spin_wheel_ui.gd
ls -la scenes/ui/spin_wheel_ui.tscn
```

---

## 🔧 SETUP INSTRUCTIONS

### Step 1: Verify Scene Structure

Open `scenes/ui/spin_wheel_ui.tscn` in Godot Editor and verify this hierarchy:

```
SpinWheelUI (CanvasLayer) [process_mode = 3]
├─ Overlay (ColorRect) - Black semi-transparent background
└─ Panel (Panel) - 600x600 centered panel
   ├─ WheelContainer (Node2D) - Center (300, 300), rotates during spin
   ├─ Arrow (ColorRect) - Red arrow pointing down at top
   │  └─ ArrowTip (Polygon2D) - Triangle tip
   ├─ TierLabel (Label) - Top-left, shows ATM tier name
   ├─ StatusLabel (Label) - Bottom center, shows status/cost
   ├─ CloseButton (Button) - Top-right (510, 10), 80x40, red text
   └─ SpinButton (Button) - Bottom center (225, 530), 150x50, green text
```

### Step 2: Verify Node Properties

**Critical Settings:**

| Node | Property | Value | Why |
|------|----------|-------|-----|
| SpinWheelUI | process_mode | 3 (ALWAYS) | Works when game paused |
| SpinWheelUI | layer | 10 | Above other UI |
| Panel | size | 600x600 | Centered container |
| CloseButton | text | "✕ Close" | Always visible |
| SpinButton | text | "SPIN!" | Changes during flow |

### Step 3: Verify Script Connections

Open `scripts/spin_wheel_ui.gd` and ensure these exist:

```gdscript
# Line 45: Process mode set in _ready()
process_mode = Node.PROCESS_MODE_ALWAYS

# Lines 63-73: Button connections
close_button.pressed.connect(_on_close_button_pressed)
spin_button.pressed.connect(_on_spin_button_pressed)

# Lines 275-297: Gold validation functions
func get_player_gold() -> int
func spend_player_gold(amount: int) -> bool
```

### Step 4: Integration Check

Verify your ATM scripts call the spin wheel correctly:

```gdscript
# In your ATM script (e.g., weapon_atm.gd)
func _on_player_interact():
    var spin_ui = get_tree().get_first_node_in_group("spin_wheel_ui")
    if spin_ui:
        spin_ui.open(tier, player)  # tier = 0-3, player = CharacterBody2D
```

### Step 5: Player Method Requirements

Ensure your player script has these methods:

```gdscript
# In your player.gd script
func get_total_gold() -> int:
    return gold  # Return current gold amount

func spend_gold(amount: int) -> bool:
    if gold >= amount:
        gold -= amount
        return true
    return false

func add_weapon_to_inventory(weapon_id: String):
    # Add weapon to inventory
    pass
```

---

## 🧪 TESTING GUIDE

### Test Scenario 1: Open Spin Wheel (FREE - Bronze ATM)

**Steps:**
1. Start game
2. Walk to Bronze ATM
3. Press E

**Expected Result:**
```
Console Output:
🎰 Opening spin wheel - Tier: 0 (BRONZE ATM)
   Cost: 0 gold
   Target: WoodenSword
   Weapon pool: [WoodenSword, MikuSword, ...]
✅ Wheel setup complete with 5 weapons
✅ Spin wheel opened successfully!
```

**Visual Check:**
- [ ] UI opens and fills screen
- [ ] Game pauses (player can't move)
- [ ] Panel shows "BRONZE ATM" at top
- [ ] Status shows "FREE SPIN! Press SPIN to start!" in green
- [ ] 5 weapon slots visible in circle
- [ ] Red arrow pointing down at top
- [ ] **Close button (✕ Close) visible top-right**
- [ ] **Spin button (SPIN!) visible bottom center in green**

---

### Test Scenario 2: Successful Free Spin

**Steps:**
1. Open Bronze ATM (free)
2. Click SPIN! button

**Expected Result:**
```
Console Output:
🎰 === SPIN BUTTON PRESSED ===
Is spinning: false
Spin complete: false
Starting spin...
💰 Gold check - Cost: 0, Player has: 1000
✅ Free spin, no gold needed
🎰 Spin started! Target slot: 2 (MikuSword)

[After 3 seconds...]

🎰 Spin complete! Selected weapon: Miku Sword
   Rarity: Uncommon
✨ Created effects for Uncommon rarity
✅ Added miku_sword to inventory
✅ Spin finished successfully!
```

**Visual Check:**
- [ ] Spin button changes to "SPINNING..." (grayed out, disabled)
- [ ] Close button HIDES during spin
- [ ] Wheel rotates smoothly for 3 seconds
- [ ] Wheel spins fast initially, slows down gradually
- [ ] Wheel stops with selected weapon aligned to arrow
- [ ] Camera shakes when result shown
- [ ] Particles spawn around result
- [ ] Status label shows "You got: Miku Sword (Uncommon)!" in green color
- [ ] Spin button changes to "CLOSE" (gray)
- [ ] Close button REAPPEARS
- [ ] Weapon appears in inventory hotbar

---

### Test Scenario 3: Paid Spin (Silver ATM - 5,000 Gold)

**Prerequisite:** Player has 10,000 gold

**Steps:**
1. Walk to Silver ATM
2. Press E
3. Verify cost shown
4. Click SPIN!

**Expected Result:**
```
Console Output:
🎰 Opening spin wheel - Tier: 1 (SILVER ATM)
   Cost: 5000 gold
   Target: FireSword
   Weapon pool: [FireSword, IceSword, ...]
✅ Spin wheel opened successfully!

[After clicking SPIN]
💰 Gold check - Cost: 5000, Player has: 10000
✅ Spent 5000 gold
🎰 Spin started! Target slot: 0 (FireSword)

[After spin...]
✅ Added fire_sword to inventory
```

**Visual Check:**
- [ ] Status shows "Cost: 5000 Gold - Press SPIN!" in white
- [ ] After clicking SPIN, gold deducted immediately
- [ ] Player gold display updates (10,000 → 5,000)
- [ ] Spin proceeds normally
- [ ] Result weapon added to inventory

---

### Test Scenario 4: Insufficient Gold

**Prerequisite:** Player has 2,000 gold

**Steps:**
1. Walk to Silver ATM (costs 5,000)
2. Press E
3. Try to click SPIN!

**Expected Result:**
```
Console Output:
🎰 Opening spin wheel - Tier: 1 (SILVER ATM)
   Cost: 5000 gold
   Target: FireSword
   Weapon pool: [...]
✅ Spin wheel opened successfully!

[After clicking SPIN]
💰 Gold check - Cost: 5000, Player has: 2000
❌ Not enough gold! Need 5000 but player has 2000
```

**Visual Check:**
- [ ] Status shows "Not enough gold! Need: 5000 (Have: 2000)" in red on open
- [ ] When clicking SPIN, status flashes red 3 times
- [ ] Status updates to "NOT ENOUGH GOLD! Need: 5000 (Have: 2000)"
- [ ] NO gold deducted
- [ ] NO spin animation starts
- [ ] Spin button stays as "SPIN!" (doesn't change)
- [ ] Can still close UI with Close button

---

### Test Scenario 5: Close Before Spinning

**Steps:**
1. Open any ATM
2. Click Close button (X)

**Expected Result:**
```
Console Output:
🎰 === CLOSE BUTTON PRESSED ===
🎰 Closing spin wheel...
   Before - visible: true, paused: true
   After - visible: false, paused: false
✅ Spin wheel closed
```

**Visual Check:**
- [ ] UI closes immediately
- [ ] Game resumes (player can move)
- [ ] No gold spent
- [ ] No weapon obtained

---

### Test Scenario 6: Close After Spinning

**Steps:**
1. Open any ATM
2. Click SPIN!
3. Wait for spin to complete
4. Click CLOSE button (or X button)

**Expected Result:**
```
Console Output:
🎰 === SPIN BUTTON PRESSED ===
Spin already complete, closing...
🎰 Closing spin wheel...
   Before - visible: true, paused: true
   After - visible: false, paused: false
✅ Spin wheel closed
```

**Visual Check:**
- [ ] Both CLOSE button (bottom) and X button (top-right) work
- [ ] UI closes smoothly
- [ ] Game resumes
- [ ] Weapon is in inventory

---

### Test Scenario 7: Multiple Spins (Bronze ATM - Free)

**Steps:**
1. Open Bronze ATM
2. Click SPIN!, wait for result
3. Click CLOSE
4. Open Bronze ATM again
5. Click SPIN! again

**Expected Result:**
- [ ] First spin works normally
- [ ] Close works
- [ ] Second open shows fresh wheel with new weapons
- [ ] Second spin works
- [ ] Both weapons appear in inventory
- [ ] No errors in console

---

### Test Scenario 8: Inventory Full

**Prerequisite:** Fill all 9 inventory slots

**Steps:**
1. Open any ATM
2. Click SPIN!
3. Wait for result

**Expected Result:**
```
Console Output:
⚠️ Inventory full!
```

**Visual Check:**
- [ ] Spin completes normally
- [ ] Result shown with "(Inventory Full!)" message appended
- [ ] No weapon added (inventory stays full)
- [ ] Can still close UI

---

## 🐛 TROUBLESHOOTING

### Issue 1: Buttons Not Visible

**Symptoms:**
- Close button missing
- Spin button missing
- Can't interact with UI

**Solutions:**

1. **Check Scene Structure:**
   ```
   Open scenes/ui/spin_wheel_ui.tscn
   Verify CloseButton and SpinButton exist under Panel
   ```

2. **Verify Button Positions:**
   ```gdscript
   # CloseButton should be at
   offset_left = 510.0
   offset_top = 10.0
   offset_right = 590.0
   offset_bottom = 50.0

   # SpinButton should be at
   offset_left = 225.0
   offset_top = 530.0
   offset_right = 375.0
   offset_bottom = 580.0
   ```

3. **Check Script References:**
   ```gdscript
   # In spin_wheel_ui.gd _ready()
   print("Close button exists: ", close_button != null)
   print("Spin button exists: ", spin_button != null)

   # Should output:
   # Close button exists: true
   # Spin button exists: true
   ```

4. **Reload Scene:**
   ```
   In Godot Editor:
   Scene → Reload Saved Scene
   Then run game again
   ```

---

### Issue 2: Wheel Doesn't Rotate

**Symptoms:**
- Clicking SPIN! does nothing
- Wheel stays still
- Status shows "Spinning..." but no movement

**Solutions:**

1. **Check Process Mode:**
   ```gdscript
   # In _ready(), line 45
   process_mode = Node.PROCESS_MODE_ALWAYS

   # Or in .tscn, line 6
   process_mode = 3
   ```

2. **Verify _process() is Running:**
   ```gdscript
   # Add debug print in _process()
   func _process(delta):
       if is_spinning:
           print("Spinning... rotation: ", spin_rotation)
   ```

3. **Check WheelContainer Reference:**
   ```gdscript
   # In _ready()
   print("Wheel container exists: ", wheel_container != null)
   print("Wheel container path: ", wheel_container.get_path() if wheel_container else "NULL")
   ```

---

### Issue 3: Gold Not Deducted

**Symptoms:**
- Spin works but gold stays same
- Console shows "Spent X gold" but player gold unchanged

**Solutions:**

1. **Verify Player Methods Exist:**
   ```gdscript
   # Check player script has:
   func spend_gold(amount: int) -> bool:
       if gold >= amount:
           gold -= amount
           emit_signal("gold_changed", gold)  # If you have this signal
           return true
       return false
   ```

2. **Check Method Call:**
   ```gdscript
   # In spin_wheel_ui.gd, add debug
   func spend_player_gold(amount: int) -> bool:
       print("Calling spend_gold on player: ", current_player)
       var result = current_player.spend_gold(amount)
       print("Spend gold result: ", result)
       print("Player gold after: ", current_player.get_total_gold())
       return result
   ```

3. **Ensure Player Reference is Valid:**
   ```gdscript
   # When opening wheel
   print("Player reference: ", current_player)
   print("Player has spend_gold: ", current_player.has_method("spend_gold"))
   ```

---

### Issue 4: Can't Close UI / Stuck in UI

**Symptoms:**
- Clicking X does nothing
- Clicking CLOSE does nothing
- Must restart game

**Solutions:**

1. **Check Button Connections:**
   ```gdscript
   # In _ready()
   if close_button:
       if not close_button.pressed.is_connected(_on_close_button_pressed):
           close_button.pressed.connect(_on_close_button_pressed)
           print("✅ Close button connected")
   ```

2. **Verify close() Function Works:**
   ```gdscript
   # Test directly in console
   func close():
       print("Close called!")
       visible = false
       get_tree().paused = false
       print("Visible: ", visible, ", Paused: ", get_tree().paused)
   ```

3. **Check Input Processing:**
   ```gdscript
   # Ensure CanvasLayer is processing input
   # process_mode = 3 should handle this
   ```

4. **Manual Close Workaround:**
   ```
   Press F12 (or `) to open console
   Type: get_tree().paused = false
   Press Enter
   Then close UI manually in scene tree
   ```

---

### Issue 5: Animation Not Smooth / Laggy

**Symptoms:**
- Wheel rotation is choppy
- Wheel jumps instead of smooth rotation
- FPS drops during spin

**Solutions:**

1. **Check Frame Rate:**
   ```gdscript
   # Add FPS counter
   func _process(delta):
       print("FPS: ", Engine.get_frames_per_second())
   ```

2. **Verify Delta is Used:**
   ```gdscript
   # Animation uses time-based progress
   var progress = spin_timer / spin_duration  # ✓ Correct
   # NOT frame-based
   ```

3. **Reduce Particle Count:**
   ```gdscript
   # In create_result_effects(), reduce particles
   for i in range(5 + rarity * 2):  # Instead of 10 + rarity * 5
   ```

4. **Check Other Processes:**
   ```
   Disable other heavy effects temporarily
   Check if issue persists
   ```

---

### Issue 6: Wrong Weapon Added to Inventory

**Symptoms:**
- Wheel shows one weapon
- Different weapon added to inventory
- Random weapons appearing

**Solutions:**

1. **Verify target_weapon_index:**
   ```gdscript
   # In end_spin()
   print("Target index: ", target_weapon_index)
   print("Weapons array: ", weapons)
   print("Selected weapon: ", weapons[target_weapon_index])
   ```

2. **Check Weapon Pool Generation:**
   ```gdscript
   # In open()
   print("Generated weapons: ", weapons)
   print("Pre-selected index: ", target_weapon_index)
   print("Pre-selected weapon: ", weapons[target_weapon_index])
   ```

3. **Verify WeaponPoolManager:**
   ```gdscript
   # Ensure weapon IDs match
   var weapon_id = weapons[target_weapon_index]
   print("Weapon ID: ", weapon_id)
   print("Display name: ", WeaponPoolManager.get_weapon_display_name(weapon_id))
   ```

---

## 📊 DEBUG OUTPUT REFERENCE

### Normal Successful Flow (Free Spin):

```
🎰 === Spin Wheel UI Initialization ===
Panel exists: true
Wheel container exists: true
Close button exists: true
Spin button exists: true
✅ Close button connected
✅ Spin button connected
🎰 Process mode set to ALWAYS (works when paused)
========================

🎰 Opening spin wheel - Tier: 0 (BRONZE ATM)
   Cost: 0 gold
   Target: WoodenSword
   Weapon pool: [WoodenSword, MikuSword, FireSword, IceSword, PoisonSword]
✅ Wheel setup complete with 5 weapons
✅ Spin wheel opened successfully!

🎰 === SPIN BUTTON PRESSED ===
Is spinning: false
Spin complete: false
Starting spin...
💰 Gold check - Cost: 0, Player has: 5000
✅ Free spin, no gold needed
🎰 Spin started! Target slot: 0 (WoodenSword)

[3 seconds later...]

🎰 Spin complete! Selected weapon: Wooden Sword
   Rarity: Common
✨ Created effects for Common rarity
✅ Added wooden_sword to inventory
✅ Spin finished successfully!

🎰 === SPIN BUTTON PRESSED ===
Is spinning: false
Spin complete: true
Spin already complete, closing...
🎰 Closing spin wheel...
   Before - visible: true, paused: true
   After - visible: false, paused: false
✅ Spin wheel closed
```

---

### Paid Spin with Gold Deduction:

```
🎰 Opening spin wheel - Tier: 1 (SILVER ATM)
   Cost: 5000 gold
   Target: FireSword
   Weapon pool: [FireSword, IceSword, ThunderSword, PoisonSword, MikuSword]
✅ Spin wheel opened successfully!

🎰 === SPIN BUTTON PRESSED ===
Starting spin...
💰 Gold check - Cost: 5000, Player has: 10000
✅ Spent 5000 gold
🎰 Spin started! Target slot: 0 (FireSword)

[After spin...]

🎰 Spin complete! Selected weapon: Fire Sword
   Rarity: Rare
✨ Created effects for Rare rarity
✅ Added fire_sword to inventory
✅ Spin finished successfully!
```

---

### Insufficient Gold Error:

```
🎰 Opening spin wheel - Tier: 2 (GOLD ATM)
   Cost: 20000 gold
   Target: ThunderSword
   Weapon pool: [...]
✅ Spin wheel opened successfully!

🎰 === SPIN BUTTON PRESSED ===
Starting spin...
💰 Gold check - Cost: 20000, Player has: 5000
❌ Not enough gold! Need 20000 but player has 5000
```

---

### Close Without Spinning:

```
🎰 Opening spin wheel - Tier: 0 (BRONZE ATM)
   Cost: 0 gold
   Target: WoodenSword
   Weapon pool: [...]
✅ Spin wheel opened successfully!

🎰 === CLOSE BUTTON PRESSED ===
🎰 Closing spin wheel...
   Before - visible: true, paused: true
   After - visible: false, paused: false
✅ Spin wheel closed
```

---

## ✅ FINAL VERIFICATION CHECKLIST

Before marking as complete, verify ALL of these:

### Code Verification:
- [ ] `scripts/spin_wheel_ui.gd` exists and is complete (467 lines)
- [ ] Line 45: `process_mode = Node.PROCESS_MODE_ALWAYS` is set
- [ ] Lines 31-32: `TIER_COSTS` and `TIER_NAMES` arrays defined
- [ ] Lines 275-285: `get_player_gold()` function exists
- [ ] Lines 287-297: `spend_player_gold()` function exists
- [ ] Lines 219-273: `start_spin()` has gold validation
- [ ] Lines 313-335: `_process()` handles animation
- [ ] Lines 337-348: `calculate_target_rotation()` adds 5 full rotations

### Scene Verification:
- [ ] `scenes/ui/spin_wheel_ui.tscn` exists
- [ ] Line 6: `process_mode = 3` is set
- [ ] Lines 67-74: CloseButton exists with correct position
- [ ] Lines 76-83: SpinButton exists with correct position
- [ ] Lines 32-42: Arrow with ArrowTip exists

### Functional Verification:
- [ ] Open ATM → UI shows
- [ ] Close button visible and works
- [ ] Spin button visible and works
- [ ] Free spin (Bronze) works without gold check
- [ ] Paid spin deducts gold correctly
- [ ] Insufficient gold shows error and prevents spin
- [ ] Wheel rotates smoothly for 3 seconds
- [ ] Result weapon added to inventory
- [ ] Camera shake and particles on result
- [ ] Can close UI after spin
- [ ] Game pauses during UI, resumes after close

### Integration Verification:
- [ ] Player has `get_total_gold()` method
- [ ] Player has `spend_gold(amount)` method
- [ ] Inventory system works with weapon addition
- [ ] WeaponPoolManager generates weapon pools
- [ ] CameraShake creates shake effects
- [ ] ParticleManager creates particle effects

### Performance Verification:
- [ ] Runs at 60 FPS during spin
- [ ] No lag when opening UI
- [ ] No lag when closing UI
- [ ] Animation is smooth and not choppy

---

## 🎯 QUICK TEST COMMAND

Run this in game console to test directly:

```gdscript
# Get references
var player = get_tree().get_first_node_in_group("player")
var spin_ui = get_tree().get_first_node_in_group("spin_wheel_ui")

# Test open
spin_ui.open(0, player)  # Bronze ATM, free spin

# Wait a moment, then test spin
spin_ui.start_spin()

# To force close
spin_ui.close()
```

---

## 📝 NOTES

### Gold Costs by Tier:
- **Tier 0 (Bronze):** 0 gold - FREE SPIN!
- **Tier 1 (Silver):** 5,000 gold
- **Tier 2 (Gold):** 20,000 gold
- **Tier 3 (Divine):** 50,000 gold

### Animation Details:
- **Duration:** 3.0 seconds
- **Easing:** Ease-out cubic (smooth deceleration)
- **Rotation:** 5 full rotations (TAU * 5 = ~31.4 radians ≈ 1800°) + alignment to result slot
- **Updates:** Every frame via `_process(delta)`

### Button States:
1. **Initial:** "SPIN!" (green, enabled)
2. **During Spin:** "SPINNING..." (gray, disabled)
3. **After Spin:** "CLOSE" (gray, enabled)

### Close Button:
- Always visible (except during spin animation)
- Always works to exit UI
- Located top-right corner
- Red "✕ Close" text

---

## 🚀 READY TO USE!

Your Spin Wheel UI is now fully functional with:
✅ Gold validation and deduction
✅ Smooth rotation animation
✅ Proper button handling
✅ Complete UI flow
✅ Error handling for edge cases
✅ Production-ready code

If you encounter any issues not covered in troubleshooting, check:
1. Console output for error messages
2. Scene structure matches exactly
3. Player methods exist and return correct values
4. WeaponPoolManager is functioning

**Happy spinning! 🎰✨**
