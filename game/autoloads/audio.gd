extends Node
## Sound effects player pool, on the buses of default_bus_layout.tres (Master, Music, SFX, UI).
## Each sound has a voice limit: a play beyond it, or with no free player, is dropped silently.
## Holds no run state. Audio does not follow GameClock (pitch and speed unchanged under F4).
## Also plays the provisional music loop on the Music bus, whose low-pass filter muffles it with the lucidity tier (story 3.8).
## Never log per sound played.

const SFX_BUS: StringName = &"SFX"
const MUSIC_BUS: StringName = &"Music"
## Provisional music loop (8 s, generated), replaced by story 7.7.
const MUSIC_LOOP: AudioStream = preload("res://audio/music/music_placeholder.wav")
## Range of AudioEffectLowPassFilter.cutoff_hz; the top is the open filter.
const MIN_CUTOFF_HZ: float = 1.0
const OPEN_CUTOFF_HZ: float = 20500.0
## At exit, wait for this many mixer passes (at most this many ms, polling every EXIT_POLL_MSEC) so the mixer
## releases the stopped playbacks (technical).
const EXIT_FLUSH_PASSES: int = 4
const EXIT_FLUSH_MSEC: int = 600
const EXIT_POLL_MSEC: int = 5
## Players in the pool (technical, not gameplay).
const POOL_SIZE: int = 16
## Default number of players allowed to play the same stream at once.
const DEFAULT_MAX_VOICES: int = 3

## Plays refused (pool full or voice limit reached), for debugging.
var dropped_count: int = 0

var _players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _low_pass: AudioEffectLowPassFilter
## Indices of the players that are not playing, used as a stack.
var _free_players: PackedInt32Array = PackedInt32Array()
## Number of players currently playing each stream.
var _voices: Dictionary[AudioStream, int] = {}


func _ready() -> void:
	if AudioServer.get_bus_index(SFX_BUS) == -1:
		Log.error("audio", "bus %s is missing from default_bus_layout.tres" % SFX_BUS)
		assert(false, "Missing SFX bus")
	for i: int in POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		player.finished.connect(_on_player_finished.bind(i))
		add_child(player)
		_players.append(player)
		_free_players.append(POOL_SIZE - 1 - i) # pops give player 0 first
	_setup_music()


## Stops every sound, music included, so no playback outlives the autoload at exit (a playing stream leaks).
func _exit_tree() -> void:
	for player: AudioStreamPlayer in _players:
		player.stop()
	if _music_player != null:
		_music_player.stop()
	_wait_for_mixer()


## Blocks until the audio mixer has run a few passes (it drops a stopped playback on one of them), at most
## EXIT_FLUSH_MSEC: a playback still held at exit leaks. Called at exit only.
func _wait_for_mixer() -> void:
	var passes: int = 0
	var waited: int = 0
	var last: float = AudioServer.get_time_since_last_mix()
	while passes < EXIT_FLUSH_PASSES and waited < EXIT_FLUSH_MSEC:
		OS.delay_msec(EXIT_POLL_MSEC)
		waited += EXIT_POLL_MSEC
		var now: float = AudioServer.get_time_since_last_mix()
		if now < last:
			passes += 1 # the clock went back to 0: a mix pass happened
		last = now


## Plays the music loop on the Music bus and adds its low-pass filter. Once, here: a new game never restarts it.
func _setup_music() -> void:
	var bus: int = AudioServer.get_bus_index(MUSIC_BUS)
	if bus == -1:
		Log.error("audio", "bus %s is missing from default_bus_layout.tres" % MUSIC_BUS)
		assert(false, "Missing Music bus")
		return
	_low_pass = AudioEffectLowPassFilter.new()
	_low_pass.cutoff_hz = OPEN_CUTOFF_HZ
	AudioServer.add_bus_effect(bus, _low_pass) # only once: every call would stack one more filter
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "Music"
	_music_player.bus = MUSIC_BUS
	_music_player.stream = MUSIC_LOOP
	add_child(_music_player)
	_music_player.play()


## Cutoff of the low-pass filter on the Music bus, in Hz: clamped to its range (20500 = open). Not finite: ignored.
func set_music_muffle(cutoff_hz: float) -> void:
	if _low_pass == null or not is_finite(cutoff_hz):
		return
	_low_pass.cutoff_hz = clampf(cutoff_hz, MIN_CUTOFF_HZ, OPEN_CUTOFF_HZ)


## Current cutoff of the Music low-pass filter, in Hz (OPEN_CUTOFF_HZ without music).
func music_cutoff_hz() -> float:
	return OPEN_CUTOFF_HZ if _low_pass == null else _low_pass.cutoff_hz


## The music player (checks).
func music_player() -> AudioStreamPlayer:
	return _music_player


## Plays stream on the SFX bus. Returns false when the play is dropped (voice limit or pool full).
func play_sfx(stream: AudioStream, max_voices: int = DEFAULT_MAX_VOICES) -> bool:
	if stream == null:
		Log.error("audio", "play_sfx() called without a stream")
		assert(false, "play_sfx() needs a stream")
		return false
	var voices: int = _voices.get(stream, 0)
	if voices >= max_voices or _free_players.is_empty():
		dropped_count += 1
		return false
	var index: int = _free_players[_free_players.size() - 1]
	_free_players.resize(_free_players.size() - 1)
	_voices[stream] = voices + 1
	var player: AudioStreamPlayer = _players[index]
	player.stream = stream
	player.play()
	return true


## Number of players currently playing stream (debug and checks).
func voices_of(stream: AudioStream) -> int:
	return _voices.get(stream, 0)


func _on_player_finished(index: int) -> void:
	var stream: AudioStream = _players[index].stream
	var voices: int = _voices.get(stream, 0)
	if voices <= 1:
		_voices.erase(stream)
	else:
		_voices[stream] = voices - 1
	_free_players.append(index)
