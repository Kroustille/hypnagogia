extends GutTest
## Starting a night from the bedroom (story 6.5): Main begins there, the bed starts a run, the HUD follows.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const AT_BED: Vector2 = Vector2(64, 122)
const AT_DESK: Vector2 = Vector2(496, 70)
const AWAY: Vector2 = Vector2(304, 250)

var _main: Main


func before_each() -> void:
	Main.start_in_bedroom = true
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func after_each() -> void:
	Main.start_in_bedroom = false # the default of the suite (tests/support/pre_run.gd)
	RoomLoader.collect_orphans(true)
	remove_child(_main)
	_main.queue_free()


func _active() -> Node:
	return _main.get_node("%ActiveScene")


func _bedroom() -> Bedroom:
	for child: Node in _active().get_children():
		if child is Bedroom:
			return child as Bedroom
	return null


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _hud() -> Hud:
	return _main.find_children("*", "Hud", true, false)[0] as Hud


func _move_walker(at: Vector2) -> void:
	_bedroom().walker().global_position = at
	await wait_physics_frames(2) # the zones report on the physics tick


func _interact() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"interact"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_physics_frames(3)
	var release: InputEventAction = InputEventAction.new()
	release.action = &"interact"
	release.pressed = false
	Input.parse_input_event(release)
	await wait_physics_frames(1)


func test_the_game_starts_in_the_bedroom_without_a_run_or_a_hud() -> void:
	assert_not_null(_bedroom())
	assert_null(_run())
	assert_eq(_active().get_child_count(), 1)
	assert_false(_hud().visible)
	assert_false(GameClock.paused)


func test_the_prompt_shows_only_near_the_bed_or_the_desk() -> void:
	assert_false(_bedroom().is_prompt_visible(), "not at the start position")
	await _move_walker(AT_BED)
	assert_true(_bedroom().is_prompt_visible())
	assert_string_contains(_bedroom().prompt_text(), "X", "the key read from the InputMap")
	assert_eq(_bedroom().prompt_text(), tr(&"UI_BEDROOM_SLEEP") % "X")
	await _move_walker(AWAY)
	assert_false(_bedroom().is_prompt_visible())
	await _move_walker(AT_DESK)
	assert_eq(_bedroom().prompt_text(), tr(&"UI_BEDROOM_SEED") % "X")


func test_interacting_at_the_bed_replaces_the_bedroom_by_a_fresh_run() -> void:
	await _move_walker(AT_BED)
	await _interact()
	assert_null(_bedroom(), "no bedroom node left in the active scene")
	assert_not_null(_run())
	assert_eq(_active().get_child_count(), 1)
	assert_false(_run().state.seeded, "a seed drawn at random")
	assert_true(_hud().visible)
	assert_false(GameClock.paused)


func test_interacting_elsewhere_does_nothing() -> void:
	await _move_walker(AWAY)
	await _interact()
	assert_not_null(_bedroom())
	assert_null(_run())
	assert_false(_hud().visible)


func test_the_pause_menu_works_in_the_bedroom() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"pause"
	event.pressed = true
	Input.parse_input_event(event)
	await wait_physics_frames(3)
	assert_true(GameClock.paused)
	assert_true((_main.find_children("*", "PauseMenu", true, false)[0] as PauseMenu).visible)
