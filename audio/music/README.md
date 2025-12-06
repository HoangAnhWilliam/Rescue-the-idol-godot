# Music Tracks Folder

This folder contains all 17 background music tracks for the game.

## Required Music Files (17 tracks):

### MENU & GENERAL (3):
1. `menu_music.ogg` - Main Menu Music - Calm atmospheric
2. `victory_fanfare.ogg` - Victory Fanfare - Short triumph (30 sec)
3. `game_over.ogg` - Game Over Music - Sad reflective

### BIOME MUSIC (5):
4. `forest_music.ogg` - Starting Forest - Light exploration
5. `desert_music.ogg` - Desert Wasteland - Mysterious sparse
6. `tundra_music.ogg` - Frozen Tundra - Cold ethereal
7. `volcanic_music.ogg` - Volcanic Darklands - Intense dangerous
8. `blood_temple_music.ogg` - Blood Temple - Dark evil gothic

### BOSS MUSIC (5):
9. `fire_dragon_boss.ogg` - Fire Dragon Boss - Epic orchestral
10. `vampire_lord_boss.ogg` - Vampire Lord Boss - Gothic organ
11. `pam_boss.ogg` - Pam Tung Ken Boss - Anime OP remix
12. `dark_miku_boss.ogg` - Dark Miku Boss - Dark J-pop
13. `despair_miku_boss.ogg` - Despair Miku Boss - Tragic orchestral

### SPECIAL AREAS (3):
14. `otaku_fortress.ogg` - Otaku Fortress - Anime electronic
15. `miku_rescue.ogg` - Miku Rescue Event - Emotional hopeful
16. `credits_music.ogg` - Credits Music - Uplifting ending

### DYNAMIC (1):
17. `combat_layer.ogg` - Combat Intensity Layer (optional)

## Format Requirements:
- **Format**: OGG Vorbis
- **Quality**: 128 kbps (balanced quality/size)
- **Duration**: 3 minutes each (except Victory 30s, Game Over 1min)
- **Loop**: Seamless loop points
- **Import Settings in Godot**:
  - Loop: ENABLED
  - Loop Offset: 0
  - Compression: Vorbis

## How to Generate:

See `/MUSIC_GENERATION.md` for detailed Suno AI prompts and generation instructions.

## Current Status:
⚠️ **PLACEHOLDER** - Music files need to be generated and added.

The AudioManager is ready to use these files once they are added to this folder.
