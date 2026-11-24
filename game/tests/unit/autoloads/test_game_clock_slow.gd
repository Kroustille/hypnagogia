extends GutTest
## GameClock slows (story 5.8): groups, duration in real ticks, pause, product, token, reset.

const DT: float = 1.0 / 60.0
const SLOWED: Array[GameClock.Group] = [GameClock.Group.ENEMIES, GameClock.Group.ENEMY_BULLETS, GameClock.Group.WORLD]

var _a: RefCounted = RefCounted.new()
var _b: RefCounted = RefCounted.new()


func after_each() -> void:
	GameClock.reset_slows()
	GameClock.paused = false
	GameClock.global_multiplier = 1.0


func _run(ticks: int) -> void:
	for i: int in ticks:
		GameClock._physics_process(DT)


func test_only_the_given_groups_are_slowed() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	for group: GameClock.Group in SLOWED:
		assert_almost_eq(GameClock.scale(group), 0.5, 0.0001)
	for group: GameClock.Group in [GameClock.Group.PLAYER, GameClock.Group.PLAYER_BULLETS, GameClock.Group.FX]:
		assert_eq(GameClock.scale(group), 1.0)


func test_the_slow_ends_by_itself_after_its_seconds() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	_run(239)
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMIES), 0.5, 0.0001, "still on at 239 ticks")
	_run(2)
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)
	assert_eq(GameClock.slow_count(), 0)


func test_the_duration_is_frozen_while_paused() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 1.0)
	GameClock.paused = true
	_run(300)
	GameClock.paused = false
	assert_eq(GameClock.slow_count(), 1)
	_run(30)
	assert_eq(GameClock.slow_count(), 1, "half a second left")
	_run(31)
	assert_eq(GameClock.slow_count(), 0)


func test_the_debug_slow_motion_stretches_the_duration() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 1.0)
	GameClock.global_multiplier = 0.5
	_run(61)
	assert_eq(GameClock.slow_count(), 1, "one real second at half speed leaves half of it")
	_run(60)
	assert_eq(GameClock.slow_count(), 0)


func test_two_tokens_multiply() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	GameClock.apply_slow(_b, [GameClock.Group.ENEMIES] as Array[GameClock.Group], 0.5, 1.0)
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMIES), 0.25, 0.0001)
	assert_almost_eq(GameClock.scale(GameClock.Group.WORLD), 0.5, 0.0001)
	_run(61)
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMIES), 0.5, 0.0001, "the short one is over")


func test_the_same_token_restarts_instead_of_stacking() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 1.0)
	_run(50)
	GameClock.apply_slow(_a, SLOWED, 0.5, 1.0)
	assert_eq(GameClock.slow_count(), 1)
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMIES), 0.5, 0.0001)
	_run(30)
	assert_eq(GameClock.slow_count(), 1, "restarted: still running")


func test_clear_slow_and_reset_slows() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	GameClock.apply_slow(_b, SLOWED, 0.5, 4.0)
	GameClock.clear_slow(_a)
	assert_almost_eq(GameClock.scale(GameClock.Group.WORLD), 0.5, 0.0001)
	GameClock.reset_slows()
	assert_eq(GameClock.scale(GameClock.Group.WORLD), 1.0)
	assert_eq(GameClock.slow_count(), 0)


func test_a_run_start_or_end_resets_the_slows() -> void:
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	Events.run_ended.emit(0)
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)
	GameClock.apply_slow(_a, SLOWED, 0.5, 4.0)
	Events.run_started.emit()
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)
