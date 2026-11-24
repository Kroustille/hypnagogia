extends GutTest
## run.json through a night (story 6.8): written at the start, erased at the end, never written outside a floor run.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _dir: SaveDir
var _main: Main


func before_each() -> void:
	_dir = SaveDir.new()
	Main.start_in_bedroom = false


func after_each() -> void:
	GameClock.paused = false
	Main.default_mode = RunOptions.Mode.FLOOR
	if _main != null:
		RoomLoader.collect_orphans(true)
		remove_child(_main)
		_main.queue_free()
		_main = null
	_dir.restore()


func _start_main() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _kill_player() -> void:
	var player: Player = get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player
	player.health.set_forced_invulnerability(false)
	player.health.half_hearts = 1
	player.hurtbox.receive(DamageInfo.from_bullet(1.0, Vector2.RIGHT, DamageInfo.Source.CONTACT))


func test_the_floor_run_writes_the_night_at_the_start() -> void:
	await _start_main()
	assert_true(SaveService.has_run())
	var snapshot: RunSnapshot = SaveService.read_run()
	assert_eq(snapshot.cell, _run().floor_layout.start)
	assert_eq(snapshot.state.run_seed, _run().state.run_seed)


func test_a_death_erases_the_night() -> void:
	await _start_main()
	_kill_player()
	assert_false(SaveService.has_run())


func test_a_victory_erases_the_night() -> void:
	await _start_main()
	Events.boss_defeated.emit(&"professor")
	await wait_physics_frames(roundi(Tuning.ROOM.boss_victory_delay * Engine.physics_ticks_per_second) + 20)
	assert_false(SaveService.has_run())


func test_a_new_run_erases_the_night_of_the_old_one() -> void:
	await _start_main()
	SaveService.write_run(SaveService.read_run()) # the night the player gave up
	Events.run_requested.emit(RunOptions.Mode.ARENA, -1, false, "")
	await wait_physics_frames(2)
	assert_false(SaveService.has_run(), "an arena run leaves nothing")


func test_an_arena_run_never_writes_the_night() -> void:
	Main.default_mode = RunOptions.Mode.ARENA
	await _start_main()
	assert_false(SaveService.has_run())
	assert_false(_run().is_resumable())


func test_the_pause_menu_says_save_and_quit_only_in_a_floor_run() -> void:
	await _start_main()
	var pause: PauseMenu = _main.find_children("*", "PauseMenu", true, false)[0] as PauseMenu
	pause.open("", PauseMenu.Focus.RESUME, _run().is_resumable())
	assert_eq((pause.get_node("%QuitButton") as Button).text, tr(&"UI_PAUSE_SAVE_QUIT"))
	pause.open("", PauseMenu.Focus.RESUME, false)
	assert_eq((pause.get_node("%QuitButton") as Button).text, tr(&"UI_PAUSE_QUIT"))
