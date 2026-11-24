extends GutTest
## The seed in the menus and in the run (story 4.11): shown in the pause menu and on the wake screen, typed in the seed
## window, a valid code restarts on it, an invalid one changes nothing.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const SEED: int = 12345

var _main: Main


func before_each() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await get_tree().process_frame


func after_each() -> void:
	remove_child(_main)
	_main.queue_free()


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _menu(menu_class: String) -> Control:
	for node: Node in _main.find_children("*", menu_class, true, false):
		return node as Control
	return null


func _press(action: StringName) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().process_frame
	await get_tree().process_frame


func _pause() -> PauseMenu:
	await _press(&"pause")
	return _menu("PauseMenu") as PauseMenu


func _label_text(menu: Control) -> String:
	return (menu.get_node("%SeedLabel") as Label).text


func _kill_player() -> void:
	var player: Player = get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player
	player.health.set_forced_invulnerability(false)
	player.health.half_hearts = 1
	player.hurtbox.receive(DamageInfo.from_bullet(1.0, Vector2.RIGHT, DamageInfo.Source.CONTACT))


func _open_seed_entry_from_pause() -> SeedEntry:
	var pause: PauseMenu = await _pause()
	(pause.get_node("%NewSeedButton") as Button).pressed.emit()
	return _menu("SeedEntry") as SeedEntry


func test_the_pause_menu_shows_the_seed_of_the_run() -> void:
	var pause: PauseMenu = await _pause()
	assert_true(pause.visible)
	assert_eq(_label_text(pause), tr(&"UI_PAUSE_SEED") % _run().rng.seed_code())
	assert_eq(_run().rng.seed_code().length(), 8)


func test_the_wake_screen_shows_the_seed_of_the_run_that_ended() -> void:
	var code: String = _run().rng.seed_code()
	_kill_player()
	var wake: WakeScreen = _menu("WakeScreen") as WakeScreen
	assert_true(wake.visible)
	assert_eq(_label_text(wake), tr(&"UI_WAKE_SEED") % code)


func test_a_run_without_a_typed_seed_is_not_seeded() -> void:
	assert_false(_run().state.seeded)


func test_a_valid_code_from_the_pause_menu_starts_a_seeded_run_on_it() -> void:
	var old_run: Run = _run()
	var entry: SeedEntry = await _open_seed_entry_from_pause()
	assert_true(entry.visible)
	entry.set_text("0000-0c1s")
	entry.submit()
	await get_tree().process_frame
	await get_tree().process_frame
	var run: Run = _run()
	assert_ne(run, old_run)
	assert_eq(run.state.run_seed, SEED)
	assert_true(run.state.seeded)
	assert_eq(run.rng.seed_code(), "00000C1S")
	assert_false(GameClock.paused, "the game runs")
	assert_false(_menu("PauseMenu").visible)
	assert_false(entry.visible)


func test_a_valid_code_from_the_wake_screen_starts_a_seeded_run() -> void:
	_kill_player()
	var wake: WakeScreen = _menu("WakeScreen") as WakeScreen
	for i: int in 30:
		await get_tree().physics_frame # the input guard of the screen
	(wake.get_node("%NewSeedButton") as Button).pressed.emit()
	var entry: SeedEntry = _menu("SeedEntry") as SeedEntry
	assert_true(entry.visible)
	entry.set_text("00000C1S")
	entry.submit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_run().state.run_seed, SEED)
	assert_true(_run().state.seeded)
	assert_false(wake.visible)
	assert_false(entry.visible)
	assert_false(GameClock.paused)


func test_an_invalid_code_starts_nothing_and_leaves_the_pause_intact() -> void:
	var old_run: Run = _run()
	var entry: SeedEntry = await _open_seed_entry_from_pause()
	entry.set_text("1234")
	entry.submit()
	await get_tree().process_frame
	assert_eq(_run(), old_run, "same run")
	assert_true(entry.visible)
	assert_eq(entry.error_text(), tr(&"UI_SEED_INVALID"))
	assert_true(GameClock.paused, "still paused")
	assert_false(old_run.state.seeded)


func test_escape_closes_the_window_only_and_gives_back_the_pause_menu() -> void:
	var entry: SeedEntry = await _open_seed_entry_from_pause()
	await _press(&"ui_cancel")
	assert_false(entry.visible)
	assert_true(_menu("PauseMenu").visible, "the pause menu is back")
	assert_true(GameClock.paused, "the game is still paused")


func test_a_restart_after_a_typed_seed_draws_a_new_seed() -> void:
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED, true, "")
	await get_tree().process_frame
	assert_true(_run().state.seeded)
	_kill_player()
	var wake: WakeScreen = _menu("WakeScreen") as WakeScreen
	for i: int in 30:
		await get_tree().physics_frame
	wake.restart_requested.emit()
	await get_tree().process_frame
	assert_false(_run().state.seeded)
	assert_ne(_run().state.run_seed, SEED)


