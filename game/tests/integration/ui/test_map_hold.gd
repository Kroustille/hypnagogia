extends GutTest
## The map is held, not toggled, and never pauses the game (story 4.9, AC 1, 6, 7).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _main: Main
var _view: FloorMapView


func before_each() -> void:
	Main.default_mode = RunOptions.Mode.FLOOR
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)
	_view = _main.find_child("FloorMapView", true, false) as FloorMapView


func after_each() -> void:
	Input.action_release(&"map")
	remove_child(_main)
	_main.queue_free()


func test_the_map_action_exists_on_tab_and_select() -> void:
	assert_true(InputMap.has_action(&"map"))
	var keys: Array[int] = []
	var buttons: Array[int] = []
	for event: InputEvent in InputMap.action_get_events(&"map"):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
		elif event is InputEventJoypadButton:
			buttons.append((event as InputEventJoypadButton).button_index)
	assert_eq(keys, [KEY_TAB] as Array[int])
	assert_eq(buttons, [JOY_BUTTON_BACK] as Array[int])


func test_holding_shows_the_map_and_releasing_hides_it_without_pausing() -> void:
	assert_not_null(_view)
	assert_false(_view.visible)
	Input.action_press(&"map")
	await wait_physics_frames(2)
	assert_true(_view.visible)
	assert_false(GameClock.paused)
	Input.action_release(&"map")
	await wait_physics_frames(2)
	assert_false(_view.visible)


func test_the_game_keeps_running_while_the_map_is_open() -> void:
	Input.action_press(&"map")
	await wait_physics_frames(2)
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)
	var active: Node = _main.find_child("ActiveScene", true, false)
	assert_ne(active.process_mode, Node.PROCESS_MODE_DISABLED)


func test_the_map_stays_hidden_while_paused() -> void:
	GameClock.paused = true
	Input.action_press(&"map")
	await wait_physics_frames(2)
	assert_false(_view.visible)
	GameClock.paused = false


func test_the_map_stays_hidden_in_the_arena() -> void:
	Input.action_release(&"map")
	Main.default_mode = RunOptions.Mode.ARENA
	remove_child(_main)
	_main.queue_free()
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)
	_view = _main.find_child("FloorMapView", true, false) as FloorMapView
	Input.action_press(&"map")
	await wait_physics_frames(2)
	assert_false(_view.visible)
	Main.default_mode = RunOptions.Mode.FLOOR
