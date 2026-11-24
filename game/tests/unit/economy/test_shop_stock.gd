extends GutTest
## ShopStock (story 5.5): the five stalls, distinct items, fixed draws, determinism.

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const FULL_HEARTS: int = 6

var _none: Array[StringName] = []


func _pool(defs: Array[ItemDef]) -> ItemPoolDef:
	var pool: ItemPoolDef = ItemPoolDef.new()
	pool.items = defs
	return pool


func _draw(seed_value: int, owned: Array[StringName] = _none, hearts: int = FULL_HEARTS) -> Array[RoomStock.Offer]:
	return ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), owned, hearts,
			RunRng.new(seed_value).stream(RunRng.SHOP), Tuning.ECONOMY)


func _ids(offers: Array[RoomStock.Offer]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for offer: RoomStock.Offer in offers:
		ids.append(offer.id())
	return ids


func test_five_stalls_with_the_prices_of_the_tuning() -> void:
	var offers: Array[RoomStock.Offer] = _draw(1)
	assert_eq(offers.size(), 5)
	var kinds: Array[int] = []
	var prices: Array[int] = []
	for offer: RoomStock.Offer in offers:
		kinds.append(offer.kind)
		prices.append(offer.price)
	assert_eq(kinds, [RoomStock.Kind.ITEM, RoomStock.Kind.ITEM, RoomStock.Kind.CONSUMABLE, RoomStock.Kind.HEART,
			RoomStock.Kind.ARMOR] as Array[int])
	var tuning: EconomyTuning = Tuning.ECONOMY
	assert_eq(prices, [tuning.item_price, tuning.item_price, tuning.consumable_price, tuning.heart_price,
			tuning.armor_price] as Array[int])
	assert_eq(offers[3].amount, tuning.heal_half_hearts)
	assert_eq(offers[4].amount, tuning.armor_half_hearts)


func test_the_two_items_are_distinct_for_every_seed() -> void:
	for seed_value: int in 40:
		var offers: Array[RoomStock.Offer] = _draw(seed_value)
		assert_ne(offers[0].item.id, offers[1].item.id, "seed %d" % seed_value)


func test_owned_items_are_never_offered_and_one_candidate_gives_one_item() -> void:
	var owned: Array[StringName] = [&"lead_legs"]
	var offers: Array[RoomStock.Offer] = _draw(3, owned)
	assert_eq(offers.size(), 4, "one item only")
	assert_eq(offers[0].item.id, &"falling_tooth")
	var one_heart: Array[RoomStock.Offer] = _draw(3, _none, 2)
	assert_eq(one_heart[0].item.id, &"lead_legs", "no tooth with one heart max")
	assert_eq(one_heart.size(), 4)


func test_the_same_seed_gives_the_same_stalls_and_the_draws_do_not_depend_on_the_inventory() -> void:
	assert_eq(_ids(_draw(9)), _ids(_draw(9)))
	var full: RandomNumberGenerator = RunRng.new(9).stream(RunRng.SHOP)
	var poor: RandomNumberGenerator = RunRng.new(9).stream(RunRng.SHOP)
	var owned: Array[StringName] = [&"lead_legs", &"falling_tooth"]
	ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), _none, FULL_HEARTS, full, Tuning.ECONOMY)
	ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), owned, 2, poor, Tuning.ECONOMY)
	assert_eq(poor.state, full.state, "three draws whatever is held")


func test_other_streams_are_untouched() -> void:
	var rng: RunRng = RunRng.new(4)
	var treasure: int = rng.stream(RunRng.TREASURE).state
	ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), _none, FULL_HEARTS, rng.stream(RunRng.SHOP), Tuning.ECONOMY)
	assert_eq(rng.stream(RunRng.TREASURE).state, treasure)


func test_a_player_who_cannot_wear_armor_gets_a_second_heart_at_the_heart_price() -> void:
	var offers: Array[RoomStock.Offer] = ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), _none, FULL_HEARTS,
			RunRng.new(1).stream(RunRng.SHOP), Tuning.ECONOMY, true)
	var tuning: EconomyTuning = Tuning.ECONOMY
	assert_eq(offers.size(), 5)
	assert_eq(offers[3].kind, RoomStock.Kind.HEART)
	assert_eq(offers[4].kind, RoomStock.Kind.HEART)
	assert_eq(offers[4].price, tuning.heart_price)
	assert_eq(offers[4].amount, tuning.heal_half_hearts)
	for offer: RoomStock.Offer in offers:
		assert_ne(offer.kind, RoomStock.Kind.ARMOR)


func test_the_draws_do_not_change_without_armor() -> void:
	var plain: RandomNumberGenerator = RunRng.new(4).stream(RunRng.SHOP)
	var bare: RandomNumberGenerator = RunRng.new(4).stream(RunRng.SHOP)
	var with_armor: Array[RoomStock.Offer] = ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), _none, FULL_HEARTS, plain, Tuning.ECONOMY)
	var without_armor: Array[RoomStock.Offer] = ShopStock.draw(_pool([TOOTH, LEGS]), ConsumableCatalog.all(), _none, FULL_HEARTS, bare, Tuning.ECONOMY, true)
	assert_eq(plain.randi(), bare.randi())
	assert_eq(_ids(with_armor).slice(0, 3), _ids(without_armor).slice(0, 3))


func test_a_stall_seen_before_the_item_is_corrected_on_the_next_entry() -> void:
	var stock: RoomStock = RoomStock.new()
	for offer: RoomStock.Offer in _draw(2):
		stock.add_offer(offer, Vector2.ZERO)
	stock.add_drop(RoomStock.Kind.ARMOR, 1, Vector2.ZERO) # a floor drop (free): it stays
	assert_eq(stock.apply_no_armor(Tuning.ECONOMY), 1)
	var kinds: Array[int] = []
	for offer: RoomStock.Offer in stock.offers:
		kinds.append(offer.kind)
	assert_eq(kinds.count(RoomStock.Kind.ARMOR), 1, "only the drop is left")
	assert_eq(stock.offers[4].price, Tuning.ECONOMY.heart_price)
