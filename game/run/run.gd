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

@onready var _player: Player = %Player
@onready var _room_slot: Node = %RoomSlot


func _ready() -> void:
	# First, so that the end of the run is notified even when the room below fails to load (AR28).
	_player.died.connect(_on_player_died)
	var arena: Arena = ARENA_SCENE.instantiate() as Arena
	if arena == null:
		Log.error("run", "arena scene root is not an Arena")
		assert(false, "Arena scene must have an Arena root")
		return
	arena.setup(_player) # before add_child()
	_room_slot.add_child(arena)
	_player.global_position = arena.player_spawn_position()
	_player.reset_physics_interpolation() # the player does not trail from (0, 0)
	Log.info("run", "run started")


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	Log.info("run", "run ended outcome=death")
	Events.run_ended.emit(Outcome.DEATH)
