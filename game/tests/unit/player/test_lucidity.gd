extends GutTest
## Lucidity: bounds, tiers, graze cap, spending and room tier. Thresholds are read from the tuning, never hardcoded.

var _tuning: LucidityTuning
var _lucidity: Lucidity


func before_each() -> void:
	_tuning = LucidityTuning.new()
	_lucidity = Lucidity.new(_tuning)


func test_starts_full_at_the_top_tier() -> void:
	assert_eq(_lucidity.value, _tuning.max_value)
	assert_eq(_lucidity.live_tier, Lucidity.Tier.LUCID)
	assert_eq(_lucidity.room_tier, Lucidity.Tier.LUCID)


func test_value_never_goes_below_zero() -> void:
	_lucidity.set_value(-50)
	assert_eq(_lucidity.value, 0)
	assert_eq(_lucidity.live_tier, Lucidity.Tier.TOTAL_ABANDON)


func test_value_never_exceeds_the_maximum() -> void:
	_lucidity.set_value(_tuning.max_value + 500)
	assert_eq(_lucidity.value, _tuning.max_value)
	_lucidity.set_value(10)
	assert_eq(_lucidity.gain(_tuning.max_value * 3), _tuning.max_value - 10, "gain returns what was really gained")
	assert_eq(_lucidity.value, _tuning.max_value)


func test_gain_ignores_negative_amounts() -> void:
	_lucidity.set_value(40)
	assert_eq(_lucidity.gain(-10), 0)
	assert_eq(_lucidity.value, 40)


func test_tier_for_at_each_floor_and_one_point_either_side() -> void:
	var floors: PackedInt32Array = _tuning.tier_floors
	for i: int in floors.size():
		var floor_value: int = floors[i]
		assert_eq(_lucidity.tier_for(floor_value), i as Lucidity.Tier, "floor %d reaches tier %d" % [floor_value, i])
		if i < floors.size() - 1:
			assert_eq(_lucidity.tier_for(floor_value - 1), (i + 1) as Lucidity.Tier,
				"one under floor %d falls to the next tier" % floor_value)
		var over_is_same_tier: bool = i == 0 or floor_value + 1 < floors[i - 1]
		var expected_over: int = i if over_is_same_tier else i - 1
		assert_eq(_lucidity.tier_for(floor_value + 1), expected_over as Lucidity.Tier,
			"one over floor %d" % floor_value)


func test_live_tier_follows_the_value() -> void:
	_lucidity.set_value(_tuning.tier_floors[1])
	assert_eq(_lucidity.live_tier, Lucidity.Tier.FLOATING)
	_lucidity.set_value(_tuning.tier_floors[1] - 1)
	assert_eq(_lucidity.live_tier, Lucidity.Tier.DRIFT)


func test_graze_gain_is_capped_per_room() -> void:
	_lucidity.set_value(0)
	var cap: int = _tuning.graze_cap_per_room
	assert_eq(_lucidity.gain(cap - 1, Lucidity.Source.GRAZE), cap - 1)
	assert_eq(_lucidity.gain(5, Lucidity.Source.GRAZE), 1, "only what is left of the cap")
	assert_eq(_lucidity.gain(5, Lucidity.Source.GRAZE), 0, "cap reached")
	assert_eq(_lucidity.value, cap)


func test_other_sources_are_not_capped_by_the_graze_cap() -> void:
	_lucidity.set_value(0)
	var cap: int = _tuning.graze_cap_per_room
	_lucidity.gain(cap, Lucidity.Source.GRAZE)
	assert_eq(_lucidity.gain(3, Lucidity.Source.PERFECT_DASH), 3)
	assert_eq(_lucidity.value, cap + 3)


func test_begin_room_reopens_the_graze_cap() -> void:
	_lucidity.set_value(0)
	_lucidity.gain(_tuning.graze_cap_per_room, Lucidity.Source.GRAZE)
	assert_eq(_lucidity.gain(1, Lucidity.Source.GRAZE), 0)
	_lucidity.begin_room()
	assert_eq(_lucidity.gain(1, Lucidity.Source.GRAZE), 1)


func test_cap_counts_only_what_was_really_gained() -> void:
	_lucidity.set_value(_tuning.max_value - 1)
	assert_eq(_lucidity.gain(_tuning.graze_cap_per_room, Lucidity.Source.GRAZE), 1, "full gauge swallows the surplus")
	_lucidity.set_value(0)
	assert_eq(_lucidity.gain(_tuning.graze_cap_per_room, Lucidity.Source.GRAZE), _tuning.graze_cap_per_room - 1)


func test_try_spend_refused_when_value_is_insufficient() -> void:
	_lucidity.set_value(5)
	watch_signals(_lucidity)
	assert_false(_lucidity.try_spend(6, &"dash"))
	assert_eq(_lucidity.value, 5, "value unchanged on refusal")
	assert_signal_not_emitted(_lucidity, "spent")
	assert_signal_not_emitted(_lucidity, "value_changed")


func test_try_spend_refused_for_non_positive_cost() -> void:
	assert_false(_lucidity.try_spend(0))
	assert_false(_lucidity.try_spend(-3))
	assert_eq(_lucidity.value, _tuning.max_value)


func test_try_spend_accepted_pays_and_emits() -> void:
	var amount: int = _tuning.tier_floors[Lucidity.Tier.DRIFT]
	_lucidity.set_value(amount)
	watch_signals(_lucidity)
	assert_true(_lucidity.try_spend(amount, &"power"), "spending exactly the value is allowed")
	assert_eq(_lucidity.value, 0)
	assert_signal_emitted_with_parameters(_lucidity, "spent", [&"power", amount, Lucidity.Tier.DRIFT])


func test_room_tier_keeps_the_lowest_tier_reached() -> void:
	_lucidity.begin_room()
	_lucidity.set_value(_tuning.tier_floors[2] - 1) # ABANDON
	assert_eq(_lucidity.room_tier, Lucidity.Tier.ABANDON)
	_lucidity.set_value(_tuning.max_value)
	assert_eq(_lucidity.live_tier, Lucidity.Tier.LUCID)
	assert_eq(_lucidity.room_tier, Lucidity.Tier.ABANDON, "room tier does not climb back inside the room")


func test_begin_room_resets_room_tier_to_the_live_tier() -> void:
	_lucidity.set_value(0)
	_lucidity.set_value(_tuning.tier_floors[1])
	_lucidity.begin_room()
	assert_eq(_lucidity.room_tier, Lucidity.Tier.FLOATING)


func test_room_danger_raised_only_when_going_deeper() -> void:
	_lucidity.begin_room()
	watch_signals(_lucidity)
	_lucidity.set_value(_tuning.tier_floors[1] - 1) # DRIFT
	assert_signal_emitted_with_parameters(_lucidity, "room_danger_raised", [Lucidity.Tier.DRIFT, Lucidity.Tier.LUCID])
	_lucidity.set_value(_tuning.max_value)
	assert_signal_emit_count(_lucidity, "room_danger_raised", 1)
	_lucidity.begin_room()
	assert_signal_emit_count(_lucidity, "room_danger_raised", 1, "begin_room never emits it")
