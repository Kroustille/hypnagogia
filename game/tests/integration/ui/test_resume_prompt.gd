extends GutTest
## The resume prompt at launch (story 6.8).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _dir: SaveDir
var _main: Main


func before_each() -> void:
	_dir = SaveDir.new()


func after_each() -> void:
	GameClock.paused = false
	Main.start_in_bedroom = false
	if _main != null:
		RoomLoader.collect_orphans(true)
		remove_child(_main)
		_main.queue_free()
		_main = null
	_dir.restore()


## A real night: a first Main plays the start room and writes run.json, then goes away.
func _leave_a_night() -> void:
	Main.start_in_bedroom = false
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)
	remove_child(_main)
	_main.queue_free()
	_main = null
	await wait_physics_frames(2)
	assert_true(SaveService.has_run())


func _launch() -> void:
	Main.start_in_bedroom = true
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func _prompt() -> ResumePrompt:
	return _main.find_children("*", "ResumePrompt", true, false)[0] as ResumePrompt


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func test_no_prompt_without_a_saved_night() -> void:
	await _launch()
	assert_false(_prompt().visible)
	assert_false(GameClock.paused)


func test_a_saved_night_is_offered_with_resume_focused() -> void:
	await _leave_a_night()
	await _launch()
	assert_true(_prompt().visible)
	assert_true(GameClock.paused, "the game waits behind the prompt")
	assert_true((_prompt().get_node("%ResumeButton") as Button).has_focus())
	assert_eq((_prompt().get_node("%Title") as Label).text, tr(&"UI_RESUME_TITLE"))


func test_resume_continues_the_night_and_erases_then_rewrites_the_file() -> void:
	await _leave_a_night()
	var saved: RunSnapshot = SaveService.read_run()
	await _launch()
	(_prompt().get_node("%ResumeButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_false(_prompt().visible)
	assert_false(GameClock.paused)
	assert_eq(_run().state.run_seed, saved.state.run_seed)
	assert_eq(_run().current_cell(), saved.cell)
	assert_true(SaveService.has_run(), "written again at the entry of the room")


func test_new_night_erases_the_file_and_leaves_the_bedroom() -> void:
	await _leave_a_night()
	await _launch()
	(_prompt().get_node("%NewNightButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_false(_prompt().visible)
	assert_false(SaveService.has_run())
	assert_false(GameClock.paused)
	assert_null(_run(), "the bedroom, not a run")


func test_a_broken_file_is_set_aside_with_a_notice() -> void:
	var file: FileAccess = FileAccess.open(_dir.file("run.json"), FileAccess.WRITE)
	file.store_string("{ broken")
	file.close()
	await _launch()
	assert_false(_prompt().visible)
	assert_true(FileAccess.file_exists(_dir.file("run.json.corrupt")))
	assert_false(SaveService.has_run())
	var notice: Notice = _main.find_children("*", "Notice", true, false)[0] as Notice
	assert_true(notice.visible)


func test_a_night_pointing_outside_the_floor_is_set_aside() -> void:
	await _leave_a_night()
	var snapshot: RunSnapshot = SaveService.read_run()
	snapshot.cell = Vector2i(999, 999)
	SaveService.write_run(snapshot)
	await _launch()
	assert_false(_prompt().visible)
	assert_true(FileAccess.file_exists(_dir.file("run.json.corrupt")))
