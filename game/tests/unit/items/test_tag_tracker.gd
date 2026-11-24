extends GutTest
## TagTracker counts distinct items per tag: two copies of one item count once (story 5.1).

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")

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
