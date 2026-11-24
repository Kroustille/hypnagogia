extends GutTest
## Telegraph.cancel() (story 4.4): no attack comes of a cancelled announcement.

var _telegraph: Telegraph


func before_each() -> void:
	_telegraph = Telegraph.new()
	_telegraph.setup(GameClock.Group.ENEMIES)
	add_child_autofree(_telegraph)


func _sound() -> AudioStream:
	return load("res://audio/sfx/sfx_enemy_sleepwalker_telegraph.wav") as AudioStream


func test_cancel_stops_a_running_telegraph_at_once() -> void:
	_telegraph.start(0.5, _sound())
	assert_true(_telegraph.is_active())
	_telegraph.cancel()
	assert_false(_telegraph.is_active(), "no attack to come")
	assert_eq(_telegraph.progress(), 0.0, "the announcing animation has no progress left")


func test_cancel_without_a_telegraph_does_nothing() -> void:
	_telegraph.cancel()
	assert_false(_telegraph.is_active())


func test_a_cancelled_telegraph_can_start_again_and_runs_its_full_duration() -> void:
	_telegraph.start(0.5, _sound())
	_telegraph.cancel()
	var duration: float = _telegraph.start(0.5, _sound())
	assert_almost_eq(duration, maxf(0.5, Tuning.COMBAT.min_telegraph), 0.0001)
	assert_true(_telegraph.is_active())
	await wait_physics_frames(int(duration * Engine.physics_ticks_per_second) + 3)
	assert_false(_telegraph.is_active(), "it ended by itself")
