extends GutTest
## ItemPicker (story 5.2): exclusions, one draw per call, determinism.

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const FULL_HEARTS: int = 6

var _none: Array[StringName] = []


func _pool(defs: Array[ItemDef]) -> ItemPoolDef:
	var pool: ItemPoolDef = ItemPoolDef.new()
	pool.items = defs
	return pool


func _copy(id: String, stackable: bool = false) -> ItemDef:
	var def: ItemDef = ItemDef.new()
	def.id = StringName(id)
	def.stackable = stackable
	return def


func test_an_owned_item_is_excluded() -> void:
	var owned: Array[StringName] = [&"lead_legs"]
	var found: Array[ItemDef] = ItemPicker.candidates_of(_pool([TOOTH, LEGS]), owned, FULL_HEARTS)
	assert_eq(found, [TOOTH] as Array[ItemDef])
	for seed_value: int in 10:
		var rng: RandomNumberGenerator = RunRng.new(seed_value).stream(RunRng.TREASURE)
		assert_eq(ItemPicker.draw(_pool([TOOTH, LEGS]), owned, FULL_HEARTS, rng), TOOTH)


func test_a_stackable_item_stays_in_the_pool_when_owned() -> void:
	var owned: Array[StringName] = [&"falling_tooth", &"lead_legs"]
	var found: Array[ItemDef] = ItemPicker.candidates_of(_pool([TOOTH, LEGS]), owned, FULL_HEARTS)
	assert_eq(found, [TOOTH] as Array[ItemDef])


func test_the_tooth_is_excluded_with_one_heart_max() -> void:
	var found: Array[ItemDef] = ItemPicker.candidates_of(_pool([TOOTH, LEGS]), _none, 2)
	assert_eq(found, [LEGS] as Array[ItemDef])
	var three: Array[ItemDef] = ItemPicker.candidates_of(_pool([TOOTH, LEGS]), _none, 4)
	assert_eq(three.size(), 2, "two hearts max can pay one heart")


func test_an_empty_filtered_pool_gives_null_and_still_draws_once() -> void:
	var owned: Array[StringName] = [&"lead_legs"]
	var rng: RandomNumberGenerator = RunRng.new(5).stream(RunRng.TREASURE)
	var reference: RandomNumberGenerator = RunRng.new(5).stream(RunRng.TREASURE)
	assert_null(ItemPicker.draw(_pool([LEGS]), owned, FULL_HEARTS, rng))
	assert_null(ItemPicker.draw(null, _none, FULL_HEARTS, rng))
	assert_null(ItemPicker.draw(_pool([]), _none, FULL_HEARTS, rng))
	for i: int in 3:
		reference.randi()
	assert_eq(rng.state, reference.state, "one draw per call, even with nothing to offer (decision 12)")


func test_one_candidate_draws_like_eight() -> void:
	var many: Array[ItemDef] = []
	for i: int in 8:
		many.append(_copy("item_%d" % i))
	var rng_many: RandomNumberGenerator = RunRng.new(31).stream(RunRng.TREASURE)
	var rng_one: RandomNumberGenerator = RunRng.new(31).stream(RunRng.TREASURE)
	ItemPicker.draw(_pool(many), _none, FULL_HEARTS, rng_many)
	assert_eq(ItemPicker.draw(_pool([many[0]]), _none, FULL_HEARTS, rng_one), many[0])
	assert_eq(rng_one.state, rng_many.state, "a single candidate advances the stream too")


func test_one_draw_per_call_whatever_the_number_of_candidates() -> void:
	var many: Array[ItemDef] = []
	for i: int in 8:
		many.append(_copy("item_%d" % i))
	var few: Array[ItemDef] = [many[0], many[1]]
	var rng_many: RandomNumberGenerator = RunRng.new(77).stream(RunRng.TREASURE)
	var rng_few: RandomNumberGenerator = RunRng.new(77).stream(RunRng.TREASURE)
	ItemPicker.draw(_pool(many), _none, FULL_HEARTS, rng_many)
	ItemPicker.draw(_pool(few), _none, FULL_HEARTS, rng_few)
	assert_eq(rng_many.state, rng_few.state, "the stream advanced the same way")


func test_same_seed_and_same_owned_give_the_same_item() -> void:
	var many: Array[ItemDef] = []
	for i: int in 8:
		many.append(_copy("item_%d" % i))
	var first: ItemDef = ItemPicker.draw(_pool(many), _none, FULL_HEARTS, RunRng.new(2024).stream(RunRng.TREASURE, 0))
	var second: ItemDef = ItemPicker.draw(_pool(many), _none, FULL_HEARTS, RunRng.new(2024).stream(RunRng.TREASURE, 0))
	assert_eq(first.id, second.id)
	var seen: Dictionary[StringName, bool] = {}
	for seed_value: int in 60:
		seen[ItemPicker.draw(_pool(many), _none, FULL_HEARTS, RunRng.new(seed_value).stream(RunRng.TREASURE)).id] = true
	assert_gt(seen.size(), 4, "different seeds reach several items")
