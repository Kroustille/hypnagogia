extends GutTest
## The wake time through a run and its screens (story 6.6): set before run_ended, shown on the wake screen and by the
## bedroom alarm clock.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _dir: SaveDir
var _harness: RoomHarness
var _log: Array[String] = []
var _minutes: Array[int] = []


func before_each() -> void:
	_dir = SaveDir.new()
	_log.clear()
	_minutes.clear()
	Events.wake_time_set.connect(_on_wake_time_set)
	Events.run_ended.connect(_on_run_ended)


func after_each() -> void:
	_dir.restore()
	Events.wake_time_set.disconnect(_on_wake_time_set)
	Events.run_ended.disconnect(_on_run_ended)
	GameClock.paused = false
	if _harness != null:
		_harness.release()
		_harness = null
	Main.start_in_bedroom = false


func _on_wake_time_set(minute: int) -> void:
	_log.append("time")
	_minutes.append(minute)


func _on_run_ended(_outcome: int) -> void:
	_log.append("ended")


func _floor_run() -> Run:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_floor(1234)
	return _harness.run


func _clear_combat_rooms(run: Run, count: int) -> void:
	var combats: Array[Vector2i] = run.floor_layout.cells_of_type(Room.RoomType.COMBAT)
	for index: int in count:
		run.floor_map.mark_cleared(combats[index])


func test_a_death_reads_the_rooms_cleared_and_sets_the_time_before_run_ended() -> void:
	var run: Run = _floor_run()
	var total: int = run.floor_layout.cells_of_type(Room.RoomType.COMBAT).size()
	_clear_combat_rooms(run, total / 2)
	run._on_player_died()
	assert_eq(_log, ["time", "ended"] as Array[String])
	assert_eq(_minutes[0], WakeClock.new().minute_at(0, total / 2, total))
	assert_eq(run.state.wake_minute, _minutes[0])


func test_cells_without_a_fight_do_not_count() -> void:
	var run: Run = _floor_run()
	assert_true(run.floor_map.is_cleared(run.floor_layout.start), "the start room is cleared on entry")
	run._on_player_died()
	assert_eq(_minutes, [1380] as Array[int], "no combat room cleared: 23:00")


func test_a_death_with_every_room_cleared_stays_at_00_17() -> void:
	var run: Run = _floor_run()
	_clear_combat_rooms(run, run.floor_layout.cells_of_type(Room.RoomType.COMBAT).size())
	run._on_player_died()
	assert_eq(WakeClock.format(_minutes[0]), "00:17")


func test_a_victory_wakes_at_00_18_and_only_once() -> void:
	var run: Run = _floor_run()
	run._end_by_victory()
	run._on_player_died() # ignored: the run is over
	assert_eq(_log, ["time", "ended"] as Array[String])
	assert_eq(WakeClock.format(_minutes[0]), "00:18")


func test_a_run_without_a_floor_plan_wakes_at_the_start_of_the_night() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start("res://rooms/arena/arena.tscn")
	_harness.run._on_player_died()
	assert_eq(_minutes, [1380] as Array[int])


func test_the_wake_screen_and_the_bedroom_clock_show_the_time() -> void:
	Main.start_in_bedroom = true
	var main: Main = MAIN_SCENE.instantiate() as Main
	add_child(main)
	await wait_physics_frames(2)
	var bedroom: Bedroom = main.find_children("*", "Bedroom", true, false)[0] as Bedroom
	assert_eq((bedroom.get_node("%AlarmClock") as Label).text, "23:00", "before any run")
	main.free()
	Main.start_in_bedroom = false
	main = MAIN_SCENE.instantiate() as Main
	add_child(main)
	await wait_physics_frames(2)
	Events.wake_time_set.emit(1419)
	Events.run_ended.emit(Run.Outcome.DEATH)
	await wait_physics_frames(25)
	var wake: WakeScreen = main.find_children("*", "WakeScreen", true, false)[0] as WakeScreen
	assert_eq((wake.get_node("%TimeLabel") as Label).text, "Réveil : 23:39")
	(wake.get_node("%BedroomButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	bedroom = main.find_children("*", "Bedroom", true, false)[0] as Bedroom
	assert_eq((bedroom.get_node("%AlarmClock") as Label).text, "23:39")
	RoomLoader.collect_orphans(true)
	main.free()


func test_a_plan_only_generated_for_the_map_log_does_not_change_the_time_of_an_arena_run() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start("res://rooms/arena/arena.tscn")
	_harness.run.ensure_floor() # what F1 G does: a plan that is not played
	_harness.run.floor_map.mark_cleared(Vector2i.ZERO)
	_harness.run._on_player_died()
	assert_eq(_minutes, [1380] as Array[int])
