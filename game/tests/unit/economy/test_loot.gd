extends GutTest
## Loot.roll (story 5.4): shards by tier, the drop chance, a stream that moves the same way every time.

const SEED: int = 2468


func _rng(seed_value: int = SEED) -> RandomNumberGenerator:
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = seed_value
	return generator


func _economy(shards_min: int, shards_max: int, chance: float) -> EconomyTuning:
	var tuning: EconomyTuning = EconomyTuning.new()
	tuning.shards_min = shards_min
	tuning.shards_max = shards_max
	tuning.drop_chance = chance
	return tuning


func test_shards_follow_the_tier_multiplier() -> void:
	var expected: Dictionary[int, int] = {0: 1, 1: 1, 2: 2, 3: 2, 4: 2} # base 1: 1, 1.25 -> 1, 1.5 -> 2 (1.5 rounds up)
	for tier: int in expected:
		var result: Loot.LootResult = Loot.roll(tier, _rng(), Tuning.LUCIDITY, _economy(1, 1, 0.0))
		assert_eq(result.shards, expected[tier], "base 1 at tier %d" % tier)


func test_a_base_of_two_gives_three_at_x1_25_because_2_5_rounds_away_from_zero() -> void:
	assert_eq(Loot.roll(1, _rng(), Tuning.LUCIDITY, _economy(2, 2, 0.0)).shards, 3)
	assert_eq(Loot.roll(3, _rng(), Tuning.LUCIDITY, _economy(2, 2, 0.0)).shards, 4)
	assert_eq(Loot.roll(0, _rng(), Tuning.LUCIDITY, _economy(2, 2, 0.0)).shards, 2)


func test_total_abandon_doubles_the_range() -> void:
	for seed_value: int in 50:
		var shards: int = Loot.roll(4, _rng(seed_value), Tuning.LUCIDITY, Tuning.ECONOMY).shards
		assert_between(shards, 2, 6)


func _drop_rate(tier: int) -> float:
	var drops: int = 0
	var rooms: int = 4000
	var generator: RandomNumberGenerator = _rng()
	for _i: int in rooms:
		drops += Loot.roll(tier, generator, Tuning.LUCIDITY, Tuning.ECONOMY).drops.size()
	return float(drops) / rooms


func test_the_drop_chance_is_30_percent_when_lucid_and_60_percent_in_abandon() -> void:
	assert_almost_eq(_drop_rate(0), 0.3, 0.04)
	assert_almost_eq(_drop_rate(3), 0.6, 0.04)


func test_the_chance_is_capped_at_one() -> void:
	var always: EconomyTuning = _economy(1, 1, 0.9)
	for _i: int in 30:
		assert_eq(Loot.roll(4, _rng(_i), Tuning.LUCIDITY, always).drops.size(), 1)


func test_the_stream_moves_the_same_way_with_or_without_a_drop_and_at_any_tier() -> void:
	# Same seed: the chance draw decides the outcome only, so after the roll both streams are at the same point.
	var never: RandomNumberGenerator = _rng()
	var always: RandomNumberGenerator = _rng()
	var deep: RandomNumberGenerator = _rng()
	Loot.roll(0, never, Tuning.LUCIDITY, _economy(1, 3, 0.0))
	Loot.roll(0, always, Tuning.LUCIDITY, _economy(1, 3, 1.0))
	Loot.roll(4, deep, Tuning.LUCIDITY, _economy(1, 3, 0.3))
	var next_never: int = never.randi()
	assert_eq(always.randi(), next_never)
	assert_eq(deep.randi(), next_never)


func test_the_same_seed_gives_the_same_thousand_rooms() -> void:
	var first: Array = _thousand()
	assert_eq(_thousand(), first)


func _thousand() -> Array:
	var generator: RandomNumberGenerator = _rng()
	var log: Array = []
	for _i: int in 1000:
		var result: Loot.LootResult = Loot.roll(_i % 5, generator, Tuning.LUCIDITY, Tuning.ECONOMY)
		log.append([result.shards, result.drops.duplicate(), result.consumable_rolls.duplicate()])
	return log


func test_extra_drops_add_guaranteed_drops_and_none_by_default() -> void:
	var plain: Loot.LootResult = Loot.roll(0, _rng(), Tuning.LUCIDITY, _economy(1, 1, 0.0))
	assert_eq(plain.drops.size(), 0)
	var boosted: Loot.LootResult = Loot.roll(0, _rng(), Tuning.LUCIDITY, _economy(1, 1, 0.0), 1)
	assert_eq(boosted.drops.size(), 1)
	var too_many: Loot.LootResult = Loot.roll(0, _rng(), Tuning.LUCIDITY, _economy(1, 1, 0.0), 5)
	assert_eq(too_many.drops.size(), Loot.EXTRA_SLOTS, "cut to the slots the stream pays for")


func test_the_extra_drop_never_shifts_the_stream_nor_the_normal_sequence() -> void:
	var without: RandomNumberGenerator = _rng(9)
	var with_extra: RandomNumberGenerator = _rng(9)
	var plain: Loot.LootResult = Loot.roll(2, without, Tuning.LUCIDITY, Tuning.ECONOMY, 0)
	var boosted: Loot.LootResult = Loot.roll(2, with_extra, Tuning.LUCIDITY, Tuning.ECONOMY, 1)
	assert_eq(with_extra.randi(), without.randi(), "same number of draws with or without the item")
	assert_eq(boosted.shards, plain.shards)
	assert_eq(boosted.drops.slice(0, plain.drops.size()), plain.drops, "the normal drop is the same")
	assert_eq(boosted.drops.size(), plain.drops.size() + 1, "one more, with no chance roll")


func test_a_consumable_drop_carries_its_raw_draw_and_picks_by_id_order() -> void:
	var found: bool = false
	for seed_value: int in 200:
		var result: Loot.LootResult = Loot.roll(0, _rng(seed_value), Tuning.LUCIDITY, _economy(1, 1, 1.0))
		if result.drops[0] == Drops.Kind.CONSUMABLE:
			found = true
			assert_not_null(Drops.consumable_for(result.consumable_rolls[0]))
	assert_true(found)
	assert_eq(Drops.consumable_for(0).id, &"coffee")
	assert_eq(Drops.consumable_for(1).id, &"pinch")
	assert_eq(Drops.consumable_for(2).id, &"coffee")
