extends Node
## AudioManager Singleton - Central audio control system for Miku's Despair
##
## Handles all music and sound effects in the game with:
## - Dynamic music system (biome/boss music with crossfading)
## - SFX pooling for performance
## - Volume controls (Master, Music, SFX)
## - Settings integration with SaveSystem

# ============================================================================
# MUSIC PLAYERS
# ============================================================================

var music_player_1: AudioStreamPlayer
var music_player_2: AudioStreamPlayer
var current_music_player: AudioStreamPlayer
var next_music_player: AudioStreamPlayer

# ============================================================================
# SFX POOL
# ============================================================================

var sfx_pool: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE = 20

# ============================================================================
# VOLUME SETTINGS
# ============================================================================

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0

# ============================================================================
# MUSIC TRACKS (PRELOADED PATHS)
# ============================================================================

var music_tracks := {
	# Menu & General
	"menu": "res://audio/music/menu_music.ogg",
	"victory": "res://audio/music/victory_fanfare.ogg",
	"game_over": "res://audio/music/game_over.ogg",

	# Biome Music
	"forest": "res://audio/music/forest_music.ogg",
	"desert": "res://audio/music/desert_music.ogg",
	"tundra": "res://audio/music/tundra_music.ogg",
	"volcanic": "res://audio/music/volcanic_music.ogg",
	"blood_temple": "res://audio/music/blood_temple_music.ogg",

	# Boss Music
	"fire_dragon_boss": "res://audio/music/fire_dragon_boss.ogg",
	"vampire_lord_boss": "res://audio/music/vampire_lord_boss.ogg",
	"pam_boss": "res://audio/music/pam_boss.ogg",
	"dark_miku_boss": "res://audio/music/dark_miku_boss.ogg",
	"despair_miku_boss": "res://audio/music/despair_miku_boss.ogg",

	# Special Areas
	"otaku_fortress": "res://audio/music/otaku_fortress.ogg",
	"miku_rescue": "res://audio/music/miku_rescue.ogg",
	"credits": "res://audio/music/credits_music.ogg",

	# Optional
	"combat_layer": "res://audio/music/combat_layer.ogg"
}

# ============================================================================
# SFX LIBRARY (PRELOADED PATHS)
# ============================================================================

var sfx_library := {
	# === COMBAT SOUNDS ===
	"hit_impact": "res://audio/sfx/combat/hit_impact.ogg",
	"enemy_death": "res://audio/sfx/combat/enemy_death.ogg",
	"player_hurt": "res://audio/sfx/combat/player_hurt.ogg",
	"level_up": "res://audio/sfx/combat/level_up.ogg",
	"xp_collect": "res://audio/sfx/combat/xp_collect.ogg",
	"critical_hit": "res://audio/sfx/combat/critical_hit.ogg",
	"dodge_roll": "res://audio/sfx/combat/dodge_roll.ogg",
	"parry_block": "res://audio/sfx/combat/parry_block.ogg",
	"enemy_spawn": "res://audio/sfx/combat/enemy_spawn.ogg",

	# === WEAPON SOUNDS ===
	"sword_slash": "res://audio/sfx/weapons/sword_slash.ogg",
	"bow_shoot": "res://audio/sfx/weapons/bow_shoot.ogg",
	"lightning_zap": "res://audio/sfx/weapons/lightning_zap.ogg",
	"earth_slam": "res://audio/sfx/weapons/earth_slam.ogg",
	"daggers_slash": "res://audio/sfx/weapons/daggers_slash.ogg",
	"acid_sizzle": "res://audio/sfx/weapons/acid_sizzle.ogg",
	"flute_notes": "res://audio/sfx/weapons/flute_notes.ogg",
	"magic_slash": "res://audio/sfx/weapons/magic_slash.ogg",

	# === UI SOUNDS ===
	"button_click": "res://audio/sfx/ui/button_click.ogg",
	"menu_open": "res://audio/sfx/ui/menu_open.ogg",
	"menu_close": "res://audio/sfx/ui/menu_close.ogg",
	"item_pickup": "res://audio/sfx/ui/item_pickup.ogg",
	"notification": "res://audio/sfx/ui/notification.ogg",
	"fragment_collect": "res://audio/sfx/ui/fragment_collect.ogg",
	"chat_message": "res://audio/sfx/ui/chat_message.ogg",

	# === BOSS SOUNDS ===
	"dragon_roar": "res://audio/sfx/bosses/dragon_roar.ogg",
	"vampire_laugh": "res://audio/sfx/bosses/vampire_laugh.ogg",
	"boss_phase_change": "res://audio/sfx/bosses/boss_phase_change.ogg",
	"pam_anime_shout": "res://audio/sfx/bosses/pam_anime_shout.ogg",
	"dark_magic": "res://audio/sfx/bosses/dark_magic.ogg",
	"tragic_note": "res://audio/sfx/bosses/tragic_note.ogg",

	# === ENVIRONMENT SOUNDS ===
	"footstep_grass": "res://audio/sfx/environment/footstep_grass.ogg",
	"footstep_sand": "res://audio/sfx/environment/footstep_sand.ogg",
	"footstep_snow": "res://audio/sfx/environment/footstep_snow.ogg",
	"cage_shatter": "res://audio/sfx/environment/cage_shatter.ogg",
	"ritual_chant": "res://audio/sfx/environment/ritual_chant.ogg"
}

