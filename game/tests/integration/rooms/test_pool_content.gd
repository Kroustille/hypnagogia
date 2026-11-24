extends GutTest
## The content of the real Onset pool (story 4.10, AC 1 to 7): quotas that make two runs differ. The numbers are the
## story's decisions (see its "Décisions prises sans Kroustille"); the shape rules themselves belong to RoomValidator.

const POOL_DIR: String = "res://rooms/pool/onset"
## Pit cells that make a room "full of holes" (a chasm band, a lake, several islands).
const MANY_PIT_CELLS: int = 40
const ENEMY_IDS: Array[StringName] = [&"sleepwalker", &"night_light", &"lullaby", &"sheep"]
const SHOOTERS: Array[StringName] = [&"night_light", &"lullaby"]

## What the quotas read of one combat room.
class RoomStats extends RefCounted:
	var id: StringName = &""
	var size: Room.SizeKind = Room.SizeKind.SCREEN
	var doors: int = 0
	var pits: int = 0
	var high: int = 0
	var low: int = 0
	var furniture: int = 0
	var lamps: int = 0
	## Wave number -> enemy ids (Array[StringName]).
	var waves: Dictionary[int, Array] = {}
	var reinforcements: int = 0
	var far_reinforcement: bool = false

	func types() -> Array[StringName]:
		var found: Array[StringName] = []
		for wave: int in waves:
			for id_value: StringName in waves[wave]:
				if not found.has(id_value):
					found.append(id_value)
		return found


static var _stats: Array[RoomStats] = []


func before_all() -> void:
	if not _stats.is_empty():
		return
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		if info.room_type == Room.RoomType.COMBAT:
			_stats.append(_read(info))


func _read(info: RoomInfo) -> RoomStats:
	var room: Room = (load(info.path) as PackedScene).instantiate() as Room
	var waves: Dictionary[int, Array] = {}
	for spawn: EnemySpawn in room.enemy_spawns():
		var ids: Array = waves.get(spawn.wave, [])
		ids.append(spawn.enemy.id)
		waves[spawn.wave] = ids
	var reinforcements: Array[Vector2] = []
	for marker: Node in room.get_node("ReinforcementSpawns").get_children():
		reinforcements.append((marker as Node2D).position)
	var door_centers: Array[Vector2] = []
	for door: Door in room.doors():
		door_centers.append(door.position)
	var far: bool = false
	for point: Vector2 in reinforcements:
		var nearest: float = INF
		for center: Vector2 in door_centers:
			nearest = minf(nearest, point.distance_to(center))
		far = far or nearest > 6.0 * Const.TILE_SIZE
	var stats: RoomStats = RoomStats.new()
	stats.id = info.id
	stats.size = info.size_kind
	stats.doors = info.doors.size()
	stats.pits = (room.get_node("Pits") as TileMapLayer).get_used_cells().size()
	stats.high = (room.get_node("HighObstacles") as TileMapLayer).get_used_cells().size()
	stats.low = (room.get_node("LowObstacles") as TileMapLayer).get_used_cells().size()
	stats.furniture = room.furnitures().size()
	stats.lamps = room.triggers().size()
	stats.waves = waves
	stats.reinforcements = reinforcements.size()
	stats.far_reinforcement = far
	room.free()
	return stats


func _count_where(predicate: Callable) -> int:
	var count: int = 0
	for room: RoomStats in _stats:
		if predicate.call(room):
			count += 1
	return count


func test_there_are_at_least_thirty_combat_rooms_numbered_without_a_gap() -> void:
	assert_gte(_stats.size(), 30)
	for i: int in _stats.size():
		assert_eq(String(_stats[i].id), "onset_combat_%03d" % (i + 1), "room %d" % (i + 1))
	var other: Dictionary = {}
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		other[info.room_type] = true
	for room_type: Room.RoomType in [Room.RoomType.START, Room.RoomType.TREASURE, Room.RoomType.SHOP, Room.RoomType.NIGHTMARE]:
		assert_true(other.has(room_type), "a %s room remains" % Room.RoomType.find_key(room_type))


func test_most_rooms_have_holes_and_several_are_full_of_them() -> void:
	var with_holes: int = _count_where(func(r: RoomStats) -> bool: return r.pits > 0)
	assert_gte(with_holes * 100, _stats.size() * 70, "at least 70 percent of the rooms have pits (%d of %d)" % [with_holes, _stats.size()])
	var many: int = _count_where(func(r: RoomStats) -> bool: return r.pits >= MANY_PIT_CELLS)
	assert_gte(many, 6, "at least 6 rooms with %d pit cells or more" % MANY_PIT_CELLS)


