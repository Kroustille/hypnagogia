extends GutTest
## The floor generator on the real Onset pool (story 4.10, AC 8): floors differ from one seed to the next.

const SEEDS: Array[int] = [
	1, 42, 12345, 987654321, 31415926535, 271828182845, 0, 1099511627775, 20260101, 5555,
]
const DEF_PATH: String = "res://data/floors/onset.tres"

static var _pool: Array[RoomInfo] = []

var _def: FloorDef


func before_all() -> void:
	if _pool.is_empty():
		_pool = RoomCatalog.pool((load(DEF_PATH) as FloorDef).pool_dir)


func before_each() -> void:
	_def = load(DEF_PATH) as FloorDef


func _combat_ids(layout: FloorLayout) -> Array[StringName]:
	var ids: Array[StringName] = []
	for cell: Vector2i in layout.cells_of_type(Room.RoomType.COMBAT):
		ids.append(layout.cells[cell].info.id)
	ids.sort()
	return ids


func test_the_catalog_holds_at_least_thirty_combat_rooms() -> void:
	var count: int = 0
	for info: RoomInfo in _pool:
		if info.room_type == Room.RoomType.COMBAT:
			count += 1
	assert_gte(count, 30)


func test_ten_seeds_draw_different_rooms_on_the_real_pool() -> void:
	var sets: Dictionary = {}
	var distinct: Dictionary = {}
	for seed_value: int in SEEDS:
		var layout: FloorLayout = FloorGenerator.generate(_def, _pool, RunRng.new(seed_value), 0)
		assert_true(layout.valid, "seed %d: %s" % [seed_value, layout.failure])
		var ids: Array[StringName] = _combat_ids(layout)
		assert_eq(ids.size(), _def.combat_rooms, "seed %d: 12 combat rooms" % seed_value)
		var key: String = ",".join(PackedStringArray(ids))
		assert_false(sets.has(key), "seed %d draws a set of rooms no earlier seed drew" % seed_value)
		sets[key] = seed_value
		for id: StringName in ids:
			distinct[id] = true
		_check_invariants(layout, "seed %d" % seed_value)
	assert_gte(distinct.size(), 20, "at least 20 distinct combat rooms over the 10 floors (%d)" % distinct.size())


func _check_invariants(layout: FloorLayout, label: String) -> void:
	var seen: Dictionary = {}
	for cell: Vector2i in layout.cells:
		var placement: FloorLayout.Placement = layout.cells[cell]
		assert_false(seen.has(placement.info.id), "%s: %s used once" % [label, placement.info.id])
		seen[placement.info.id] = true
		assert_eq(placement.info.room_type, placement.room_type, "%s: room of the cell type" % label)
		for side: int in layout.door_sides(cell):
			assert_true(placement.info.doors.has(side), "%s: %s has the door it needs" % [label, placement.info.id])
	assert_eq(layout.cells.size(), _def.total_rooms(), "%s: 16 rooms" % label)
	assert_eq(layout.depths_from(layout.start).size(), layout.cells.size(), "%s: every room is reachable" % label)
	for cell: Vector2i in layout.cells_of_type(Room.RoomType.NIGHTMARE):
		assert_gte(layout.distance(layout.start, cell), _def.min_nightmare_distance, "%s: nightmare far from the start" % label)
		assert_eq(layout.neighbors(cell).size(), 1, "%s: the nightmare room is a dead end" % label)
	for room_type: Room.RoomType in [Room.RoomType.TREASURE, Room.RoomType.SHOP]:
		for cell: Vector2i in layout.cells_of_type(room_type):
			assert_eq(layout.neighbors(cell).size(), 1, "%s: a dead end" % label)
