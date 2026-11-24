extends GutTest
## Same seed, same unlocks: same floor and same objects (story 6.9, AC 4; GDD technical indicator, checked on 10 seeds).
## Two runs per seed: the plan of the floor, the offers of the treasure room and of the shop at the first visit, and the
## enemies met in the rooms on the way there.

const SEEDS: Array[int] = [1, 42, 777, 20260524, 13579, 99999, 314159, 271828, 8675309, 4242424]
const WAVE_TICKS: int = 400

var _harness: RoomHarness


class Shown extends RefCounted:
	var plan: String = ""
	var stocks: Dictionary[String, String] = {}
	var enemies: Dictionary[String, PackedStringArray] = {}



func after_each() -> void:
	if _harness != null:
		_harness.release()
		_harness = null


## Plays a run on the seed and describes what it shows: plan, then for the treasure room and the shop the offers, and the
## enemies of every combat room crossed to get there.
func _describe(seed_value: int) -> Shown:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_floor(seed_value)
	var run: Run = _harness.run
	var layout: FloorLayout = run.floor_layout
	var result: Shown = Shown.new()
	result.plan = layout.to_text()
	var targets: Array[Vector2i] = layout.cells_of_type(Room.RoomType.TREASURE) + layout.cells_of_type(Room.RoomType.SHOP)
	for target: Vector2i in targets:
		for step: Vector2i in _path(layout, run.current_cell(), target):
			await _walk_to(run, step, result)
	for target: Vector2i in targets:
		result.stocks[str(target)] = JSON.stringify(run.stock_of(target).to_dict())
	_harness.release()
	_harness = null
	return result


## The cells to cross, the origin excluded, the target included (shortest way, the neighbours in a fixed order).
func _path(layout: FloorLayout, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty() and not came_from.has(to):
		var cell: Vector2i = queue.pop_front()
		for neighbor: Vector2i in layout.neighbors(cell):
			if not came_from.has(neighbor):
				came_from[neighbor] = cell
				queue.append(neighbor)
	var steps: Array[Vector2i] = []
	var cursor: Vector2i = to
	while cursor != from:
		steps.push_front(cursor)
		cursor = came_from[cursor]
	return steps


func _walk_to(run: Run, cell: Vector2i, result: Shown) -> void:
	run.travel(FloorLayout.side_towards(run.current_cell(), cell)) # no Transition in the harness: the trip is immediate
	assert_eq(run.current_cell(), cell)
	if run.current_room().room_type != Room.RoomType.COMBAT:
		return
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS)
	result.enemies[str(cell)] = _harness.living_names()


func test_ten_seeds_give_the_same_floor_and_the_same_objects_twice() -> void:
	for seed_value: int in SEEDS:
		var first: Shown = await _describe(seed_value)
		var second: Shown = await _describe(seed_value)
		assert_eq(first.plan, second.plan, "plan of seed %d" % seed_value)
		assert_eq(first.stocks, second.stocks, "treasure and shop of seed %d" % seed_value)
		assert_eq(first.enemies, second.enemies, "enemies of seed %d" % seed_value)
		assert_gt(first.stocks.size(), 0, "seed %d has a treasure room or a shop" % seed_value)
		assert_gt(first.enemies.size(), 0, "seed %d: a fight lies on the way" % seed_value)


func test_two_seeds_do_not_give_the_same_floor() -> void:
	var first: Shown = await _describe(SEEDS[0])
	var second: Shown = await _describe(SEEDS[1])
	assert_ne(first.plan, second.plan)
