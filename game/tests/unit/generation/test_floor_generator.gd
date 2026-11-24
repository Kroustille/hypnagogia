extends GutTest
## FloorGenerator (story 4.7, AC 4 to 6): invariants of every floor, determinism on 10 seeds, clean failure.

const SEEDS: Array[int] = [
	1, 42, 12345, 987654321, 31415926535, 271828182845, 0, 1099511627775, 20260101, 5555,
]
const DEF_PATH: String = "res://data/floors/onset.tres"

var _def: FloorDef


func before_each() -> void:
	_def = (load(DEF_PATH) as FloorDef).duplicate() as FloorDef # a copy: the tests change it


func _generate(seed_value: int, pool: Array[RoomInfo] = FakePool.rooms()) -> FloorLayout:
	return FloorGenerator.generate(_def, pool, RunRng.new(seed_value), 0)


func test_the_def_composition() -> void:
	assert_eq(_def.combat_rooms, 12)
	assert_eq(_def.treasure_rooms, 1)
	assert_eq(_def.shop_rooms, 1)
	assert_eq(_def.nightmare_rooms, 1)
	assert_eq(_def.min_nightmare_distance, 4)
	assert_eq(_def.total_rooms(), 16)


func test_ten_seeds_give_the_same_floor_twice() -> void:
	var signatures: Dictionary = {}
	for seed_value: int in SEEDS:
		var first: FloorLayout = _generate(seed_value)
		var second: FloorLayout = _generate(seed_value)
		assert_true(first.valid, "seed %d gives a floor" % seed_value)
		assert_eq(first.signature(), second.signature(), "seed %d: same floor from a new RunRng" % seed_value)
		assert_eq(first.attempts, second.attempts)
		signatures[first.signature()] = true
	assert_gt(signatures.size(), 1, "the 10 floors are not all the same")
	assert_eq(signatures.size(), SEEDS.size(), "and in fact all different")


func test_every_floor_respects_the_invariants() -> void:
	for seed_value: int in SEEDS:
		var layout: FloorLayout = _generate(seed_value)
		_check_invariants(layout, "seed %d" % seed_value)


func test_the_order_of_the_pool_does_not_change_the_floor() -> void:
	for seed_value: int in SEEDS:
		var reference: FloorLayout = _generate(seed_value)
		var rotated: FloorLayout = _generate(seed_value, FakePool.rooms_rotated(7))
		assert_eq(rotated.signature(), reference.signature(), "seed %d" % seed_value)


func test_reference_floors_do_not_drift() -> void:
	# Reference values: a change here means the same seed now gives another floor (shared codes would break).
	assert_eq(_generate(12345).signature().sha256_text().substr(0, 16), "65f74ff31329bc8a")
	assert_eq(_generate(42).signature().sha256_text().substr(0, 16), "9ab912cddeccd67b")
	assert_eq(_generate(12345).attempts, 1)


func test_the_shape_does_not_depend_on_the_pool() -> void:
	# Layout and rooms use two streams: a smaller pool changes the rooms, not the shape (while the constraints hold).
	var small: Array[RoomInfo] = []
	for info: RoomInfo in FakePool.rooms():
		if info.room_type != Room.RoomType.COMBAT or String(info.id).to_int() < 14:
			small.append(info)
	var compared: int = 0
	for seed_value: int in SEEDS:
		var full: FloorLayout = _generate(seed_value)
		var reduced: FloorLayout = _generate(seed_value, small)
		if reduced.valid and full.attempts == 1 and reduced.attempts == 1:
			compared += 1
			assert_eq(reduced.to_text(), full.to_text(), "seed %d: same shape" % seed_value)
	assert_gte(compared, 5, "most seeds were compared")


func test_another_floor_index_gives_another_floor() -> void:
	var first: FloorLayout = FloorGenerator.generate(_def, FakePool.rooms(), RunRng.new(777), 0)
	var second: FloorLayout = FloorGenerator.generate(_def, FakePool.rooms(), RunRng.new(777), 1)
	assert_ne(first.signature(), second.signature())
	assert_eq(second.floor_index, 1)


func test_a_pool_without_enough_combat_rooms_fails_cleanly() -> void:
	var poor: Array[RoomInfo] = []
	for info: RoomInfo in FakePool.rooms():
		if info.room_type != Room.RoomType.COMBAT or String(info.id).ends_with("0"):
			poor.append(info)
	_def.max_attempts = 5
	var layout: FloorLayout = _generate(1, poor)
	assert_false(layout.valid)
	assert_eq(layout.attempts, 5, "it tried the allowed number of times and stopped")
	assert_false(layout.failure.is_empty())
	assert_eq(layout.signature(), "invalid")


