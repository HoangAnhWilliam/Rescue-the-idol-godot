# 🎵🔊 Audio System Implementation Guide
## Miku's Despair - Melody of the Dead

**Complete sound & music system for Godot 4.3**

---

## 📚 TABLE OF CONTENTS

1. [System Overview](#system-overview)
2. [What Has Been Implemented](#what-has-been-implemented)
3. [File Structure](#file-structure)
4. [How It Works](#how-it-works)
5. [Next Steps (What YOU Need to Do)](#next-steps)
6. [Testing Checklist](#testing-checklist)
7. [Troubleshooting](#troubleshooting)
8. [API Reference](#api-reference)

---

## 🎯 SYSTEM OVERVIEW

The audio system consists of:
- **AudioManager** singleton - Central audio control
- **17 Music Tracks** - Dynamic biome/boss music
- **35 Sound Effects** - Combat, weapons, UI, bosses
- **Volume Controls** - Master, Music, SFX sliders
- **Settings Integration** - Save/load audio preferences

---

## ✅ WHAT HAS BEEN IMPLEMENTED

### ✅ Core Systems

#### 1. AudioManager Singleton (`scripts/audio_manager.gd`)
**Location:** `res://scripts/audio_manager.gd`
**Status:** ✅ COMPLETE & ACTIVE

**Features:**
- ✅ Dual music player system (crossfading)
- ✅ SFX pooling (20 simultaneous sounds)
- ✅ Volume controls (Master, Music, SFX)
- ✅ Settings integration with SaveSystem
- ✅ Helper functions for biome/boss music
- ✅ Weapon-specific sound mapping

**Key Functions:**
```gdscript
AudioManager.play_music(track_name, fade_time)
AudioManager.play_sfx(sfx_name, volume_modifier)
AudioManager.play_biome_music(biome_name)
AudioManager.play_boss_music(boss_name)
AudioManager.set_master_volume(value)
AudioManager.set_music_volume(value)
AudioManager.set_sfx_volume(value)
```

---

#### 2. Player Integration (`scripts/player.gd`)
**Status:** ✅ COMPLETE

**Integrated Sounds:**
- ✅ Line 281: Player hurt sound (`player_hurt`)
- ✅ Line 304: Game over music
- ✅ Line 317: XP collect sound (`xp_collect`)
- ✅ Line 340: Level up sound (`level_up`)

---

#### 3. Enemy Integration (`scripts/enemy.gd`)
**Status:** ✅ COMPLETE

**Integrated Sounds:**
- ✅ Lines 146-149: Hit impact + critical hit sounds
- ✅ Line 227: Enemy death sound (`enemy_death`)

---

#### 4. Weapon Integration (`scripts/weapon.gd`)
**Status:** ✅ COMPLETE

**Integrated Sounds:**
- ✅ Lines 62-63: Weapon-specific attack sounds
  - MikuSword → `magic_slash`
  - WoodenSword → `sword_slash`
  - FrostBow → `bow_shoot`
  - LightningChain → `lightning_zap`
  - EarthshatterStaff → `earth_slam`
  - ShadowDaggers → `daggers_slash`
  - AcidGauntlets → `acid_sizzle`
  - EnchantingFlute → `flute_notes`

---

#### 5. Boss Integration (`scripts/boss_manager.gd`)
**Status:** ✅ COMPLETE

**Integrated Music & Sounds:**
- ✅ Lines 179-180: Fire Dragon music + roar
- ✅ Lines 230-231: Vampire Lord music + laugh
- ✅ Lines 255-258: Victory fanfare → biome music return
- ✅ Line 267: Boss phase change sound

---

#### 6. Biome Integration (`scripts/biome_generator.gd`)
**Status:** ✅ COMPLETE

**Integrated Music:**
- ✅ Line 80: Starting biome music
- ✅ Line 278: Biome change music transitions

**Music Mapping:**
- Starting Forest → `forest`
- Desert Wasteland → `desert`
- Frozen Tundra → `tundra`
- Volcanic Darklands → `volcanic`
- Blood Temple → `blood_temple`

---

#### 7. UI Integration (`scripts/upgrade_menu.gd`)
**Status:** ✅ COMPLETE

**Integrated Sounds:**
- ✅ Line 114: Menu open sound (`menu_open`)
- ✅ Line 264: Menu close sound (`menu_close`)
- ✅ Lines 266, 272, 278: Button click sounds (`button_click`)

---

#### 8. Settings Menu (`scripts/settings_menu.gd`)
**Status:** ✅ CREATED (needs scene setup)

**Features:**
- ✅ Master volume slider
- ✅ Music volume slider
- ✅ SFX volume slider
- ✅ Auto-save to SaveSystem
- ✅ Test SFX on slider change

**⚠️ TODO:** Create the scene file with UI nodes (see instructions below)

---

#### 9. SaveSystem Integration (`scripts/save_system.gd`)
**Status:** ✅ ALREADY COMPATIBLE

The SaveSystem already has audio settings defined:
- Line 27: `master_volume: 1.0`
- Line 28: `music_volume: 0.8`
- Line 29: `sfx_volume: 1.0`

No changes needed! AudioManager uses these automatically.

---

## 📁 FILE STRUCTURE

```
Rescue-the-idol-godot/
├── audio/
│   ├── music/                      # 17 music tracks
│   │   ├── README.md              ✅ Created
│   │   ├── .gitkeep               ✅ Created
│   │   ├── menu_music.ogg         ⚠️ TODO: Generate
│   │   ├── victory_fanfare.ogg    ⚠️ TODO: Generate
│   │   ├── game_over.ogg          ⚠️ TODO: Generate
│   │   ├── forest_music.ogg       ⚠️ TODO: Generate
│   │   ├── desert_music.ogg       ⚠️ TODO: Generate
│   │   ├── tundra_music.ogg       ⚠️ TODO: Generate
│   │   ├── volcanic_music.ogg     ⚠️ TODO: Generate
│   │   ├── blood_temple_music.ogg ⚠️ TODO: Generate
│   │   ├── fire_dragon_boss.ogg   ⚠️ TODO: Generate
│   │   ├── vampire_lord_boss.ogg  ⚠️ TODO: Generate
│   │   ├── pam_boss.ogg           ⚠️ TODO: Generate
│   │   ├── dark_miku_boss.ogg     ⚠️ TODO: Generate
│   │   ├── despair_miku_boss.ogg  ⚠️ TODO: Generate
│   │   ├── otaku_fortress.ogg     ⚠️ TODO: Generate
│   │   ├── miku_rescue.ogg        ⚠️ TODO: Generate
│   │   ├── credits_music.ogg      ⚠️ TODO: Generate
│   │   └── combat_layer.ogg       ⚠️ TODO: Generate (optional)
│   │
│   └── sfx/                        # 35 sound effects
│       ├── README.md              ✅ Created
│       ├── combat/                ✅ Folder created
│       │   ├── .gitkeep           ✅ Created
│       │   ├── hit_impact.ogg     ⚠️ TODO: Download
│       │   ├── enemy_death.ogg    ⚠️ TODO: Download
│       │   ├── player_hurt.ogg    ⚠️ TODO: Download
│       │   ├── level_up.ogg       ⚠️ TODO: Download
│       │   ├── xp_collect.ogg     ⚠️ TODO: Download
│       │   ├── critical_hit.ogg   ⚠️ TODO: Download
│       │   ├── dodge_roll.ogg     ⚠️ TODO: Download
│       │   ├── parry_block.ogg    ⚠️ TODO: Download
│       │   └── enemy_spawn.ogg    ⚠️ TODO: Download
│       │
│       ├── weapons/               ✅ Folder created
│       │   ├── .gitkeep           ✅ Created
│       │   ├── sword_slash.ogg    ⚠️ TODO: Download
│       │   ├── bow_shoot.ogg      ⚠️ TODO: Download
│       │   ├── lightning_zap.ogg  ⚠️ TODO: Download
│       │   ├── earth_slam.ogg     ⚠️ TODO: Download
│       │   ├── daggers_slash.ogg  ⚠️ TODO: Download
│       │   ├── acid_sizzle.ogg    ⚠️ TODO: Download
│       │   ├── flute_notes.ogg    ⚠️ TODO: Download
│       │   └── magic_slash.ogg    ⚠️ TODO: Download
│       │
│       ├── ui/                    ✅ Folder created
│       │   ├── .gitkeep           ✅ Created
│       │   ├── button_click.ogg   ⚠️ TODO: Download
│       │   ├── menu_open.ogg      ⚠️ TODO: Download
│       │   ├── menu_close.ogg     ⚠️ TODO: Download
│       │   ├── item_pickup.ogg    ⚠️ TODO: Download
│       │   ├── notification.ogg   ⚠️ TODO: Download
│       │   ├── fragment_collect.ogg ⚠️ TODO: Download
│       │   └── chat_message.ogg   ⚠️ TODO: Download
│       │
│       ├── bosses/                ✅ Folder created
│       │   ├── .gitkeep           ✅ Created
│       │   ├── dragon_roar.ogg    ⚠️ TODO: Download
│       │   ├── vampire_laugh.ogg  ⚠️ TODO: Download
│       │   ├── boss_phase_change.ogg ⚠️ TODO: Download
│       │   ├── pam_anime_shout.ogg ⚠️ TODO: Download
│       │   ├── dark_magic.ogg     ⚠️ TODO: Download
│       │   └── tragic_note.ogg    ⚠️ TODO: Download
│       │
│       └── environment/           ✅ Folder created
│           ├── .gitkeep           ✅ Created
│           ├── footstep_grass.ogg ⚠️ TODO: Download
│           ├── footstep_sand.ogg  ⚠️ TODO: Download
│           ├── footstep_snow.ogg  ⚠️ TODO: Download
│           ├── cage_shatter.ogg   ⚠️ TODO: Download
│           └── ritual_chant.ogg   ⚠️ TODO: Download
│
├── scripts/
│   ├── audio_manager.gd           ✅ COMPLETE & ACTIVE
│   ├── settings_menu.gd           ✅ CREATED (needs scene)
│   ├── player.gd                  ✅ Integrated
│   ├── enemy.gd                   ✅ Integrated
│   ├── weapon.gd                  ✅ Integrated
│   ├── boss_manager.gd            ✅ Integrated
│   ├── biome_generator.gd         ✅ Integrated
│   ├── upgrade_menu.gd            ✅ Integrated
│   └── save_system.gd             ✅ Compatible
│
├── project.godot                  ✅ AudioManager in autoload
├── MUSIC_GENERATION.md            ✅ Complete guide
├── SFX_DOWNLOAD.md                ✅ Complete guide
└── AUDIO_SYSTEM_IMPLEMENTATION.md ✅ This file
```

---

## 🔧 HOW IT WORKS

### Music System

**Crossfade System:**
```gdscript
# Two AudioStreamPlayer nodes alternate
music_player_1 plays Track A
↓ Player enters new biome
music_player_2 starts Track B at -80db
↓ Tween fades:
  - player_1: 0db → -80db (3 seconds)
  - player_2: -80db → 0db (3 seconds)
↓ Swap players
music_player_2 is now current, player_1 is next
```

**Biome Music Flow:**
```
Game Start
  → BiomeGenerator._ready() (line 80)
    → AudioManager.play_biome_music("Starting Forest")
      → Plays forest_music.ogg

Player moves to Desert
  → BiomeGenerator.update_current_biome() (line 278)
    → AudioManager.play_biome_music("Desert Wasteland")
      → Crossfades to desert_music.ogg

Boss spawns
  → BossManager.spawn_fire_dragon() (line 179)
    → AudioManager.play_boss_music("FireDragon")
      → Crossfades to fire_dragon_boss.ogg

Boss defeated
  → BossManager._on_boss_defeated() (line 255)
    → AudioManager.play_music("victory")
      → Plays victory_fanfare.ogg for 3 seconds
    → AudioManager.return_to_biome_music()
      → Returns to volcanic_music.ogg
```

---

### SFX System

**Sound Effect Pooling:**
```gdscript
# 20 AudioStreamPlayer nodes in pool
[SFXPlayer_0, SFXPlayer_1, ..., SFXPlayer_19]

Player takes damage
  → AudioManager.play_sfx("player_hurt")
    → Find first non-playing player (e.g., SFXPlayer_5)
    → Load player_hurt.ogg
    → Play sound
    → Player automatically returns to pool when finished

20 sounds playing at once
  → AudioManager.play_sfx("hit_impact")
    → All players busy
    → Interrupts oldest sound (SFXPlayer_0)
```

---

### Volume System

**Volume Flow:**
```
Settings Menu Slider (0-100)
  ↓
AudioManager.set_music_volume(value / 100.0)
  ↓
master_volume * music_volume = final_volume
  ↓
linear_to_db(final_volume) = volume_db
  ↓
music_player.volume_db = volume_db
  ↓
SaveSystem.save_data.settings.music_volume = value
  ↓
Saved to user://save_game.dat
```

---

## 🚀 NEXT STEPS (What YOU Need to Do)

### Step 1: Generate Music Tracks (3-4 hours)
📄 **See:** `MUSIC_GENERATION.md`

1. Sign up at https://suno.ai/
2. Copy each prompt from MUSIC_GENERATION.md
3. Generate all 17 tracks
4. Download as MP3
5. Convert to OGG using:
   - Online: https://convertio.co/mp3-ogg/
   - OR FFmpeg: `ffmpeg -i input.mp3 -c:a libvorbis -q:a 5 output.ogg`
6. Place in `res://audio/music/`
7. In Godot: Select each file → Import tab → Loop: ON → Reimport

---

### Step 2: Download Sound Effects (30-45 minutes)
📄 **See:** `SFX_DOWNLOAD.md`

1. Create account at https://freesound.org/
2. Download all 35 sounds using links in SFX_DOWNLOAD.md
3. Rename to match naming convention
4. Convert to OGG if needed
5. Place in correct subfolders:
   - `res://audio/sfx/combat/`
   - `res://audio/sfx/weapons/`
   - `res://audio/sfx/ui/`
   - `res://audio/sfx/bosses/`
   - `res://audio/sfx/environment/`
6. In Godot: Select each file → Import tab → Loop: OFF → Reimport

---

### Step 3: Create Settings Menu Scene (15 minutes)

**Option A: Add to Existing Settings Menu**
If you already have a settings/options menu:

1. Open your settings menu scene
2. Add 3 HSlider nodes:
   - `MasterVolumeSlider` (min: 0, max: 100, value: 100)
   - `MusicVolumeSlider` (min: 0, max: 100, value: 70)
   - `SFXVolumeSlider` (min: 0, max: 100, value: 100)
3. Attach `settings_menu.gd` script
4. Connect sliders in Inspector

**Option B: Create New Settings Menu Scene**

1. Scene → New Scene
2. Root: CanvasLayer (name: "SettingsMenu")
3. Add nodes:
   ```
   CanvasLayer (SettingsMenu)
   └── Panel
       ├── VBoxContainer
       │   ├── Label (text: "Master Volume")
       │   ├── HSlider (name: "MasterVolumeSlider")
       │   ├── Label (text: "Music Volume")
       │   ├── HSlider (name: "MusicVolumeSlider")
       │   ├── Label (text: "SFX Volume")
       │   └── HSlider (name: "SFXVolumeSlider")
       └── Button (name: "CloseButton", text: "Close")
   ```
4. Configure sliders:
   - Min Value: 0
   - Max Value: 100
   - Step: 1
   - Value: 100 (Master), 70 (Music), 100 (SFX)
5. Attach script: `res://scripts/settings_menu.gd`
6. Save as: `res://scenes/ui/settings_menu.tscn`

**Option C: Use Placeholder Script Only**
The `settings_menu.gd` script will work even without a scene - AudioManager handles volume internally. The script is optional UI.

---

### Step 4: Test Everything (30 minutes)

See Testing Checklist below ↓

---

## ✅ TESTING CHECKLIST

### Music Tests
- [ ] Game starts with forest music
- [ ] Music changes when entering desert biome
- [ ] Music crossfades smoothly (no clicks/pops)
- [ ] Fire Dragon boss spawns with boss music + roar
- [ ] Vampire Lord boss spawns with boss music + laugh
- [ ] Victory fanfare plays when boss dies
- [ ] Music returns to biome music after victory
- [ ] Game over music plays when player dies
- [ ] All 17 music files load without errors

### SFX Tests
- [ ] Player hurt sound plays when taking damage
- [ ] XP collect sound plays when picking up XP
- [ ] Level up sound plays when leveling up
- [ ] Enemy death sound plays when enemy dies
- [ ] Hit impact sound plays when hitting enemy
- [ ] Critical hit sound plays on critical hits
- [ ] Weapon sounds play for each weapon type:
  - [ ] MikuSword (magic slash)
  - [ ] WoodenSword (sword slash)
  - [ ] FrostBow (bow shoot)
  - [ ] LightningChain (lightning zap)
  - [ ] EarthshatterStaff (earth slam)
  - [ ] ShadowDaggers (daggers slash)
  - [ ] AcidGauntlets (acid sizzle)
  - [ ] EnchantingFlute (flute notes)
- [ ] Button click plays when clicking upgrade menu buttons
- [ ] Menu open/close sounds play
- [ ] Boss roar/laugh plays when boss spawns
- [ ] Phase change sound plays when boss changes phase
- [ ] All 35 SFX load without errors

### Volume Control Tests
- [ ] Master slider controls all audio
- [ ] Music slider controls music only (not SFX)
- [ ] SFX slider controls SFX only (not music)
- [ ] Volume settings save to file
- [ ] Volume settings load on game restart
- [ ] Muting master volume stops all sound

### Performance Tests
- [ ] No lag when playing multiple SFX simultaneously
- [ ] No stutter when music changes
- [ ] No memory leaks (check in profiler)
- [ ] Game runs smoothly on mobile (if targeting mobile)
- [ ] Audio pool handles 20+ simultaneous sounds

### Console Tests
- [ ] No errors in Godot Output console
- [ ] AudioManager initialization message appears
- [ ] Music track names logged correctly
- [ ] SFX names logged correctly (or warnings if missing)

---

## 🐛 TROUBLESHOOTING

### Issue: "AudioManager: Music file missing" warnings
**Cause:** Music files not generated yet
**Solution:** This is expected! Generate music files using MUSIC_GENERATION.md

---

### Issue: No sound plays at all
**Checks:**
1. ✅ AudioManager in Project Settings → Autoload?
2. ✅ Audio files in correct folders?
3. ✅ Files are OGG format (not MP3/WAV)?
4. ✅ Master volume not at 0?
5. ✅ Check Output console for errors

---

### Issue: Music doesn't loop
**Solution:**
1. Select music file in FileSystem
2. Import tab → Loop: ON
3. Click "Reimport"

---

### Issue: SFX too loud/quiet
**Solutions:**
- Adjust SFX volume in game settings
- OR modify play_sfx calls with volume_modifier:
  ```gdscript
  AudioManager.play_sfx("explosion", 0.5)  # 50% volume
  ```

---

### Issue: Music crossfade has clicking/popping
**Solutions:**
1. Check OGG quality (use quality 5 in FFmpeg)
2. Ensure files are seamlessly looping
3. Adjust fade_time in play_music() calls

---

### Issue: Settings don't save
**Checks:**
1. ✅ SaveSystem autoload active?
2. ✅ User data folder writable?
3. ✅ Check console for save errors

---

## 📖 API REFERENCE

### AudioManager Functions

#### Music Control
```gdscript
# Play a music track with crossfade
AudioManager.play_music(track_name: String, fade_time: float = 2.0)

# Stop current music
AudioManager.stop_music(fade_time: float = 2.0)

# Pause/resume music
AudioManager.pause_music()
AudioManager.resume_music()

# Helper: Play biome music
AudioManager.play_biome_music(biome_name: String)
# Biome names: "Starting Forest", "Desert Wasteland", "Frozen Tundra",
#              "Volcanic Darklands", "Blood Temple"

# Helper: Play boss music
AudioManager.play_boss_music(boss_name: String)
# Boss names: "FireDragon", "VampireLord", "PamTungKen",
#             "DarkMiku", "DespairMiku"

# Return to biome music after boss
AudioManager.return_to_biome_music()
```

#### SFX Control
```gdscript
# Play a sound effect
AudioManager.play_sfx(sfx_name: String, volume_modifier: float = 1.0)

# Helper: Play weapon sound
AudioManager.play_weapon_sound(weapon_class: String)
```

#### Volume Control
```gdscript
# Set volumes (0.0 - 1.0)
AudioManager.set_master_volume(value: float)
AudioManager.set_music_volume(value: float)
AudioManager.set_sfx_volume(value: float)

# Mute/unmute all
AudioManager.mute_all()
AudioManager.unmute_all()
```

#### Available Music Tracks
```gdscript
"menu"                 # Main menu
"victory"              # Victory fanfare (30s)
"game_over"            # Game over (1min)
"forest"               # Starting Forest
"desert"               # Desert Wasteland
"tundra"               # Frozen Tundra
"volcanic"             # Volcanic Darklands
"blood_temple"         # Blood Temple
"fire_dragon_boss"     # Fire Dragon boss
"vampire_lord_boss"    # Vampire Lord boss
"pam_boss"             # Pam Tung Ken boss
"dark_miku_boss"       # Dark Miku boss
"despair_miku_boss"    # Despair Miku boss
"otaku_fortress"       # Otaku Fortress
"miku_rescue"          # Miku rescue event
"credits"              # Credits music
"combat_layer"         # Combat intensity (optional)
```

#### Available SFX
See sfx_library dictionary in `audio_manager.gd` for full list (35 sounds).

---

## 🎉 YOU'RE DONE!

Once you've completed the Next Steps:
- ✅ All music generated and imported
- ✅ All SFX downloaded and imported
- ✅ Settings menu created (optional)
- ✅ All tests passing

Your game will have a COMPLETE professional audio system! 🎵🔊✨

---

**Questions? Issues?**
Check console output for detailed logging from AudioManager.
All audio calls are logged for debugging.

**Good luck and happy developing! 🎮**