func test_every_enemy_appears_in_ten_rooms_and_eight_rooms_mix_three_types() -> void:
	for id: StringName in ENEMY_IDS:
		var count: int = _count_where(func(r: RoomStats) -> bool: return r.types().has(id))
		assert_gte(count, 10, "%s is in at least 10 rooms (%d)" % [id, count])
	var mixed: int = _count_where(func(r: RoomStats) -> bool: return r.types().size() >= 3)
	assert_gte(mixed, 8, "at least 8 rooms combine three types or more (%d)" % mixed)


func test_waves_follow_the_difficulty_rules() -> void:
	var single: int = 0
	for room: RoomStats in _stats:
		var label: String = String(room.id)
		assert_between(room.waves.size(), 1, 3, "%s: 1 to 3 waves" % label)
		if room.waves.size() == 1:
			single += 1
		for wave: int in room.waves:
			assert_lt(wave, room.waves.size(), "%s: waves are numbered from 0 without a gap" % label)
			var ids: Array = room.waves[wave]
			assert_between(ids.size(), 2, mini(6, WaveRunner.MAX_WAVE_ENEMIES), "%s wave %d: 2 to 6 enemies" % [label, wave])
			assert_lte(ids.count(&"sheep"), 2, "%s wave %d: at most 2 sheep" % [label, wave])
			assert_lte(_shooters(ids), 4, "%s wave %d: at most 4 shooters" % [label, wave])
		var first: Array = room.waves[0]
		assert_eq(first.count(&"sheep"), 0, "%s: no sheep in the first wave" % label)
		assert_lte(_shooters(first), 2, "%s: at most 2 shooters in the first wave" % label)
	assert_lte(single, 5, "only a few warm-up rooms have a single wave")


func _shooters(ids: Array) -> int:
	var count: int = 0
	for shooter: StringName in SHOOTERS:
		count += ids.count(shooter)
	return count


func test_large_rooms_and_room_elements() -> void:
	var wide: int = _count_where(func(r: RoomStats) -> bool: return r.size == Room.SizeKind.WIDE)
	var tall: int = _count_where(func(r: RoomStats) -> bool: return r.size == Room.SizeKind.TALL)
	assert_gte(wide, 3, "wide rooms")
	assert_gte(tall, 2, "tall rooms")
	var large_with_pits: int = _count_where(func(r: RoomStats) -> bool: return r.size != Room.SizeKind.SCREEN and r.pits > 0)
	var large_with_furniture: int = _count_where(func(r: RoomStats) -> bool: return r.size != Room.SizeKind.SCREEN and r.furniture > 0)
	assert_gte(large_with_pits, 1, "a large room with pits")
	assert_gte(large_with_furniture, 1, "a large room with furniture")
	assert_gte(_count_where(func(r: RoomStats) -> bool: return r.furniture > 0), 6, "rooms with furniture")
	assert_gte(_count_where(func(r: RoomStats) -> bool: return r.lamps > 0), 3, "rooms with a lamp")
	var obstacles: int = _count_where(func(r: RoomStats) -> bool: return r.high > 0 or r.low > 0)
	assert_gte(obstacles, 15, "rooms with high or low obstacles (%d)" % obstacles)
	var both: int = _count_where(func(r: RoomStats) -> bool: return r.high > 0 and r.low > 0)
	assert_gte(both, 4, "rooms with both kinds (%d)" % both)


func test_reinforcements_and_doors() -> void:
	var four_doors: int = 0
	for room: RoomStats in _stats:
		var label: String = String(room.id)
		assert_gte(room.reinforcements, 2, "%s: at least 2 reinforcement markers" % label)
		assert_true(room.far_reinforcement, "%s: one reinforcement more than 6 tiles from every door" % label)
		assert_gte(room.doors, 2, "%s: at least two doors" % label)
		if room.doors == 4:
			four_doors += 1
	assert_gte(four_doors * 100, _stats.size() * 90, "at least 90 percent of the rooms declare four doors (%d of %d)" % [four_doors, _stats.size()])


func test_every_room_passes_the_validator() -> void:
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		assert_eq(RoomValidator.validate(load(info.path) as PackedScene), PackedStringArray(), info.id)
