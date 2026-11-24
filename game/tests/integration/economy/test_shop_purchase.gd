extends GutTest
## Buying in the shop of a floor (story 5.5): the stalls are drawn once, paid on contact, refused without effect.

const SEED: int = 20260524
const REFUSED: AudioStream = preload("res://audio/sfx/sfx_power_refused.wav")

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


func _shop_cell() -> Vector2i:
	return _run.floor_layout.cells_of_type(Room.RoomType.SHOP)[0]


func _go(cell: Vector2i) -> void:
	var sides: Array[int] = _run.floor_layout.door_sides(cell)
	_player.global_position = Vector2(40, 40) # away from any stall
	await _harness.ticks(2)
	_run._swap_room(cell, sides[0])
	await _harness.ticks(3)


func _stall(kind: RoomStock.Kind) -> Pickup:
	for pickup: Pickup in _run.current_room().pickups():
		if pickup.offer.kind == kind:
			return pickup
	return null


func _stand_on(pickup: Pickup, ticks: int = 4) -> void:
	_player.global_position = pickup.global_position
	await _harness.ticks(ticks)


func _step_off() -> void:
	_player.global_position = Vector2(40, 40)
	await _harness.ticks(6)


func _ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for pickup: Pickup in _run.current_room().pickups():
		ids.append(pickup.offer.id())
	return ids


func test_the_shop_shows_five_stalls_on_the_spots_with_a_price_label() -> void:
	await _go(_shop_cell())
	var room: Room = _run.current_room()
	assert_eq(room.pickups().size(), 5)
	var tuning: EconomyTuning = Tuning.ECONOMY
	var prices: Array[int] = []
	var spots: Dictionary = {}
	for spot: PickupSpot in room.pickup_spots():
		spots[spot.position] = spot.slot
	for pickup: Pickup in room.pickups():
		prices.append(pickup.offer.price)
		assert_true(spots.has(pickup.position), "on a spot")
		var label: Label = pickup.get_node("Price") as Label
		assert_eq(label.text, tr("UI_SHOP_PRICE") % pickup.offer.price)
		assert_gt(label.position.y, 0.0, "under the article")
	prices.sort()
	var expected: Array[int] = [tuning.consumable_price, tuning.heart_price, tuning.armor_price, tuning.item_price, tuning.item_price]
	expected.sort()
	assert_eq(prices, expected)


func test_the_stalls_are_drawn_once_and_the_same_for_the_same_seed() -> void:
	var cell: Vector2i = _shop_cell()
	var before: int = _run.rng.stream(RunRng.SHOP, 0).state
	await _go(cell)
	var first: Array[StringName] = _ids()
	var after: int = _run.rng.stream(RunRng.SHOP, 0).state
	assert_ne(after, before)
	await _go(_run.floor_layout.start)
	await _go(cell)
	assert_eq(_ids(), first)
	assert_eq(_run.rng.stream(RunRng.SHOP, 0).state, after, "no second draw")
	_harness.release()
	await _begin(SEED)
	await _go(cell)
	assert_eq(_ids(), first, "same seed, same stalls")


func test_buying_an_item_pays_and_gives_it_and_the_stall_is_gone_on_return() -> void:
	var cell: Vector2i = _shop_cell()
	await _go(cell)
	_run.add_shards(20)
	var stall: Pickup = _stall(RoomStock.Kind.ITEM)
	var offer: RoomStock.Offer = stall.offer
	var id: StringName = offer.item.id
	await _stand_on(stall)
	assert_eq(_run.state.shards, 5)
	assert_eq(_player.carrier.loadout.copies_of(id), 1)
	assert_true(offer.taken)
	assert_eq(_run.current_room().pickups().size(), 4)
	await _go(_run.floor_layout.start)
	await _go(cell)
	assert_eq(_run.current_room().pickups().size(), 4, "the others are still there")
	assert_false(_ids().has(id), "the bought item is not offered again")
	assert_eq(_run.stock_of(cell).remaining().size(), 4)


func test_not_enough_shards_refuses_once_and_takes_nothing() -> void:
	await _go(_shop_cell())
	_run.add_shards(Tuning.ECONOMY.item_price - 1)
	var stall: Pickup = _stall(RoomStock.Kind.ITEM)
	var offer: RoomStock.Offer = stall.offer
	await _stand_on(stall)
	assert_eq(_run.state.shards, Tuning.ECONOMY.item_price - 1)
	assert_eq(_player.carrier.loadout.count(), 0)
	assert_false(offer.taken)
	assert_true(Audio.voices_of(REFUSED) > 0, "refusal sound")
	assert_false(stall.is_available(), "disarmed until the player steps off")
	await _harness.ticks(10)
	assert_eq(_run.state.shards, Tuning.ECONOMY.item_price - 1, "no second try while standing there")
	_run.add_shards(1)
	await _harness.ticks(4)
	assert_false(offer.taken, "still disarmed: a new try needs a step off")
	await _step_off()
	await _stand_on(stall)
	assert_true(offer.taken, "bought on the second visit to the zone")
	assert_eq(_run.state.shards, 0)