# ============================================================================
# STATE VARIABLES
# ============================================================================

var current_music: String = ""
var is_crossfading: bool = false
var current_biome_music: String = ""  # Track biome music for boss returns

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("=== AudioManager Init ===")

	# Create music players
	music_player_1 = AudioStreamPlayer.new()
	music_player_2 = AudioStreamPlayer.new()
	music_player_1.name = "MusicPlayer1"
	music_player_2.name = "MusicPlayer2"
	music_player_1.bus = "Music"
	music_player_2.bus = "Music"
	add_child(music_player_1)
	add_child(music_player_2)

	current_music_player = music_player_1
	next_music_player = music_player_2

	# Create SFX pool
	for i in range(SFX_POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)

	# Load settings from SaveSystem
	load_audio_settings()

	# Apply volumes
	apply_volumes()

	print("✓ AudioManager ready!")
	print("  Music tracks available: ", music_tracks.size())
	print("  SFX library size: ", sfx_library.size())
	print("  SFX pool size: ", SFX_POOL_SIZE)
	print("  Master Volume: ", master_volume)
	print("  Music Volume: ", music_volume)
	print("  SFX Volume: ", sfx_volume)

# ============================================================================
# MUSIC SYSTEM - Dynamic Background Music
# ============================================================================

## Play a music track with optional crossfade
func play_music(track_name: String, fade_time: float = 2.0):
	print("🎵 play_music() called: ", track_name, " (fade: ", fade_time, "s)")

	# Skip if already playing
	if track_name == current_music and current_music_player.playing:
		print("  ⚠️ Already playing this track, skipping")
		return

	# Validate track exists
	if not track_name in music_tracks:
		push_warning("AudioManager: Music track not found: " + track_name)
		return

	var music_path = music_tracks[track_name]
	print("  → Music path: ", music_path)

	# Check if file exists before loading
	if not FileAccess.file_exists(music_path):
		push_warning("AudioManager: Music file missing: " + music_path + " (placeholder)")
		return

	var music_stream = load(music_path)

	if not music_stream:
		push_error("AudioManager: Failed to load music: " + music_path)
		return

	print("  ✅ Loaded music stream successfully")
	print("  ♪ Playing music: ", track_name)

	# If no music playing, just start
	if not current_music_player.playing:
		current_music_player.stream = music_stream
		current_music_player.play()
		current_music = track_name
		return

	# Crossfade to new track
	crossfade_music(music_stream, fade_time)
	current_music = track_name

## Crossfade between two music tracks
func crossfade_music(new_stream: AudioStream, fade_time: float):
	if is_crossfading:
		return

	is_crossfading = true

	# Setup next player
	next_music_player.stream = new_stream
	next_music_player.volume_db = -80  # Start silent
	next_music_player.play()

	# Fade out current, fade in next
	var tween = create_tween()
	tween.set_parallel(true)

	# Fade out current
	var current_target_db = -80.0
	tween.tween_property(current_music_player, "volume_db", current_target_db, fade_time)

	# Fade in next
	var next_target_db = linear_to_db(music_volume * master_volume)
	tween.tween_property(next_music_player, "volume_db", next_target_db, fade_time)

	await tween.finished

	# Stop and swap players
	current_music_player.stop()
	var temp = current_music_player
	current_music_player = next_music_player
	next_music_player = temp

	is_crossfading = false

## Stop music with optional fade out
func stop_music(fade_time: float = 2.0):
	if not current_music_player.playing:
		return

	print("♪ Stopping music")

	if fade_time > 0:
		var tween = create_tween()
		tween.tween_property(current_music_player, "volume_db", -80, fade_time)
		await tween.finished

	current_music_player.stop()
	current_music = ""

## Pause current music
func pause_music():
	if current_music_player.playing:
		current_music_player.stream_paused = true

## Resume paused music
func resume_music():
	if current_music_player.stream:
		current_music_player.stream_paused = false

# ============================================================================
# SFX SYSTEM - Sound Effects with Pooling
# ============================================================================

