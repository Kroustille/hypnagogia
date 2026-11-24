extends GutTest
## The desk of the bedroom (story 6.5): the seed window opens over a frozen bedroom.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const AT_DESK: Vector2 = Vector2(496, 70)

var _main: Main


func before_each() -> void:
	Main.start_in_bedroom = true
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func after_each() -> void:
	GameClock.paused = false
	Input.action_release(&"pause")
	Input.action_release(&"move_right")
	Main.start_in_bedroom = false # the default of the suite (tests/support/pre_run.gd)
	RoomLoader.collect_orphans(true)
	remove_child(_main)
	_main.queue_free()


func _bedroom() -> Bedroom:
	for child: Node in _main.get_node("%ActiveScene").get_children():
		if child is Bedroom:
			return child as Bedroom
	return null


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _entry() -> SeedEntry:
	return _main.find_children("*", "SeedEntry", true, false)[0] as SeedEntry


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await wait_physics_frames(3)
	var release: InputEventAction = InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await wait_physics_frames(1)


func _open_at_the_desk() -> void:
	_bedroom().walker().global_position = AT_DESK
	await wait_physics_frames(2)
	await _press(&"interact")


func test_the_desk_opens_the_seed_window_and_freezes_the_bedroom() -> void:
	await _open_at_the_desk()
	assert_true(_entry().visible)
	assert_true(GameClock.paused)
	var before: Vector2 = _bedroom().walker().global_position
	Input.action_press(&"move_right")
	await wait_physics_frames(20)
	assert_eq(_bedroom().walker().global_position, before, "the typed letters do not walk")


func test_a_valid_seed_starts_a_seeded_run_on_it() -> void:
	await _open_at_the_desk()
	_entry().set_text("00000C1S")
	_entry().submit()
	await wait_physics_frames(3)
	assert_null(_bedroom())
	assert_not_null(_run())
	assert_true(_run().state.seeded)
	assert_eq(_run().rng.seed_code(), "00000C1S")
	assert_false(GameClock.paused)


func test_escape_goes_back_to_the_bedroom_unchanged() -> void:
	await _open_at_the_desk()
	await _press(&"ui_cancel")
	assert_false(_entry().visible)
	assert_false(GameClock.paused)
	assert_not_null(_bedroom())
	assert_null(_run())
	var before: float = _bedroom().walker().global_position.x
	Input.action_press(&"move_right")
	await wait_physics_frames(10)
	Input.action_release(&"move_right")
	assert_ne(_bedroom().walker().global_position.x, before, "the walker moves again")
