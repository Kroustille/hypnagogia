extends GutTest
## TagTracker counts distinct items per tag: two copies of one item count once (story 5.1).

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const PAPER_WINGS: ItemDef = preload("res://data/items/paper_wings.tres")
const FREE_FALL: ItemDef = preload("res://data/items/free_fall.tres")

var _carrier: BuildCarrier


func before_each() -> void:
	_carrier = BuildCarrier.new()
	_carrier.setup(null, StatBlock.new())


func after_each() -> void:
	_carrier.free()


func test_two_teeth_count_once_for_fall_and_body() -> void:
	_carrier.loadout.add(TOOTH)
	_carrier.loadout.add(TOOTH)
	assert_eq(_carrier.tags.count(&"fall"), 1)
	assert_eq(_carrier.tags.count(&"body"), 1)


func test_distinct_items_of_a_tag_add_up_and_removal_lowers() -> void:
	var tooth: OwnedItem = _carrier.loadout.add(TOOTH)
	var tooth_two: OwnedItem = _carrier.loadout.add(TOOTH)
	var legs: OwnedItem = _carrier.loadout.add(LEGS)
	assert_eq(_carrier.tags.count(&"fall"), 2)
	_carrier.loadout.remove(tooth)
	assert_eq(_carrier.tags.count(&"fall"), 2, "a copy is still held")
	_carrier.loadout.remove(tooth_two)
	assert_eq(_carrier.tags.count(&"fall"), 1)
	assert_eq(_carrier.tags.count(&"body"), 0)
	_carrier.loadout.remove(legs)
	assert_eq(_carrier.tags.count(&"fall"), 0)


func test_the_signal_names_the_tag_and_its_new_count() -> void:
	watch_signals(_carrier.tags)
	_carrier.loadout.add(LEGS)
	assert_signal_emitted_with_parameters(_carrier.tags, "tag_count_changed", [&"fall", 1])
	_carrier.loadout.add(LEGS)
	assert_signal_emit_count(_carrier.tags, "tag_count_changed", 1)


func test_synergy_levels_activate_at_their_thresholds_and_the_highest_replaces() -> void:
	var tracker: TagTracker = _carrier.tags
	watch_signals(tracker)
	_carrier.loadout.add(TOOTH)
	assert_null(tracker.active_synergy(&"fall"), "one item: nothing")
	_carrier.loadout.add(LEGS)
	assert_eq(tracker.active_synergy(&"fall").id, &"fall_2")
	assert_signal_emit_count(tracker, "synergy_activated", 1)
	_carrier.loadout.add(PAPER_WINGS)
	assert_eq(tracker.active_synergy(&"fall").id, &"fall_3", "the third replaces the second")
	assert_signal_emit_count(tracker, "synergy_activated", 2)
	assert_signal_emit_count(tracker, "synergy_deactivated", 1)
	var args: Array = get_signal_parameters(tracker, "synergy_deactivated", 0)
	var gone: SynergyDef = args[0]
	assert_eq(gone.id, &"fall_2")
	_carrier.loadout.add(FREE_FALL)
	assert_eq(tracker.active_synergy(&"fall").id, &"fall_3", "no level beyond 3")
	assert_signal_emit_count(tracker, "synergy_activated", 2)


func test_two_copies_of_one_item_do_not_reach_a_threshold() -> void:
	_carrier.loadout.add(TOOTH)
	_carrier.loadout.add(TOOTH)
	assert_null(_carrier.tags.active_synergy(&"fall"))


func test_removing_an_item_below_a_threshold_deactivates_the_level_down_to_the_one_under() -> void:
	var legs: OwnedItem = _carrier.loadout.add(LEGS)
	_carrier.loadout.add(TOOTH)
	var wings: OwnedItem = _carrier.loadout.add(PAPER_WINGS)
	watch_signals(_carrier.tags)
	_carrier.loadout.remove(wings)
	assert_eq(_carrier.tags.active_synergy(&"fall").id, &"fall_2")
	_carrier.loadout.remove(legs)
	assert_null(_carrier.tags.active_synergy(&"fall"))
	assert_signal_emit_count(_carrier.tags, "synergy_deactivated", 2)
