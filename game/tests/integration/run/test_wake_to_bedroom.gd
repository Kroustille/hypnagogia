extends GutTest
## Waking up (story 6.5): "back to the bedroom" after a death or a victory, "sleep again" stays the quick restart.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
## Under the 3 s of the direct restart (story 2.2), in milliseconds.
const RESTART_BUDGET_MSEC: int = 3000

var _main: Main


func before_each() -> void:
	Main.start_in_bedroom = false
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func after_each() -> void:
	GameClock.paused = false
	Input.action_release(&"pause")
	RoomLoader.collect_orphans(true)
	remove_child(_main)
	_main.queue_free()


func _active() -> Node:
	return _main.get_node("%ActiveScene")


func _wake() -> WakeScreen:
	return _main.find_children("*", "WakeScreen", true, false)[0] as WakeScreen


func _has(node_class: GDScript) -> bool:
	for child: Node in _active().get_children():
		if is_instance_of(child, node_class):
			return true
	return false


func _end_run(outcome: int) -> void:
	Events.run_ended.emit(outcome)
	await wait_physics_frames(25) # the input guard of the screen


func test_back_to_the_bedroom_after_a_death() -> void:
	var run: Run = get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run
	await _end_run(Run.Outcome.DEATH)
	assert_true(GameClock.paused, "frozen behind the screen")
	(_wake().get_node("%BedroomButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_true(_has(Bedroom))
	assert_false(_has(Run))
	assert_eq(_active().get_child_count(), 1)
	assert_false(is_instance_valid(run), "the dead run is freed")
	assert_false(GameClock.paused)
	assert_false(_wake().visible)
	assert_false((_main.find_children("*", "Hud", true, false)[0] as Hud).visible)


func test_back_to_the_bedroom_after_a_victory() -> void:
	await _end_run(Run.Outcome.VICTORY)
	(_wake().get_node("%BedroomButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_eq(Audio.music_cutoff_hz(), Audio.OPEN_CUTOFF_HZ)
	assert_true(_has(Bedroom))
	assert_false(_has(Run))
	assert_false(GameClock.paused)


func test_sleeping_again_keeps_focus_and_starts_a_new_run_fast() -> void:
	var run: Run = get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run
	await _end_run(Run.Outcome.DEATH)
	assert_true((_wake().get_node("%RestartButton") as Button).has_focus(), "sleep again is the default")
	var started: int = Time.get_ticks_msec()
	(_wake().get_node("%RestartButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	var elapsed: int = Time.get_ticks_msec() - started
	assert_lt(elapsed, RESTART_BUDGET_MSEC)
	assert_true(_has(Run))
	assert_false(_has(Bedroom))
	assert_ne(get_tree().get_first_node_in_group(Const.GROUP_RUN), run, "a new run")
	assert_false(GameClock.paused)


func test_the_bedroom_button_waits_for_the_input_guard() -> void:
	Events.run_ended.emit(Run.Outcome.DEATH)
	(_wake().get_node("%BedroomButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_false(_has(Bedroom), "ignored while the screen is guarded")
	assert_true(_has(Run))
