extends GutTest
## The wake time (story 6.6): proportional to the combat rooms cleared, capped at death, the end of the phase at victory.

var _clock: WakeClock


func before_each() -> void:
	_clock = WakeClock.new()


func test_the_night_starts_at_23_00() -> void:
	assert_eq(WakeClock.format(_clock.start_minute()), "23:00")
	assert_eq(_clock.minute_at(0, 0, 12), 1380)


func test_half_the_rooms_make_23_39() -> void:
	assert_eq(WakeClock.format(_clock.minute_at_death(0, 6, 12)), "23:39")


func test_the_time_only_moves_when_a_room_is_finished() -> void:
	assert_eq(WakeClock.format(_clock.minute_at(0, 5, 12)), "23:32", "floori(32.5), not rounded")
	assert_eq(WakeClock.format(_clock.minute_at(0, 7, 12)), "23:45")


func test_a_death_with_every_room_cleared_stays_under_the_victory() -> void:
	assert_eq(WakeClock.format(_clock.minute_at_death(0, 12, 12)), "00:17")
	assert_eq(WakeClock.format(_clock.minute_after_boss(0)), "00:18")


func test_the_cap_can_be_disabled() -> void:
	var tuning: WakeTuning = WakeTuning.new()
	tuning.death_cap_margin_minutes = 0
	assert_eq(WakeClock.new(tuning).minute_at_death(0, 12, 12), WakeClock.new(tuning).minute_after_boss(0))


func test_no_combat_room_does_not_divide_by_zero() -> void:
	assert_eq(_clock.minute_at(0, 0, 0), 1380)
	assert_eq(_clock.minute_at(0, 3, 0), 1380)


func test_a_later_floor_is_a_phase_later_and_never_wraps_in_the_calculation() -> void:
	assert_eq(_clock.minute_at(1, 0, 12), 1380 + 78)
	assert_gt(_clock.minute_at(1, 6, 12), _clock.minute_after_boss(0))


func test_format_wraps_midnight_and_refuses_a_negative_minute() -> void:
	assert_eq(WakeClock.format(1458), "00:18")
	assert_eq(WakeClock.format(1380), "23:00")
	assert_eq(WakeClock.format(0), "00:00")
	assert_eq(WakeClock.format(-5), "--:--")
	assert_push_error("is negative")


func test_the_tuning_resource_is_valid() -> void:
	assert_true(Tuning.WAKE.is_valid())
	assert_eq(Tuning.WAKE.start_minute_of_day, 1380)
	assert_eq(Tuning.WAKE.phase_minutes, 78)
	var bad: WakeTuning = WakeTuning.new()
	bad.death_cap_margin_minutes = bad.phase_minutes
	assert_false(bad.is_valid())
