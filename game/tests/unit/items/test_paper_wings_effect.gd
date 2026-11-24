extends GutTest
## Paper wings (story 5.6): flight on, off for 3 s after a hit, back, relaunched by another hit, clean detach.

const WINGS: ItemDef = preload("res://data/items/paper_wings.tres")
const FLY: StatBlock.Stat = StatBlock.Stat.CAN_FLY_OVER_PITS

var _player: Player
var _carrier: BuildCarrier


func before_each() -> void:
	_player = PlayerFactory.make(self)
	_carrier = _player.carrier


func after_each() -> void:
	_player.free()


func _tick(seconds: float) -> void:
	# the carrier ticks its effects with the scaled delta; 60 ticks of 1/60 s here
	var count: int = roundi(seconds * 60.0)
	for i: int in count:
		_carrier._physics_process(1.0 / 60.0)


func _hit() -> void:
	_carrier.hit_taken.emit(1, DamageInfo.Source.ENEMY_BULLET)


func test_the_flight_is_on_as_soon_as_the_item_is_carried() -> void:
	assert_false(_player.can_fly_over_pits())
	_carrier.acquire(WINGS)
	assert_eq(_player.stats.value_of(FLY), 1.0)
	assert_true(_player.can_fly_over_pits())


func test_a_hit_takes_the_flight_away_for_three_seconds() -> void:
	_carrier.acquire(WINGS)
	_hit()
	assert_false(_player.can_fly_over_pits())
	_tick(2.9)
	assert_false(_player.can_fly_over_pits(), "still away")
	_tick(0.2)
	assert_true(_player.can_fly_over_pits(), "back after 3 s")


func test_a_second_hit_restarts_the_three_seconds() -> void:
	_carrier.acquire(WINGS)
	_hit()
	_tick(2.0)
	_hit()
	_tick(2.0)
	assert_false(_player.can_fly_over_pits(), "4 s after the first hit but 2 s after the second")
	_tick(1.1)
	assert_true(_player.can_fly_over_pits())


func test_a_hit_that_kills_does_nothing() -> void:
	_carrier.acquire(WINGS)
	_player.health.half_hearts = 0
	_player.health._dead = true
	_hit()
	assert_true(_player.can_fly_over_pits())


func test_the_wings_do_not_come_back_with_the_clock_paused() -> void:
	_carrier.acquire(WINGS)
	_hit()
	GameClock.paused = true
	_tick(5.0)
	GameClock.paused = false
	assert_false(_player.can_fly_over_pits())


func test_detach_gives_the_stat_back_and_disconnects() -> void:
	var before: int = _carrier.hit_taken.get_connections().size()
	var owned: OwnedItem = _carrier.acquire(WINGS)
	assert_eq(_carrier.hit_taken.get_connections().size(), before + 1)
	_carrier.loadout.remove(owned)
	assert_eq(_carrier.hit_taken.get_connections().size(), before)
	assert_eq(_player.stats.value_of(FLY), 0.0)
	_hit()
	_tick(4.0)
	assert_false(_player.can_fly_over_pits(), "a removed item never gives the flight back")


func test_detach_twice_is_harmless() -> void:
	var owned: OwnedItem = _carrier.acquire(WINGS)
	owned.effect.detach()
	owned.effect.detach()
	_carrier.loadout.remove(owned)
	assert_eq(_player.stats.value_of(FLY), 0.0)


func test_leaving_and_entering_the_tree_detaches_then_attaches_again() -> void:
	_carrier.acquire(WINGS)
	_player.remove_child(_carrier)
	assert_false(_player.can_fly_over_pits(), "the effect let go of the stat")
	_player.add_child(_carrier)
	assert_true(_player.can_fly_over_pits())
	assert_eq(_carrier.hit_taken.get_connections().size(), 1)


func test_the_flight_comes_back_when_the_carrier_is_re_attached_during_a_suspension() -> void:
	_carrier.acquire(WINGS)
	_hit()
	_tick(1.0)
	_player.remove_child(_carrier)
	_player.add_child(_carrier)
	assert_false(_player.can_fly_over_pits(), "still suspended")
	_tick(2.2)
	assert_true(_player.can_fly_over_pits(), "the countdown resumed")