func test_a_pool_without_a_nightmare_room_fails_cleanly() -> void:
	var pool: Array[RoomInfo] = []
	for info: RoomInfo in FakePool.rooms():
		if info.room_type != Room.RoomType.NIGHTMARE:
			pool.append(info)
	_def.max_attempts = 3
	assert_false(_generate(5, pool).valid)


func test_a_grid_too_small_fails_cleanly() -> void:
	_def.grid_width = 3
	_def.grid_height = 3
	_def.max_attempts = 4
	var layout: FloorLayout = _generate(9)
	assert_false(layout.valid)
	assert_eq(layout.attempts, 4)


func test_a_failed_attempt_is_drawn_again() -> void:
	# A far nightmare room (6 connections) is rarely met by the first shape: the layout is drawn again until it is.
	_def.max_attempts = 5000
	_def.combat_rooms = 9
	_def.min_nightmare_distance = 6
	var layout: FloorLayout = _generate(3)
	assert_true(layout.valid, layout.failure)
	assert_gt(layout.attempts, 1, "the first draw does not meet the distance")
	for cell: Vector2i in layout.cells_of_type(Room.RoomType.NIGHTMARE):
		assert_gte(layout.distance(layout.start, cell), 6)


func test_loops_appear_when_the_chance_is_one() -> void:
	_def.loop_chance = 1.0
	var layout: FloorLayout = _generate(12345)
	assert_true(layout.valid)
	var tree_edges: int = layout.cells.size() - 1
	assert_gt(layout.edges().size(), tree_edges, "more edges than a tree has")
	_def.loop_chance = 0.0
	var tree: FloorLayout = _generate(12345)
	assert_eq(tree.edges().size(), tree.cells.size() - 1, "no loop: a tree")


func test_a_floor_is_never_generated_twice_on_one_rng() -> void:
	# The streams keep their state: a second generation on the same RunRng continues the sequence.
	var rng: RunRng = RunRng.new(2024)
	var first: FloorLayout = FloorGenerator.generate(_def, FakePool.rooms(), rng, 0)
	var second: FloorLayout = FloorGenerator.generate(_def, FakePool.rooms(), rng, 0)
	assert_ne(first.signature(), second.signature())


func _check_invariants(layout: FloorLayout, label: String) -> void:
	assert_true(layout.valid, "%s is valid" % label)
	assert_eq(layout.cells.size(), _def.total_rooms(), "%s: 16 rooms" % label)
	var counts: Dictionary = {}
	var ids: Dictionary = {}
	for cell: Vector2i in layout.cells:
		var placement: FloorLayout.Placement = layout.cells[cell]
		counts[placement.room_type] = _count(counts, placement.room_type) + 1
		assert_not_null(placement.info, "%s: a room at %s" % [label, cell])
		assert_eq(placement.info.room_type, placement.room_type, "%s: room of the cell type" % label)
		assert_false(ids.has(placement.info.id), "%s: %s used once" % [label, placement.info.id])
		ids[placement.info.id] = true
		assert_true(Rect2i(0, 0, _def.grid_width, _def.grid_height).has_point(cell), "%s: inside the grid" % label)
		for side: int in layout.door_sides(cell):
			assert_true(placement.info.doors.has(side), "%s: %s has the door %d it needs" % [label, placement.info.id, side])
		for neighbor: Vector2i in layout.neighbors(cell):
			assert_eq((cell - neighbor).abs().x + (cell - neighbor).abs().y, 1, "%s: edges join adjacent cells" % label)
			var back: int = FloorLayout.side_towards(neighbor, cell)
			assert_true(layout.cells[neighbor].info.doors.has(back), "%s: the other room has the facing door" % label)
	assert_eq(_count(counts, Room.RoomType.START), 1, label)
	assert_eq(_count(counts, Room.RoomType.COMBAT), 12, label)
	assert_eq(_count(counts, Room.RoomType.TREASURE), 1, label)
	assert_eq(_count(counts, Room.RoomType.SHOP), 1, label)
	assert_eq(_count(counts, Room.RoomType.NIGHTMARE), 1, label)
	var depths: Dictionary[Vector2i, int] = layout.depths_from(layout.start)
	assert_eq(depths.size(), layout.cells.size(), "%s: every room is reachable from the start" % label)
	for room_type: Room.RoomType in [Room.RoomType.TREASURE, Room.RoomType.SHOP, Room.RoomType.NIGHTMARE]:
		for cell: Vector2i in layout.cells_of_type(room_type):
			assert_eq(layout.neighbors(cell).size(), 1, "%s: the %s room is a dead end" % [label, Room.RoomType.find_key(room_type)])
	for cell: Vector2i in layout.cells_of_type(Room.RoomType.NIGHTMARE):
		assert_gte(layout.distance(layout.start, cell), _def.min_nightmare_distance, "%s: nightmare far from the start" % label)


func _count(counts: Dictionary, room_type: Room.RoomType) -> int:
	var count: int = counts.get(room_type, 0)
	return count