func test_the_same_code_gives_the_same_floor_and_start_room_and_another_code_another_floor() -> void:
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED, true, "")
	await get_tree().process_frame
	var first: Run = _run()
	var signature: String = first.floor_layout.signature()
	var start_room: String = first.current_room().scene_file_path
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED, true, "")
	await get_tree().process_frame
	var second: Run = _run()
	assert_ne(second, first)
	assert_eq(second.floor_layout.signature(), signature)
	assert_eq(second.current_room().scene_file_path, start_room)
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED + 1, true, "")
	await get_tree().process_frame
	assert_ne(_run().floor_layout.signature(), signature)


func test_a_bad_room_falls_back_to_the_arena_and_is_not_replayed() -> void:
	Events.run_requested.emit(RunOptions.Mode.ROOM, 0, false, "res://main/main.gd")
	await get_tree().process_frame
	assert_push_error_count(2)
	assert_true(_run().current_room() is Arena, "the arena takes over")
	_kill_player()
	var wake: WakeScreen = _menu("WakeScreen") as WakeScreen
	for i: int in 30:
		await get_tree().physics_frame
	wake.restart_requested.emit()
	await get_tree().process_frame
	assert_eq(_run().played_options().mode, RunOptions.Mode.ARENA)
	assert_true(_run().current_room() is Arena)


func test_a_room_scene_without_room_root_does_not_leak_a_node() -> void:
	var before: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	Events.run_requested.emit(RunOptions.Mode.ROOM, 0, false, "res://ui/menus/pause_menu.tscn")
	await get_tree().process_frame
	assert_push_error_count(2)
	assert_true(_run().current_room() is Arena)
	assert_lt(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)) - before, 400, "no stray scene left over")


func _key(keycode: Key, unicode: int = 0) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.keycode = keycode
		event.physical_keycode = keycode
		event.unicode = unicode
		event.pressed = pressed
		Input.parse_input_event(event)
		await get_tree().process_frame
	await get_tree().process_frame


func test_letters_typed_after_an_invalid_enter_reach_the_field() -> void:
	var entry: SeedEntry = await _open_seed_entry_from_pause()
	var field: LineEdit = entry.get_node("%Field") as LineEdit
	await _key(KEY_1, "1".unicode_at(0))
	await _key(KEY_ENTER)
	assert_eq(entry.error_text(), tr(&"UI_SEED_INVALID"))
	await _key(KEY_A, "a".unicode_at(0))
	assert_eq(field.text, "a", "the invalid code was selected, the next letter replaces it")
	assert_eq(entry.error_text(), "")


func test_a_single_real_escape_closes_the_window_and_keeps_the_pause() -> void:
	var entry: SeedEntry = await _open_seed_entry_from_pause()
	await _key(KEY_ESCAPE)
	assert_false(entry.visible)
	assert_true(_menu("PauseMenu").visible)
	assert_true(GameClock.paused)


func test_a_new_floor_does_not_wait_for_the_loads_of_the_previous_run() -> void:
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED, true, "")
	Events.run_requested.emit(RunOptions.Mode.FLOOR, SEED + 1, true, "") # the first one leaves loads in progress
	await get_tree().process_frame
	assert_not_null(_run().floor_layout)
	assert_gt(RoomLoader.orphan_count(), 0, "the new floor did not wait for the old requests")


func test_an_adopted_orphan_leaves_no_token_in_the_resource_loader() -> void:
	var paths: PackedStringArray = RoomInfo.scene_paths("res://rooms/pool/onset")
	var first: RoomLoader = RoomLoader.new()
	first.request_all(paths)
	first.drain()
	var second: RoomLoader = RoomLoader.new()
	second.request_all(paths)
	# Adopted, not requested twice (a second request would hold a token no get collects: a leak warning at exit).
	assert_eq(RoomLoader.orphan_count(), 0, "every past request is adopted or collected")
	for path: String in paths:
		assert_not_null(second.scene_for(path), path)
	assert_eq(second.pending_count(), 0)
	RoomLoader.collect_orphans(true)


func _debug_panel() -> DebugPanel:
	for node: Node in _main.find_children("*", "DebugPanel", true, false):
		return node as DebugPanel
	return null


func test_the_f1_replay_commands() -> void:
	var panel: DebugPanel = _debug_panel()
	if panel == null:
		pending("no debug panel in this build")
		return
	var requests: Array = []
	var on_request: Callable = func(mode: int, seed_value: int, seeded: bool, room: String) -> void:
		requests.append([mode, seed_value, seeded, room])
	Events.run_requested.connect(on_request)
	assert_false(panel.replay_seed_code("not a cod!"))
	assert_eq(requests.size(), 0, "an invalid code requests nothing")
	assert_true(panel.replay_seed_code("00000C1S\r\n"))
	assert_eq(requests, [[RunOptions.Mode.FLOOR, SEED, true, ""]])
	requests.clear()
	panel.replay_current_seed()
	assert_eq(requests, [[RunOptions.Mode.FLOOR, _run().state.run_seed, true, ""]])
	Events.run_requested.disconnect(on_request)
