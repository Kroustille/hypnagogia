class_name Run
extends Node
## One night: the player and the active room (RoomSlot). Destroyed and recreated by Main on restart (AR20).
## Holds the run state (only "has it ended" for now). Notifies the end of the run on Events.run_ended.

## How a run ended. Values are explicit because they travel as ints on Events.run_ended:
## new outcomes are appended at the end (VICTORY: story 6.4).
enum Outcome { DEATH = 0 }

## Kept in the resource cache for the whole session: Main preloads run.tscn, which preloads this (AC 3).
const ARENA_SCENE: PackedScene = preload("res://rooms/arena/arena.tscn")

var _ended: bool = false
var _options: RunOptions = RunOptions.new()
## The random streams of this run (D8): a new one for every run.
var rng: RunRng

@onready var _player: Player = %Player
@onready var _room_slot: Node = %RoomSlot


## Dependency injection: call before add_child(). Without it the run plays the arena.
func setup(options: RunOptions) -> void:
	_options = options


func _ready() -> void:
	rng = RunRng.new(_options.seed_value if _options.seeded else RunRng.draw_seed())
	Log.info("run", "seed %s" % rng.seed_code())
	# First, so that the end of the run is notified even when the room below fails to load (AR28).
	_player.died.connect(_on_player_died)
	var room: Room = _make_room()
	if room == null:
		return
	room.setup(_player, rng) # before add_child()
	_room_slot.add_child(room)
	_player.global_position = room.player_spawn_position()
	_player.reset_physics_interpolation() # the player does not trail from (0, 0)
	Log.info("run", "run started")
	Events.run_started.emit()


## The room of the run: the arena, or the pre-drawn room of the options. Null (and an error) when it cannot load.
func _make_room() -> Room:
	var scene: PackedScene = ARENA_SCENE
	if _options.mode == RunOptions.Mode.ROOM:
		scene = load(_options.room_path) as PackedScene
		if scene == null:
			Log.error("run", "room scene %s cannot be loaded" % _options.room_path)
			assert(false, "RunOptions.room_path must be a room scene")
			return null
	var room: Room = scene.instantiate() as Room
	if room == null:
		Log.error("run", "room scene root is not a Room")
		assert(false, "A room scene must have a Room root")
	return room


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	Log.info("run", "run ended outcome=death")
	Events.run_ended.emit(Outcome.DEATH)
