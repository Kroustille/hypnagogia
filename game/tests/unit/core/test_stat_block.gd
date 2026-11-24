extends GutTest
## StatBlock: additive percents, application order, one modifier per source and stat, clear_source, changed signal.

const DAMAGE: StatBlock.Stat = StatBlock.Stat.DAMAGE

var _stats: StatBlock
var _a: RefCounted
var _b: RefCounted


func before_each() -> void:
	_stats = StatBlock.new()
	_stats.set_base(DAMAGE, 10.0)
	_a = RefCounted.new()
	_b = RefCounted.new()


func test_base_value_without_modifiers() -> void:
	assert_eq(_stats.value_of(DAMAGE), 10.0)
	assert_eq(_stats.value_of(StatBlock.Stat.SHOT_SPEED), 0.0, "unset stat reads 0")


func test_add_percent_modifiers_add_up_instead_of_compounding() -> void:
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.3)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.3)
	assert_almost_eq(_stats.value_of(DAMAGE), 16.0, 0.0001, "x1.6, not x1.69")


func test_order_is_flat_then_percent_then_multiply() -> void:
	var c: RefCounted = RefCounted.new()
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 5.0)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.5)
	_stats.set_modifier(c, DAMAGE, StatBlock.Kind.MULTIPLY, 2.0)
	assert_almost_eq(_stats.value_of(DAMAGE), (10.0 + 5.0) * 1.5 * 2.0, 0.0001)


func test_multiply_modifiers_compound() -> void:
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.MULTIPLY, 2.0)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.MULTIPLY, 3.0)
	assert_almost_eq(_stats.value_of(DAMAGE), 60.0, 0.0001)


func test_one_modifier_per_source_and_stat() -> void:
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.5)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.2)
	assert_almost_eq(_stats.value_of(DAMAGE), 12.0, 0.0001, "the second set replaces the first")


func test_same_source_can_hold_one_modifier_on_each_stat() -> void:
	_stats.set_base(StatBlock.Stat.SHOT_SPEED, 4.0)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 2.0)
	_stats.set_modifier(_a, StatBlock.Stat.SHOT_SPEED, StatBlock.Kind.ADD_FLAT, 1.0)
	assert_eq(_stats.value_of(DAMAGE), 12.0)
	assert_eq(_stats.value_of(StatBlock.Stat.SHOT_SPEED), 5.0)


func test_clear_source_removes_all_its_modifiers_and_only_its_own() -> void:
	_stats.set_base(StatBlock.Stat.SHOT_SPEED, 4.0)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 2.0)
	_stats.set_modifier(_a, StatBlock.Stat.SHOT_SPEED, StatBlock.Kind.ADD_FLAT, 1.0)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.ADD_FLAT, 3.0)
	_stats.clear_source(_a)
	assert_eq(_stats.value_of(DAMAGE), 13.0)
	assert_eq(_stats.value_of(StatBlock.Stat.SHOT_SPEED), 4.0)


func test_changed_is_emitted_on_a_real_variation() -> void:
	watch_signals(_stats)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 2.0)
	assert_signal_emitted_with_parameters(_stats, "changed", [DAMAGE])
	_stats.clear_source(_a)
	assert_signal_emit_count(_stats, "changed", 2)


func test_changed_is_not_emitted_when_nothing_changes() -> void:
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 2.0)
	watch_signals(_stats)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 2.0)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.0)
	_stats.set_base(DAMAGE, 10.0)
	assert_signal_not_emitted(_stats, "changed")


func test_bounds_clamp_the_computed_value_and_signal_the_clamped_change() -> void:
	_stats.set_bounds(DAMAGE, 0.0, 12.0)
	assert_eq(_stats.value_of(DAMAGE), 10.0)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.5)
	assert_eq(_stats.value_of(DAMAGE), 12.0, "capped")
	watch_signals(_stats)
	_stats.set_modifier(_b, DAMAGE, StatBlock.Kind.ADD_PERCENT, 0.5)
	assert_signal_not_emitted(_stats, "changed", "still 12: nothing changed")
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_PERCENT, -5.0)
	assert_eq(_stats.value_of(DAMAGE), 0.0, "floored")


func test_bounds_apply_when_set_after_the_modifiers() -> void:
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 100.0)
	_stats.set_bounds(DAMAGE, 0.0, 50.0)
	assert_eq(_stats.value_of(DAMAGE), 50.0)


func test_base_changed_only_on_a_real_change_of_the_base() -> void:
	watch_signals(_stats)
	_stats.set_base(DAMAGE, 10.0)
	assert_signal_not_emitted(_stats, "base_changed")
	_stats.set_base(DAMAGE, 12.0)
	assert_signal_emit_count(_stats, "base_changed", 1)
	_stats.set_modifier(_a, DAMAGE, StatBlock.Kind.ADD_FLAT, 1.0)
	assert_signal_emit_count(_stats, "base_changed", 1, "a modifier is not a base")


func test_new_stats_come_after_the_existing_ones() -> void:
	assert_eq(StatBlock.Stat.CAN_FLY_OVER_PITS, 4)
	assert_eq(StatBlock.Stat.MOVE_SPEED, 5)
	assert_eq(StatBlock.Stat.FIRE_RATE, 6)
	assert_eq(StatBlock.Stat.PIERCE, 7)
	assert_eq(StatBlock.Stat.REAR_SHOT, 8)
