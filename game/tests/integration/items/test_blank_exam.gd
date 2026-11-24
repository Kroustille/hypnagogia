extends GutTest
## Blank exam (story 5.9): the timer of a fight room, the pace of the enemies at 0, the drop that is always there.

const EXAM: ItemDef = preload("res://data/items/blank_exam.tres")
const COMBAT_ROOM: String = "res://rooms/pool/onset/onset_combat_001.tscn"
const START_ROOM: String = "res://tests/fixtures/rooms/start_room.tscn"
const WAVE_TICKS: int = 400

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	GameClock.clear_slow(self)
	_harness.release()


func _effect() -> BlankExamEffect:
	return _harness.player.carrier.loadout.items()[0].effect as BlankExamEffect


func test_the_timer_runs_in_a_fight_room_in_seconds_of_the_player_clock() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	var effect: BlankExamEffect = _effect()
	assert_true(effect.is_running())
	assert_eq(effect.seconds_left(), 45.0)
	await _harness.ticks(60)
	assert_almost_eq(effect.seconds_left(), 44.0, 0.05)


func test_the_timer_is_shown_by_the_bus_and_hidden_at_room_cleared() -> void:
	watch_signals(Events)
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	await _harness.ticks(2)
	assert_signal_emitted(Events, "exam_timer_changed")
	var shown: float = get_signal_parameters(Events, "exam_timer_changed")[0]
	assert_between(shown, 44.0, 45.0)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.room.is_cleared(), WAVE_TICKS)
	await _harness.ticks(2)
	assert_false(_effect().is_running())
	var hidden: float = get_signal_parameters(Events, "exam_timer_changed")[0]
	assert_eq(hidden, -1.0, "hidden")


func test_no_timer_without_a_fight() -> void:
	_harness.start(START_ROOM)
	_harness.player.carrier.acquire(EXAM)
	assert_false(_effect().is_running(), "a start room has no fight")


func test_no_timer_in_a_room_already_won() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.room.end_room()
	_harness.player.carrier.acquire(EXAM)
	assert_false(_effect().is_running())


func test_a_nightmare_room_never_has_a_timer() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.room.room_type = Room.RoomType.NIGHTMARE
	_harness.player.carrier.acquire(EXAM)
	assert_false(_effect().is_running())


func test_at_zero_the_pace_is_raised_and_the_timer_hidden() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	var effect: BlankExamEffect = _effect()
	assert_eq(_harness.room.danger.pace_mult, 1.0)
	effect.tick(44.0)
	assert_true(effect.is_running())
	assert_eq(_harness.room.danger.pace_mult, 1.0)
	effect.tick(1.0)
	assert_false(effect.is_running())
	assert_almost_eq(_harness.room.danger.pace_mult, 1.3, 0.0001)
	_harness.room.danger.apply_tier(Lucidity.Tier.ABANDON, Tuning.LUCIDITY)
	assert_almost_eq(_harness.room.danger.pace_mult, 1.3, 0.0001, "the tier does not touch the pace")


func test_clearing_the_room_puts_the_pace_back() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	_effect().tick(45.0)
	_harness.room.end_room()
	assert_eq(_harness.room.danger.pace_mult, 1.0)


func test_the_timer_stops_when_the_player_dies() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	_harness.player.health.died.emit()
	assert_false(_effect().is_running())


func test_the_timer_follows_the_player_clock() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(EXAM)
	GameClock.apply_slow(self, [GameClock.Group.PLAYER] as Array[GameClock.Group], 0.5, 10.0)
	await _harness.ticks(60)
	assert_almost_eq(_effect().seconds_left(), 44.5, 0.05)
