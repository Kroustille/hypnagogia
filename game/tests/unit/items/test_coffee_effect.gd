extends GutTest
## Coffee (story 5.3): +30 % speed and fire rate for 10 s, then -20 % speed for 5 s, then nothing; counted in player ticks.

const COFFEE: ConsumableDef = preload("res://data/consumables/coffee.tres")

var _player: Player
var _effect: CoffeeEffect
var _tps: float


func before_each() -> void:
	_player = PlayerFactory.make(self)
	_tps = Engine.physics_ticks_per_second
	_player.carrier.acquire_consumable(COFFEE)
	_player.carrier.use_consumable()
	_effect = _player.carrier.running_effect(&"coffee") as CoffeeEffect


func after_each() -> void:
	_player.free()


func _speed() -> float:
	return _player.stats.value_of(StatBlock.Stat.MOVE_SPEED)


func _rate() -> float:
	return _player.stats.value_of(StatBlock.Stat.FIRE_RATE)


func _run(ticks: float) -> void:
	for i: int in int(ticks):
		_player.carrier._physics_process(1.0 / _tps)


func test_phase_one_boosts_speed_and_fire_rate() -> void:
	assert_not_null(_effect)
	assert_eq(_effect.phase(), CoffeeEffect.Phase.BOOST)
	assert_almost_eq(_speed(), Tuning.PLAYER.move_speed * 1.3, 0.0001)
	assert_almost_eq(_rate(), Tuning.SHOT.fire_rate * 1.3, 0.0001)
	assert_null(_player.carrier.loadout.consumable)


func test_phase_two_slows_the_walk_and_restores_the_rate() -> void:
	_run(10.0 * _tps)
	assert_eq(_effect.phase(), CoffeeEffect.Phase.CRASH)
	assert_almost_eq(_speed(), Tuning.PLAYER.move_speed * 0.8, 0.0001)
	assert_almost_eq(_rate(), Tuning.SHOT.fire_rate, 0.0001)


func test_the_end_gives_everything_back() -> void:
	_run(15.0 * _tps)
	assert_true(_effect.is_done())
	assert_almost_eq(_speed(), Tuning.PLAYER.move_speed, 0.0001)
	assert_almost_eq(_rate(), Tuning.SHOT.fire_rate, 0.0001)
	assert_null(_player.carrier.running_effect(&"coffee"), "the carrier let go of it")


func test_taking_it_again_restarts_phase_one_without_stacking() -> void:
	_run(12.0 * _tps) # in the crash
	_player.carrier.acquire_consumable(COFFEE)
	_player.carrier.use_consumable()
	assert_same(_player.carrier.running_effect(&"coffee"), _effect, "one object")
	assert_eq(_effect.phase(), CoffeeEffect.Phase.BOOST)
	assert_almost_eq(_speed(), Tuning.PLAYER.move_speed * 1.3, 0.0001)
	_run(5.0 * _tps)
	assert_eq(_effect.phase(), CoffeeEffect.Phase.BOOST, "the ten seconds started over")
	_player.carrier.acquire_consumable(COFFEE)
	_player.carrier.use_consumable()
	assert_almost_eq(_rate(), Tuning.SHOT.fire_rate * 1.3, 0.0001, "no +60 %")


func test_durations_follow_the_player_clock() -> void:
	GameClock.global_multiplier = 0.5
	_run(10.0 * _tps)
	GameClock.global_multiplier = 1.0
	assert_eq(_effect.phase(), CoffeeEffect.Phase.BOOST, "half speed: only five seconds went by")
	_run(5.0 * _tps)
	assert_eq(_effect.phase(), CoffeeEffect.Phase.CRASH)


func test_a_pause_freezes_it() -> void:
	GameClock.paused = true
	_run(20.0 * _tps)
	GameClock.paused = false
	assert_eq(_effect.phase(), CoffeeEffect.Phase.BOOST)


func test_the_fire_rate_reaches_the_shooter() -> void:
	var shots: int = 0
	var shooter: Shooter = _player._shooter
	for i: int in int(_tps):
		if shooter.tick(1.0, true, false):
			shots += 1
	assert_between(shots, int(Tuning.SHOT.fire_rate * 1.3) - 1, int(Tuning.SHOT.fire_rate * 1.3) + 1)
