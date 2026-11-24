extends GutTest
## Loadout: copies are sources of their own, removal gives the stat back, nothing leaks (story 5.1, AC 3).

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")

var _stats: StatBlock
var _carrier: BuildCarrier


func before_each() -> void:
	_stats = StatBlock.new()
	_stats.set_base(StatBlock.Stat.DAMAGE, 10.0)
	_stats.set_base(StatBlock.Stat.MOVE_SPEED, 6.0)
	_carrier = BuildCarrier.new()
	_carrier.setup(null, _stats)


func after_each() -> void:
	_carrier.free()


func test_two_teeth_add_up_to_sixty_percent() -> void:
	_carrier.loadout.add(TOOTH)
	assert_almost_eq(_stats.value_of(StatBlock.Stat.DAMAGE), 13.0, 0.0001)
	_carrier.loadout.add(TOOTH)
	assert_almost_eq(_stats.value_of(StatBlock.Stat.DAMAGE), 16.0, 0.0001, "+60 %, not x1.69")
	assert_eq(_carrier.loadout.copies_of(&"falling_tooth"), 2)


func test_removing_one_copy_takes_back_only_its_share() -> void:
	var first: OwnedItem = _carrier.loadout.add(TOOTH)
	_carrier.loadout.add(TOOTH)
	assert_true(_carrier.loadout.remove(first))
	assert_almost_eq(_stats.value_of(StatBlock.Stat.DAMAGE), 13.0, 0.0001)
	assert_eq(_carrier.loadout.copies_of(&"falling_tooth"), 1)
	assert_false(_carrier.loadout.remove(first), "already gone")


func test_removing_every_copy_gives_the_stat_back() -> void:
	var owned: OwnedItem = _carrier.loadout.add(LEGS)
	assert_almost_eq(_stats.value_of(StatBlock.Stat.MOVE_SPEED), 4.8, 0.0001)
	assert_gt(_stats.value_of(StatBlock.Stat.PIERCE), 0.0)
	_carrier.loadout.remove(owned)
	assert_almost_eq(_stats.value_of(StatBlock.Stat.MOVE_SPEED), 6.0, 0.0001)
	assert_eq(_stats.value_of(StatBlock.Stat.PIERCE), 0.0)


func test_a_removed_owned_item_is_freed_with_no_modifier_left_behind() -> void:
	var owned: OwnedItem = _carrier.loadout.add(TOOTH)
	var probe: WeakRef = weakref(owned)
	_carrier.loadout.remove(owned)
	owned = null
	assert_true(probe.get_ref() == null, "the stat block no longer holds the source (RefCounted freed)")
	assert_eq(_carrier.loadout.count(), 0)


class _CountingEffect extends ItemEffect:
	static var attached: int = 0
	static var detached: int = 0

	func attach(new_carrier: BuildCarrier) -> void:
		super.attach(new_carrier)
		attached += 1

	func detach() -> void:
		super.detach()
		detached += 1


func test_an_effect_is_attached_then_detached_with_its_copy() -> void:
	var def: ItemDef = ItemDef.new()
	def.id = &"with_effect"
	def.effect_script = _CountingEffect
	_CountingEffect.attached = 0
	_CountingEffect.detached = 0
	var owned: OwnedItem = _carrier.loadout.add(def)
	assert_not_null(owned.effect)
	assert_eq(_CountingEffect.attached, 1)
	_carrier.loadout.remove(owned)
	assert_eq(_CountingEffect.detached, 1)


func test_signals_follow_the_changes() -> void:
	watch_signals(_carrier.loadout)
	var owned: OwnedItem = _carrier.loadout.add(TOOTH)
	assert_signal_emitted(_carrier.loadout, "item_added")
	_carrier.loadout.remove(owned)
	assert_signal_emitted(_carrier.loadout, "item_removed")


func test_sum_param_and_has_flag_read_the_numbers_of_the_items_held() -> void:
	var loadout: Loadout = _carrier.loadout
	assert_eq(loadout.sum_param(&"guaranteed_drops"), 0.0)
	assert_false(loadout.has_flag(&"blocks_armor"))
	var def: ItemDef = ItemDef.new()
	def.id = &"numbers"
	def.params = {&"guaranteed_drops": 1.0, &"blocks_armor": 1.0}
	loadout.add(def)
	loadout.add(def)
	assert_eq(loadout.sum_param(&"guaranteed_drops"), 2.0, "copies add up")
	assert_true(loadout.has_flag(&"blocks_armor"))
	assert_false(loadout.has_flag(&"other"))
