class_name RunOptions
extends RefCounted
## How a Run starts (story 4.2): what to play, and with which seed. Given to Run.setup() before add_child().
## The default is the arena of milestone A with a fresh random seed.

## ARENA: the training arena. ROOM: one pre-drawn room (room_path), for the F1 panel and the checks. FLOOR: a generated
## floor, played room by room (stories 4.7 and 4.8). Values are appended: they travel as ints.
enum Mode { ARENA, ROOM, FLOOR }

var mode: Mode = Mode.ARENA
## Scene of the room played in ROOM mode.
var room_path: String = ""
## The seed to use when seeded is true.
var seed_value: int = -1
## True: the run uses seed_value (when it is not negative) instead of drawing one.
var seeded: bool = false
## Content the profile has unlocked (story 6.7), filled by Main; empty for a typed seed. The room pool depends on it: the
## same seed gives the same floor for the same unlocks, so a typed seed ignores them and stays shareable between profiles.
## Empty at the MVP (nothing unlocks yet).
var unlocks: Array[StringName] = []


## Options from the arguments of Events.run_requested (primitive types: the bus knows no feature folder).
static func from_request(requested_mode: int, requested_seed: int, requested_seeded: bool, requested_room: String) -> RunOptions:
	var options: RunOptions = RunOptions.new()
	options.mode = Mode.ROOM if requested_mode == Mode.ROOM else (Mode.FLOOR if requested_mode == Mode.FLOOR else Mode.ARENA)
	options.seed_value = requested_seed
	options.seeded = requested_seeded
	options.room_path = requested_room
	return options