## Play a sound effect with optional volume modifier
func play_sfx(sfx_name: String, volume_modifier: float = 1.0):
	# Validate SFX exists
	if not sfx_name in sfx_library:
		push_warning("AudioManager: SFX not found: " + sfx_name)
		return

	var sfx_path = sfx_library[sfx_name]

	# Check if file exists before loading
	if not FileAccess.file_exists(sfx_path):
		# Don't spam warnings for missing SFX (placeholder system)
		return

	var sfx_stream = load(sfx_path)

	if not sfx_stream:
		push_error("AudioManager: Failed to load SFX: " + sfx_path)
		return

	# Find available player from pool
	var player = get_available_sfx_player()
	if not player:
		# Pool full, skip this sound
		return

	# Play sound
	player.stream = sfx_stream
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume_modifier)
	player.play()

## Get an available SFX player from the pool
func get_available_sfx_player() -> AudioStreamPlayer:
	# Find first non-playing player
	for player in sfx_pool:
		if not player.playing:
			return player

	# All busy, return oldest one (will interrupt)
	return sfx_pool[0]

# ============================================================================
# VOLUME CONTROL - Master, Music, SFX
# ============================================================================

## Set master volume (0.0 - 1.0)
func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	apply_volumes()
	save_audio_settings()

## Set music volume (0.0 - 1.0)
func set_music_volume(value: float):
	music_volume = clamp(value, 0.0, 1.0)
	apply_volumes()
	save_audio_settings()

## Set SFX volume (0.0 - 1.0)
func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	save_audio_settings()
	# Note: SFX volume applied per-play, not globally

## Apply volume changes to audio buses
func apply_volumes():
	# Apply to music players
	var music_db = linear_to_db(music_volume * master_volume)
	if music_db <= -79:
		music_db = -80  # Clamp to silence

	current_music_player.volume_db = music_db
	next_music_player.volume_db = music_db

## Mute all audio
func mute_all():
	set_master_volume(0.0)

## Unmute all audio
func unmute_all():
	set_master_volume(1.0)

# ============================================================================
# SETTINGS INTEGRATION - Save/Load with SaveSystem
# ============================================================================

## Save audio settings to SaveSystem
func save_audio_settings():
	if not SaveSystem:
		push_warning("AudioManager: SaveSystem not found, cannot save settings")
		return

	SaveSystem.save_data.settings.master_volume = master_volume
	SaveSystem.save_data.settings.music_volume = music_volume
	SaveSystem.save_data.settings.sfx_volume = sfx_volume
	SaveSystem.save_game()

## Load audio settings from SaveSystem
func load_audio_settings():
	if not SaveSystem:
		push_warning("AudioManager: SaveSystem not found, using defaults")
		return

	var settings = SaveSystem.save_data.settings
	master_volume = settings.get("master_volume", 1.0)
	music_volume = settings.get("music_volume", 0.7)
	sfx_volume = settings.get("sfx_volume", 1.0)

	print("  Loaded audio settings from SaveSystem:")
	print("    Master: ", master_volume)
	print("    Music: ", music_volume)
	print("    SFX: ", sfx_volume)

# ============================================================================
# HELPER FUNCTIONS - Biome & Boss Music
# ============================================================================

## Play music for a specific biome
func play_biome_music(biome_name: String):
	var track_map = {
		"Starting Forest": "forest",
		"Desert Wasteland": "desert",
		"Frozen Tundra": "tundra",
		"Volcanic Darklands": "volcanic",
		"Blood Temple": "blood_temple"
	}

	if biome_name in track_map:
		var track = track_map[biome_name]
		current_biome_music = track  # Remember for boss return
		play_music(track)
	else:
		push_warning("AudioManager: Unknown biome: " + biome_name)

## Play music for a specific boss
func play_boss_music(boss_name: String):
	print("🎵 AudioManager.play_boss_music() called with boss: ", boss_name)

	var boss_map = {
		"FireDragon": "fire_dragon_boss",
		"VampireLord": "vampire_lord_boss",
		"PamTungKen": "pam_boss",
		"DarkMiku": "dark_miku_boss",
		"DespairMiku": "despair_miku_boss"
	}

	if boss_name in boss_map:
		var track = boss_map[boss_name]
		print("  → Mapped to track: ", track)
		play_music(track, 1.0)  # Faster fade for boss entrance
	else:
		push_warning("AudioManager: Unknown boss: " + boss_name)

## Return to biome music after boss defeat
func return_to_biome_music():
	if current_biome_music != "":
		play_music(current_biome_music, 3.0)  # Slower fade after boss
	else:
		push_warning("AudioManager: No biome music to return to")

## Play weapon-specific sound based on weapon class name
func play_weapon_sound(weapon_name: String):
	var sound_map = {
		"MikuSword": "magic_slash",
		"WoodenSword": "sword_slash",
		"FrostBow": "bow_shoot",
		"LightningChain": "lightning_zap",
		"EarthshatterStaff": "earth_slam",
		"ShadowDaggers": "daggers_slash",
		"AcidGauntlets": "acid_sizzle",
		"EnchantingFlute": "flute_notes"
	}

	var sound_name = sound_map.get(weapon_name, "sword_slash")
	play_sfx(sound_name)
