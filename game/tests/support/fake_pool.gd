class_name FakePool
extends RefCounted
## RoomInfo built by hand for the generator tests (story 4.7): no scene is read. The pool has 2 start rooms, 3 treasure,
## 3 shop, 3 nightmare and 20 combat rooms, some with a partial set of doors, some large.

const N: int = Door.Side.N
const E: int = Door.Side.E
const S: int = Door.Side.S
const W: int = Door.Side.W
const ALL_DOORS: Array[int] = [N, E, S, W]
## Door sets of the combat rooms, by index (20 entries): 12 with four doors, 8 partial.
const COMBAT_DOORS: Array = [
	[N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W],
	[N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W], [N, E, S, W],
	[N, S], [E, W], [N, E, W], [E, S, W], [N, E, S], [N, S, W], [N, E], [S, W],
]


static func make(id: String, room_type: Room.RoomType, doors: Array, size_kind: Room.SizeKind = Room.SizeKind.SCREEN) -> RoomInfo:
	var info: RoomInfo = RoomInfo.new()
	info.id = StringName(id)
	info.path = "res://fake/%s.tscn" % id
	info.room_type = room_type
	info.size_kind = size_kind
	info.doors.assign(doors)
	info.doors.sort()
	return info


## The pool, in a fixed order that is deliberately not sorted by id (the generator must not depend on it).
static func rooms() -> Array[RoomInfo]:
	var pool: Array[RoomInfo] = []
	for i: int in COMBAT_DOORS.size():
		var size_kind: Room.SizeKind = Room.SizeKind.SCREEN
		if i % 7 == 3:
			size_kind = Room.SizeKind.WIDE
		elif i % 7 == 5:
			size_kind = Room.SizeKind.TALL
		var doors: Array = COMBAT_DOORS[i]
		pool.append(make("fake_combat_%02d" % i, Room.RoomType.COMBAT, doors, size_kind))
	for i: int in 3:
		pool.append(make("fake_nightmare_%02d" % i, Room.RoomType.NIGHTMARE, ALL_DOORS))
		pool.append(make("fake_shop_%02d" % i, Room.RoomType.SHOP, ALL_DOORS))
		pool.append(make("fake_treasure_%02d" % i, Room.RoomType.TREASURE, ALL_DOORS))
	for i: int in 2:
		pool.append(make("fake_start_%02d" % i, Room.RoomType.START, ALL_DOORS))
	pool.reverse()
	return pool


## The same pool with the order of its rooms changed by a fixed rotation.
static func rooms_rotated(offset: int) -> Array[RoomInfo]:
	var pool: Array[RoomInfo] = rooms()
	var rotated: Array[RoomInfo] = []
	for i: int in pool.size():
		rotated.append(pool[(i + offset) % pool.size()])
	return rotated
