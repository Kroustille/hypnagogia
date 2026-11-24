extends GutTest
## The treasure room of a floor (story 5.2): one item drawn on the first entry, kept in the stock of the cell, the same
## for the same seed, gone once taken.

const SEED: int = 20260524
const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")

var _harness: RoomHarness
var _run: Run
var _player: Player


func before_each() -> void:
	await _begin(SEED)


func after_each() -> void:
	_harness.release()


func _begin(seed_value: int) -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_floor(seed_value)
	_run = _harness.run
	_player = _harness.player
	await _harness.ticks(2)


func _treasure_cell() -> Vector2i:
	return _run.floor_layout.cells_of_type(Room.RoomType.TREASURE)[0]


## Jumps to the room of a cell (the doors are tested elsewhere).
func _go(cell: Vector2i) -> void:
	var sides: Array[int] = _run.floor_layout.door_sides(cell)
	_player.global_position = Vector2(40, 40) # away from any pedestal: the physics server still holds the old position for a tick
	await _harness.ticks(2)
	_run._swap_room(cell, sides[0])
	await _harness.ticks(3)


func _pickup_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for pickup: Pickup in _run.current_room().pickups():
		ids.append(pickup.offer.item.id)
	return ids


func test_entering_the_treasure_room_shows_one_item_on_the_pedestal() -> void:
	await _go(_treasure_cell())
	assert_eq(_run.current_room().room_type, Room.RoomType.TREASURE)
	assert_eq(_pickup_ids().size(), 1)
	var spot: PickupSpot = _run.current_room().pickup_spots()[0]
	assert_eq(_run.current_room().pickups()[0].position, spot.position)
	assert_eq(_run.stock_of(_treasure_cell()).offers.size(), 1)


func test_two_runs_of_the_same_seed_offer_the_same_item() -> void:
	await _go(_treasure_cell())
	var first: Array[StringName] = _pickup_ids()
	_harness.release()
	await _begin(SEED)
	await _go(_treasure_cell())
	assert_eq(_pickup_ids(), first)


func test_the_draw_happens_once_and_does_not_move_the_other_streams() -> void:
	var cell: Vector2i = _treasure_cell()
	var shop_before: int = _run.rng.stream(RunRng.SHOP, 0).state
	var drops_before: int = _run.rng.stream(RunRng.DROPS, 0).state
	var combat_before: int = _run.rng.stream(RunRng.COMBAT, 0).state
	var treasure_before: int = _run.rng.stream(RunRng.TREASURE, 0).state
	await _go(cell)
	var treasure_after: int = _run.rng.stream(RunRng.TREASURE, 0).state
	assert_ne(treasure_after, treasure_before, "one draw")
	await _go(_run.floor_layout.start)
	await _go(cell)
	assert_eq(_run.rng.stream(RunRng.TREASURE, 0).state, treasure_after, "no second draw on the return")
	assert_eq(_run.rng.stream(RunRng.SHOP, 0).state, shop_before)
	assert_eq(_run.rng.stream(RunRng.DROPS, 0).state, drops_before)
	assert_eq(_run.rng.stream(RunRng.COMBAT, 0).state, combat_before)


func test_an_item_left_is_offered_again_and_an_item_taken_is_gone() -> void:
	var cell: Vector2i = _treasure_cell()
	await _go(cell)
	var offered: Array[StringName] = _pickup_ids()
	await _go(_run.floor_layout.start)
	assert_eq(_run.current_room().pickups().size(), 0, "no pedestal in the start room")
	await _go(cell)
	assert_eq(_pickup_ids(), offered, "the same offer on the return")
	var pickup: Pickup = _run.current_room().pickups()[0]
	_player.global_position = pickup.global_position
	await _harness.ticks(4)
	assert_true(_run.stock_of(cell).offers[0].taken)
	assert_eq(_player.carrier.loadout.copies_of(offered[0]), 1, "free and definitive")
	await _go(_run.floor_layout.start)
	await _go(cell)
	assert_eq(_pickup_ids().size(), 0, "nothing left on the pedestal")


func test_the_draw_leaves_out_what_the_player_holds() -> void:
	var cell: Vector2i = _treasure_cell()
	for item: ItemDef in ItemCatalog.all():
		if item.id != &"falling_tooth":
			_player.carrier.acquire(item)
	await _go(cell)
	assert_eq(_pickup_ids(), [&"falling_tooth"] as Array[StringName], "only the stackable tooth is left")


func test_an_empty_filtered_pool_leaves_the_room_without_item() -> void:
	var cell: Vector2i = _treasure_cell()
	_player.health.lose_max(4) # one heart max: no tooth
	for item: ItemDef in ItemCatalog.all():
		if item.id != &"falling_tooth":
			_player.carrier.acquire(item)
	await _go(cell)
	assert_eq(_pickup_ids().size(), 0)
	assert_eq(_run.stock_of(cell).offers.size(), 0)
