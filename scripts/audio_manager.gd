extends Node

# Global audio router. Registered as autoload "AudioManager".
#
# All sound files live in res://assets/sounds/<name>.mp3. Missing files
# are silently skipped — call sites can fire-and-forget regardless of
# whether the audio artist has produced a recording yet.
#
# Usage from anywhere in the codebase:
#   AudioManager.play_sfx("seed_pick")
#   AudioManager.tick_water()       # call every frame while watering
#
# Background music starts automatically in _ready() at 20% volume and
# loops via the `finished` signal (no need to set per-stream loop flags,
# which differ across AudioStream subtypes).

const SOUNDS_DIR := "res://assets/sounds/"

const SFX_NAMES := [
	"seed_pick",
	"seed_place",
	"flower_ready",
	"flower_dead",
	"pot_clean",
	"flower_harvest",
	"flower_workbench_place",
	"workbench_modal_pop",
	"workbench_flower",
	"workbench_remove",
	"bouquet_sold",
	"customer_leave",
	"customer_arrive",
	# Extended set — game-state, negative feedback, UI polish
	"day_complete",
	"game_over",
	"customer_angry",
	"can_empty",
	"pouch_full",
	"time_warning",
]
const MUSIC_NAME := "bg_music"
const WATER_NAME := "water"

const SFX_POOL_SIZE := 8
const MUSIC_VOLUME_LINEAR := 1.0
const WATER_VOLUME_LINEAR := 0.7
const WATER_FADEOUT_SECONDS := 0.15       # how long after last tick to stop

# name -> AudioStream (or null if the file is missing)
var streams: Dictionary = {}

var music_player: AudioStreamPlayer
var water_player: AudioStreamPlayer
var sfx_pool: Array = []  # AudioStreamPlayer pool for one-shots
var water_active_until: float = 0.0
var _throttle_until: Dictionary = {}  # name -> next-allowed time

func _ready() -> void:
	_load_streams()
	_setup_music()
	_setup_water_loop()
	_setup_sfx_pool()
	play_music()

# ── Loading ───────────────────────────────────────────────────────────

func _load_streams() -> void:
	var names: Array = SFX_NAMES.duplicate()
	names.append(MUSIC_NAME)
	names.append(WATER_NAME)
	for key in names:
		var path: String = SOUNDS_DIR + key + ".mp3"
		if ResourceLoader.exists(path):
			var res: Resource = load(path)
			if res is AudioStream:
				streams[key] = res
				continue
		streams[key] = null

# ── Setup ─────────────────────────────────────────────────────────────

func _setup_music() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = linear_to_db(MUSIC_VOLUME_LINEAR)
	add_child(music_player)
	# Loop by re-playing when the stream finishes, so we don't depend on
	# per-format loop flags (mp3/ogg/wav each expose loop differently).
	music_player.finished.connect(_on_music_finished)

func _on_music_finished() -> void:
	if music_player.stream != null:
		music_player.play()

func _setup_water_loop() -> void:
	water_player = AudioStreamPlayer.new()
	water_player.bus = "Master"
	water_player.volume_db = linear_to_db(WATER_VOLUME_LINEAR)
	add_child(water_player)
	water_player.finished.connect(_on_water_finished)

func _on_water_finished() -> void:
	# Keep looping as long as we're still inside the active window.
	var now: float = Time.get_ticks_msec() / 1000.0
	if now < water_active_until and water_player.stream != null:
		water_player.play()

func _setup_sfx_pool() -> void:
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_pool.append(p)

# ── Public API ────────────────────────────────────────────────────────

func play_music() -> void:
	var s = streams.get(MUSIC_NAME)
	if s == null:
		return
	music_player.stream = s
	music_player.play()

func stop_music() -> void:
	music_player.stop()

func play_sfx(name: String) -> void:
	var s = streams.get(name)
	if s == null:
		return
	# Find an idle player in the pool.
	for p in sfx_pool:
		if not p.playing:
			p.stream = s
			p.play()
			return
	# All busy — recycle the first slot so the most recent SFX still plays.
	var first: AudioStreamPlayer = sfx_pool[0]
	first.stream = s
	first.play()

# Like play_sfx but ignored if the same name fired within the last
# `cooldown` seconds.
func play_sfx_throttled(name: String, cooldown: float = 0.12) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	if _throttle_until.get(name, 0.0) > now:
		return
	_throttle_until[name] = now + cooldown
	play_sfx(name)

# Call every frame while the player is holding F on a tap / pot.
# AudioManager handles the looping + auto-stop on its own.
func tick_water() -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	water_active_until = now + WATER_FADEOUT_SECONDS
	if streams.get(WATER_NAME) == null:
		return
	if not water_player.playing:
		water_player.stream = streams[WATER_NAME]
		water_player.play()

func _process(_delta: float) -> void:
	if water_player.playing:
		var now: float = Time.get_ticks_msec() / 1000.0
		if now > water_active_until:
			water_player.stop()
