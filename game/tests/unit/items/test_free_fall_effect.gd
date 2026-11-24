extends GutTest
## Free fall (story 5.6): +5 % damage per full second without a hit up to +50 %, half a heart more on the first hit.

const FREE_FALL: ItemDef = preload("res://data/items/free_fall.tres")
const DAMAGE: StatBlock.Stat = StatBlock.Stat.DAMAGE

var _player: Player
var _carrier: BuildCarrier
var _base: float


func before_each() -> void:
	_player = PlayerFactory.make(self)
	_carrier = _player.carrier
	_base = _player.stats.value_of(DAMAGE)


func after_each() -> void:
	_player.free()


func _tick(seconds: float) -> void:
	for i: int in roundi(seconds * 60.0):
		_carrier._physics_process(1.0 / 60.0)


func _ratio() -> float:
	return _player.stats.value_of(DAMAGE) / _base


func _incoming(amount: float = 2.0) -> DamageInfo:
	var info: DamageInfo = DamageInfo.new()
	info.amount = amount
	_carrier.hit_incoming.emit(info)
	return info


func test_the_bonus_climbs_by_steps_of_a_second_and_is_capped() -> void:
	_carrier.acquire(FREE_FALL)
	assert_almost_eq(_ratio(), 1.0, 0.0001)
	_tick(0.9)
	assert_almost_eq(_ratio(), 1.0, 0.0001, "no full second yet")
	_tick(0.2)
	assert_almost_eq(_ratio(), 1.05, 0.0001)
	_tick(2.0)
	assert_almost_eq(_ratio(), 1.15, 0.0001)
	_tick(7.0)
	assert_almost_eq(_ratio(), 1.5, 0.0001, "10 s: the cap")
	_tick(30.0)
	assert_almost_eq(_ratio(), 1.5, 0.0001)


func test_stat_changes_only_once_per_step() -> void:
	_carrier.acquire(FREE_FALL)
	var changes: Array[int] = []
	_player.stats.changed.connect(func(stat: int) -> void: changes.append(stat))
	_tick(3.0)
	assert_eq(changes.count(DAMAGE), 3)


func test_no_extra_damage_without_a_bonus() -> void:
	_carrier.acquire(FREE_FALL)
	assert_eq(_incoming(2.0).amount, 2.0)


func test_a_hit_with_a_bonus_costs_half_a_heart_more_and_resets_it() -> void:
	_carrier.acquire(FREE_FALL)
	_tick(3.0)
	var info: DamageInfo = _incoming(2.0)
	assert_eq(info.amount, 3.0)
	assert_almost_eq(_ratio(), 1.0, 0.0001)
	assert_eq(_incoming(2.0).amount, 2.0, "no bonus left for the next hit")
	_tick(1.0)
	assert_almost_eq(_ratio(), 1.05, 0.0001, "starts over from zero")


func test_a_hit_inside_the_first_second_resets_the_clock() -> void:
	_carrier.acquire(FREE_FALL)
	_tick(0.8)
	_incoming()
	_tick(0.5)
	assert_almost_eq(_ratio(), 1.0, 0.0001, "the 0.8 s before the hit are gone")


func test_the_clock_does_not_count_while_paused() -> void:
	_carrier.acquire(FREE_FALL)
	GameClock.paused = true
	_tick(5.0)
	GameClock.paused = false
	assert_almost_eq(_ratio(), 1.0, 0.0001)


func test_detach_leaves_the_stat_untouched_and_disconnects() -> void:
	var before: int = _carrier.hit_incoming.get_connections().size()
	var owned: OwnedItem = _carrier.acquire(FREE_FALL)
	_tick(3.0)
	_carrier.loadout.remove(owned)
	assert_eq(_carrier.hit_incoming.get_connections().size(), before)
	assert_almost_eq(_ratio(), 1.0, 0.0001)
	assert_eq(_incoming(2.0).amount, 2.0)
	_tick(3.0)
	assert_almost_eq(_ratio(), 1.0, 0.0001)


func test_it_is_not_stackable() -> void:
	assert_false(FREE_FALL.stackable)
	_carrier.acquire(FREE_FALL)
	assert_null(_carrier.acquire(FREE_FALL))
	assert_eq(_carrier.loadout.copies_of(&"free_fall"), 1)


func test_a_dead_player_does_not_count_time() -> void:
	_carrier.acquire(FREE_FALL)
	_player.health._dead = true
	_tick(3.0)
	assert_almost_eq(_ratio(), 1.0, 0.0001)