func test_a_heart_at_full_health_is_refused_without_spending() -> void:
	await _go(_shop_cell())
	_run.add_shards(10)
	var stall: Pickup = _stall(RoomStock.Kind.HEART)
	var offer: RoomStock.Offer = stall.offer
	await _stand_on(stall)
	assert_eq(_run.state.shards, 10)
	assert_false(offer.taken)
	_player.health.half_hearts -= 2
	await _step_off()
	await _stand_on(stall)
	assert_true(offer.taken)
	assert_eq(_run.state.shards, 10 - Tuning.ECONOMY.heart_price)
	assert_eq(_player.health.half_hearts, _player.health.max_half_hearts)


func test_an_armor_at_the_cap_is_refused_and_otherwise_bought() -> void:
	await _go(_shop_cell())
	_run.add_shards(10)
	var stall: Pickup = _stall(RoomStock.Kind.ARMOR)
	var offer: RoomStock.Offer = stall.offer
	var room_left: int = _player.health.cap_half_hearts() - _player.health.max_half_hearts - _player.health.armor
	_player.health.add_armor(room_left)
	await _stand_on(stall)
	assert_eq(_run.state.shards, 10)
	assert_false(offer.taken)
	_player.health.armor = 0
	await _step_off()
	await _stand_on(stall)
	assert_true(offer.taken)
	assert_eq(_player.health.armor, Tuning.ECONOMY.armor_half_hearts)
	assert_eq(_run.state.shards, 10 - Tuning.ECONOMY.armor_price)


func test_a_consumable_swaps_with_the_one_carried() -> void:
	await _go(_shop_cell())
	_run.add_shards(10)
	var stall: Pickup = _stall(RoomStock.Kind.CONSUMABLE)
	var offer: RoomStock.Offer = stall.offer
	var bought: ConsumableDef = offer.consumable
	var other: ConsumableDef = ConsumableCatalog.all()[0]
	if other.id == bought.id:
		other = ConsumableCatalog.all()[1]
	_player.carrier.acquire_consumable(other)
	await _stand_on(stall)
	assert_true(offer.taken)
	assert_eq(_player.carrier.loadout.consumable.id, bought.id)
	assert_eq(_run.state.shards, 10 - Tuning.ECONOMY.consumable_price)
	var dropped: bool = false
	for pickup: Pickup in _run.current_room().pickups():
		dropped = dropped or (pickup.offer.kind == RoomStock.Kind.CONSUMABLE and pickup.offer.consumable.id == other.id)
	assert_true(dropped, "the old one lies on the floor")


func test_a_falling_tooth_at_one_heart_max_is_refused_and_keeps_the_shards() -> void:
	await _go(_shop_cell())
	_run.add_shards(40)
	var stall: Pickup = _stall(RoomStock.Kind.ITEM)
	var offer: RoomStock.Offer = stall.offer
	# A stall that cannot be taken: the offer is swapped for a tooth after the player went down to one heart max.
	offer.item = load("res://data/items/falling_tooth.tres") as ItemDef
	_player.health.lose_max(_player.health.max_half_hearts - 2)
	await _stand_on(stall)
	assert_eq(_run.state.shards, 40)
	assert_false(offer.taken)


func test_a_purchase_is_announced_on_the_bus() -> void:
	await _go(_shop_cell())
	_run.add_shards(10)
	var seen: Array = []
	var listener: Callable = func(id: StringName, price: int) -> void: seen.append([id, price])
	Events.shop_purchased.connect(listener)
	await _stand_on(_stall(RoomStock.Kind.ARMOR))
	Events.shop_purchased.disconnect(listener)
	assert_eq(seen, [[&"armor", Tuning.ECONOMY.armor_price]])


func test_the_banner_opens_near_an_item_without_buying() -> void:
	await _go(_shop_cell())
	_run.add_shards(20)
	var stall: Pickup = _stall(RoomStock.Kind.ITEM)
	var seen: Array[StringName] = []
	var listener: Callable = func(title: StringName, _bonus: StringName, _cost: StringName) -> void: seen.append(title)
	Events.banner_requested.connect(listener)
	_player.global_position = stall.global_position + Vector2(Const.TILE_SIZE * 1.5, 0)
	await _harness.ticks(4)
	Events.banner_requested.disconnect(listener)
	assert_eq(seen, [stall.offer.item.name_key])
	assert_false(stall.offer.taken)
	assert_eq(_run.state.shards, 20)
