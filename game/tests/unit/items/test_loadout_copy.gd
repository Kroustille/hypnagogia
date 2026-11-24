extends GutTest
## Loadout.copy_defs() and add_def_for_copy() (story 5.10, AC 3): the copy of the build the Reflection receives.

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const MIRROR: ItemDef = preload("res://data/items/mirror.tres")
const FREE_FALL: ItemDef = preload("res://data/items/free_fall.tres")
const ALARM: ItemDef = preload("res://data/items/broken_alarm.tres")

var _player_stats: StatBlock
var _player_carrier: BuildCarrier
var _copy_stats: StatBlock
var _copy_carrier: BuildCarrier


func before_each() -> void:
	_player_stats = _make_stats()
	_player_carrier = BuildCarrier.new()
	_player_carrier.setup(null, _player_stats)
	_copy_stats = _make_stats()
	_copy_carrier = BuildCarrier.new()
	_copy_carrier.setup_host(Node.new(), _copy_stats)


func after_each() -> void:
	if is_instance_valid(_copy_carrier.host):
		_copy_carrier.host.free()
	_player_carrier.free()
	_copy_carrier.free()


func _make_stats() -> StatBlock:
	var stats: StatBlock = StatBlock.new()
	stats.set_base(StatBlock.Stat.MOVE_SPEED, 2.0)
	stats.set_base(StatBlock.Stat.REAR_SHOT, 0.0)
	stats.set_base(StatBlock.Stat.PIERCE, 0.0)
	return stats


func _copy_everything() -> void:
	for def: ItemDef in _player_carrier.loadout.copy_defs():
		_copy_carrier.loadout.add_def_for_copy(def)


func test_copy_defs_gives_definitions_one_per_copy() -> void:
	_player_carrier.loadout.add(TOOTH)
	_player_carrier.loadout.add(TOOTH)
	_player_carrier.loadout.add(MIRROR)
	var defs: Array[ItemDef] = _player_carrier.loadout.copy_defs()
	assert_eq(defs.size(), 3)
	assert_eq(defs.count(TOOTH), 2)


func test_the_active_item_is_not_copied() -> void:
	_player_carrier.loadout.add(ALARM)
	assert_eq(_player_carrier.loadout.copy_defs().size(), 0)
	assert_null(_copy_carrier.loadout.add_def_for_copy(ALARM))
	assert_null(_copy_carrier.loadout.active)


func test_the_stat_modifiers_apply_to_the_copy_only() -> void:
	_player_carrier.loadout.add(LEGS)
	_player_carrier.loadout.add(MIRROR)
	_copy_everything()
	assert_almost_eq(_copy_stats.value_of(StatBlock.Stat.MOVE_SPEED), 1.6, 0.0001, "lead legs: -20 %")
	assert_eq(_copy_stats.value_of(StatBlock.Stat.REAR_SHOT), 1.0, "the Mirror gives the rear shot")
	assert_eq(_copy_stats.value_of(StatBlock.Stat.PIERCE), 1.0, "the stat is there; the pattern ignores it")


func test_the_copies_share_no_source_with_the_player() -> void:
	_player_carrier.loadout.add(LEGS)
	_copy_everything()
	var original: OwnedItem = _player_carrier.loadout.items()[0]
	var copy: OwnedItem = _copy_carrier.loadout.items()[0]
	assert_ne(copy, original)
	_player_carrier.loadout.remove(original)
	assert_eq(_player_stats.value_of(StatBlock.Stat.MOVE_SPEED), 2.0)
	assert_almost_eq(_copy_stats.value_of(StatBlock.Stat.MOVE_SPEED), 1.6, 0.0001, "the copy keeps its own modifier")


func test_the_tooth_costs_no_heart_and_an_unsupported_effect_is_not_attached() -> void:
	var tooth_copy: OwnedItem = _copy_carrier.loadout.add_def_for_copy(TOOTH)
	assert_not_null(tooth_copy, "its damage bonus is copied")
	assert_null(tooth_copy.effect)
	assert_eq(tooth_copy.max_half_hearts_paid, 0, "no heart is taken from a copy")
	var fall_copy: OwnedItem = _copy_carrier.loadout.add_def_for_copy(FREE_FALL)
	assert_not_null(fall_copy)
	assert_null(fall_copy.effect, "free fall does not support a non-player host")
	assert_eq(fall_copy.charge_max, 0)


func test_a_non_player_carrier_has_no_player_and_no_synergies() -> void:
	assert_null(_copy_carrier.player)
	assert_null(_copy_carrier.tags)
	assert_not_null(_copy_carrier.host)
