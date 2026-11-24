class_name RunState
extends RefCounted
## What a run is about, apart from its nodes (story 4.7): the seed, whether the player chose it, the floor being played.
## Carried by the Run; the generator and the menus read it. Only the Run writes it (the shards, since story 5.4).

## The seed of the run (40 bits, see RunRng).
var run_seed: int = 0
## True when the seed was given (shared code, F1 panel) instead of drawn: such a run does not count for progression.
var seeded: bool = false
## Index of the floor being played; only the first floor exists for now.
var floor_index: int = 0
## Shards held (story 5.4): never negative. Run keeps the bus (Events.shards_changed) in step with it.
var shards: int = 0
## The time of the wake-up (story 6.6), in minutes from the evening midnight (see WakeClock); -1 until the run ends.
var wake_minute: int = -1
## Seconds played, the pauses and the screens that freeze the run excluded (the Run counts them): kept across a resume so that
## the duration of a night is its playing time.
var play_seconds: float = 0.0


func add_shards(amount: int) -> void:
	if amount > 0:
		shards += amount


## Pays this many shards. False, and nothing changes, when there are not enough (or the amount is negative).
func spend_shards(amount: int) -> bool:
	if amount < 0 or amount > shards:
		return false
	shards -= amount
	return true


## The state as saved in run.json. The seed goes as text (large integers must not travel as JSON floats).
func to_dict() -> Dictionary:
	return {
		"seed": str(run_seed),
		"seeded": seeded,
		"floor_index": floor_index,
		"shards": shards,
		"wake_minute": wake_minute,
		"play_seconds": play_seconds,
	}


## The state of a saved dictionary, null when a field is missing or of the wrong type.
static func from_dict(data: Dictionary) -> RunState:
	var seed_text: Variant = data.get("seed")
	if typeof(seed_text) != TYPE_STRING:
		return null
	var text: String = seed_text
	if not text.is_valid_int():
		return null
	var state: RunState = RunState.new()
	state.run_seed = text.to_int()
	state.seeded = data.get("seeded") == true
	var floor_value: Variant = data.get("floor_index")
	var shards_value: Variant = data.get("shards")
	var wake_value: Variant = data.get("wake_minute", -1)
	if not _is_number(floor_value) or not _is_number(shards_value) or not _is_number(wake_value):
		return null
	state.floor_index = whole(floor_value)
	state.shards = maxi(whole(shards_value), 0)
	state.wake_minute = whole(wake_value)
	var played: Variant = data.get("play_seconds", 0.0)
	if _is_number(played):
		var seconds: float = played
		state.play_seconds = maxf(seconds, 0.0) if is_finite(seconds) else 0.0
	return state


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


## A whole number read from JSON (numbers come back as floats), default for anything else.
static func whole(value: Variant, default: int = 0) -> int:
	if typeof(value) == TYPE_INT:
		var integer: int = value
		return integer
	if typeof(value) == TYPE_FLOAT:
		var number: float = value
		return int(number) if is_finite(number) else default
	return default


## A string read from JSON; call after checking the type.
static func text_of(value: Variant) -> String:
	var text: String = value
	return text
