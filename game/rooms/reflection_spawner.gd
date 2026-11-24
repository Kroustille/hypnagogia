class_name ReflectionSpawner
extends RefCounted
## Decides and makes the apparition of the hostile reflection of the Mirror in a room (story 5.10). One per room, listening
## to Room.fight_started. The draw is ONE call of the "combat" stream per eligible room (a combat room that is not a
## nightmare, not cleared, with the Mirror carried), whatever the result: the stream is shared with the reinforcement
## of the Abandon tier, so a draw that depended on anything else would make two players of one seed diverge.

const REFLECTION_DEF: EnemyDef = preload("res://data/enemies/reflection.tres")
const MIRROR_ID: StringName = &"mirror"
## The reflection appears in one eligible room out of this many, on average.
const ONE_ROOM_IN: int = 4

var _room: Room
var _player: Player
var _rng: RunRng
var _floor_index: int = 0


func _init(room: Room, player: Player, rng: RunRng, floor_index: int) -> void:
	_room = room
	_player = player
	_rng = rng
	_floor_index = floor_index


## Whether the draw is made in this room: the Mirror is carried in a combat room that is not a nightmare nor already won.
func is_eligible() -> bool:
	return (
			_room.room_type == Room.RoomType.COMBAT and not _room.is_nightmare() and not _room.is_cleared()
			and _player.carrier != null and _player.carrier.loadout.copies_of(MIRROR_ID) > 0)


## The draw of this room: false without any draw when the room is not eligible, else exactly one call of the combat stream.
func draw() -> bool:
	if not is_eligible():
		return false
	return _rng.stream(RunRng.COMBAT, _floor_index).randi_range(0, ONE_ROOM_IN - 1) == 0


## The first wave is about to appear. Draws, and when it is a hit the reflection appears at the end of the frame: this
## signal comes from inside the wave runner's own logic, nothing is spawned from here.
func on_fight_started() -> void:
	if not is_eligible():
		return
	var hit: bool = draw()
	Log.info("room", "mirror draw: reflection %s" % ("appears" if hit else "stays away"))
	if hit:
		_appear.call_deferred()


func _appear() -> void:
	if not is_instance_valid(_room) or not _room.is_inside_tree() or _room.is_cleared() or _player.health.is_dead():
		return
	spawn()


## Makes the reflection now, without any draw (the draw is on_fight_started(); the debug key uses this). Null when the
## room refuses it.
func spawn() -> Enemy:
	var center: Vector2 = _room.to_global(_room.frame_px() / 2.0)
	var requested: Vector2 = _room.to_local(center * 2.0 - _player.global_position) # opposite the player
	var defs: Array[ItemDef] = _player.carrier.loadout.copy_defs()
	var factor: float = _room.hp_factor()
	var prepare: Callable = func(enemy: Enemy) -> void:
		var reflection: Reflection = enemy as Reflection
		if reflection != null:
			reflection.give_build(defs, factor, center)
	return _room.spawn_enemy(REFLECTION_DEF, requested, prepare)
