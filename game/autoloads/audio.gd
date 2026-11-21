extends Node
## Sound effects player pool, on the buses of default_bus_layout.tres (Master, Music, SFX, UI).
## Each sound has a voice limit: a play beyond it, or with no free player, is dropped silently.
## Holds no run state. Audio does not follow GameClock (pitch and speed unchanged under F4).
## Never log per sound played.

const SFX_BUS: StringName = &"SFX"
## Players in the pool (technical, not gameplay).
const POOL_SIZE: int = 16
## Default number of players allowed to play the same stream at once.
const DEFAULT_MAX_VOICES: int = 3

## Plays refused (pool full or voice limit reached), for debugging.
var dropped_count: int = 0

var _players: Array[AudioStreamPlayer] = []
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
