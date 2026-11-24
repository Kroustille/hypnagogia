extends GutTest
## Saving at the entry of a room and resuming (story 6.8): the run comes back as it was when the room was entered, and the
## room draws the same things again.

const SEED: int = 4242


## What a room looked like on the first entry.
class Seen extends RefCounted:
	var before_health: Dictionary = {}
	var before_lucidity: int = 0
	var before_rng: Dictionary = {}
	var before_shards: int = 0
	var cell: Vector2i = Vector2i.ZERO
	var stocks: String = ""
	var rng: Dictionary = {}
	var enemies: String = ""
	var items: String = ""
	var layout: String = ""
	var visited: int = 0


var _dir: SaveDir
var _harness: RoomHarness


func before_each() -> void:
	_dir = SaveDir.new()
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()
	RoomLoader.collect_orphans(true)
	_dir.restore()


## The cells from the start to the first cell of this type (breadth first), the start excluded.
func _path_to(layout: FloorLayout, room_type: Room.RoomType) -> Array[Vector2i]:
	var came_from: Dictionary[Vector2i, Vector2i] = {layout.start: layout.start}
	var queue: Array[Vector2i] = [layout.start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		if cell != layout.start and layout.cells[cell].room_type == room_type:
			var path: Array[Vector2i] = []
			var step: Vector2i = cell
			while step != layout.start:
				path.push_front(step)
				step = came_from[step]
			return path
		for neighbor: Vector2i in layout.neighbors(cell):
			if not came_from.has(neighbor):
				came_from[neighbor] = cell
				queue.append(neighbor)
	return []


## Walks the doors along the path, then returns what the run looked like just before the last step.
func _walk(path: Array[Vector2i], seen: Seen) -> void:
	var run: Run = _harness.run
	var player: Player = _harness.player
	for cell: Vector2i in path:
		seen.before_health = player.health.export_state()
		seen.before_lucidity = player.lucidity.value
		seen.before_rng = run.rng.export_states()
		seen.before_shards = run.state.shards
		var side: int = FloorLayout.SIDE_STEPS.find(cell - run.current_cell())
		run.travel(side) # no transition node in the harness: the swap is immediate


func _give_a_build(player: Player, run: Run) -> void:
	player.carrier.acquire(ItemCatalog.by_id(&"falling_tooth"))
	player.carrier.acquire(ItemCatalog.by_id(&"broken_alarm"))
	player.carrier.loadout.set_charge(1)
	player.carrier.acquire_consumable(ConsumableCatalog.by_id(&"coffee"))
	player.health.add_armor(2)
	player.health.lose_half_hearts_unarmored(1)
	player.lucidity.set_value(40)
	run.add_shards(7)


func _first_entry_of(room_type: Room.RoomType) -> Seen:
	_harness.start_floor(SEED)
	var run: Run = _harness.run
	var player: Player = _harness.player
	_give_a_build(player, run)
	var path: Array[Vector2i] = _path_to(run.floor_layout, room_type)
	assert_false(path.is_empty(), "the floor has a room of this type")
	var seen: Seen = Seen.new()
	_walk(path, seen)
	if room_type == Room.RoomType.COMBAT:
		await _harness.until(func() -> bool: return not _harness.living_enemies().is_empty(), 600)
		await _harness.ticks(10)
	else:
		await _harness.ticks(30)
	seen.cell = run.current_cell()
	seen.stocks = _stocks_text(run)
	seen.rng = run.rng.export_states()
	seen.enemies = _enemies_text()
	seen.items = _items_text(player)
	seen.layout = run.floor_layout.to_text()
	seen.visited = run.floor_map.visited.size()
	return seen


func _stocks_text(run: Run) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var cells: Array[Vector2i] = run.stocks.keys()
	cells.sort()
	for cell: Vector2i in cells:
		parts.append("%s=%s" % [cell, JSON.stringify(run.stocks[cell].to_dict(), "", true)])
	return "|".join(parts)


func _enemies_text() -> String:
	var parts: PackedStringArray = PackedStringArray()
	for enemy: Enemy in _harness.living_enemies():
		parts.append("%s@%s" % [enemy.name, enemy.global_position])
	return ",".join(parts)


func _items_text(player: Player) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for owned: OwnedItem in player.carrier.loadout.items():
		parts.append("%s:%d:%d" % [owned.def.id, owned.max_half_hearts_paid, owned.charge])
	var consumable: ConsumableDef = player.carrier.loadout.consumable
	parts.append("consumable=%s" % (consumable.id if consumable != null else &""))
	return ",".join(parts)


func test_the_saved_night_is_the_state_at_the_entry_of_the_room() -> void:
	var first: Seen = await _first_entry_of(Room.RoomType.COMBAT)
	var snapshot: RunSnapshot = SaveService.read_run() # through the file: JSON text and back
	assert_not_null(snapshot)
	assert_eq(snapshot.cell, first.cell)
	assert_eq(snapshot.health, first.before_health)
	assert_eq(snapshot.lucidity, first.before_lucidity)
	assert_eq(snapshot.state.shards, first.before_shards)
	assert_eq(snapshot.rng_states, first.before_rng, "the 64 bit states are the ones the run had, decimal text and all")
	assert_eq(snapshot.items.size(), 2)
	assert_eq(snapshot.consumable, &"coffee")


func test_a_resumed_combat_room_replays_the_same_room() -> void:
	var first: Seen = await _first_entry_of(Room.RoomType.COMBAT)
	var player: Player = _harness.player
	var snapshot: RunSnapshot = SaveService.read_run()
	_harness.release()
	RoomLoader.collect_orphans(true)
	_harness = RoomHarness.new()
	add_child(_harness)
	SaveService.delete_run() # what Main does when the player resumes
	_harness.start_resume(snapshot)
	await _harness.until(func() -> bool: return not _harness.living_enemies().is_empty(), 600)
	await _harness.ticks(10)
	var run: Run = _harness.run
	var resumed: Player = _harness.player
	assert_ne(resumed, player)
	assert_eq(run.floor_layout.to_text(), first.layout, "the same plan")
	assert_eq(run.current_cell(), first.cell)
	assert_eq(resumed.health.export_state(), first.before_health)
	assert_eq(resumed.lucidity.value, 40)
	assert_eq(run.state.shards, 7)
	assert_eq(_items_text(resumed), first.items, "items, their cost in hearts, the charge, the consumable")
	assert_eq(_stocks_text(run), first.stocks)
	assert_eq(run.floor_map.visited.keys().size(), first.visited)
	assert_eq(run.rng.export_states(), first.rng, "the room drew the same numbers again")
	assert_ne(first.enemies, "", "there are enemies to compare")
	assert_eq(_enemies_text(), first.enemies, "the same enemies at the same places")
	assert_true(SaveService.has_run(), "written again at the entry of the room")


func test_a_resumed_treasure_room_offers_the_same_item() -> void:
	var first: Seen = await _first_entry_of(Room.RoomType.TREASURE)
	var snapshot: RunSnapshot = SaveService.read_run()
	assert_false(snapshot.stocks.has(snapshot.cell), "saved before the draw of the room")
	var drawn: String = first.stocks
	_harness.release()
	RoomLoader.collect_orphans(true)
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_resume(snapshot)
	assert_eq(_stocks_text(_harness.run), drawn)
	assert_eq(_harness.run.rng.export_states(), first.rng)


func test_an_item_that_no_longer_exists_is_skipped() -> void:
	await _first_entry_of(Room.RoomType.COMBAT)
	var snapshot: RunSnapshot = SaveService.read_run()
	snapshot.items.append({"id": "removed_in_a_later_version", "paid": 0, "charge": -1})
	_harness.release()
	RoomLoader.collect_orphans(true)
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_resume(snapshot)
	assert_eq(_harness.player.carrier.loadout.count(), 2)
	assert_eq(_harness.run.current_cell(), snapshot.cell)
