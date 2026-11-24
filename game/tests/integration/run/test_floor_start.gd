extends GutTest
## A new game plays the floor (story 4.8, AC 1, 7, 8): the start room is calm, shows the controls help, the other rooms load
## in the background, and the main scene starts on the floor by default.

const SEED: int = 777

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func test_the_main_scene_plays_the_floor_by_default() -> void:
	assert_eq(Main.default_mode, RunOptions.Mode.FLOOR)


func test_the_start_room_is_calm_and_shows_the_controls() -> void:
	_harness.start_floor(SEED)
	var room: Room = _harness.run.current_room()
	assert_eq(room.room_type, Room.RoomType.START)
	assert_eq(room.alive_enemy_count(), 0)
	assert_false(room.has_fight(), "no wave in the start room")
	var tutorials: Array[Node] = room.get_children().filter(func(child: Node) -> bool: return child is ControlsTutorial)
	assert_eq(tutorials.size(), 1, "one controls help in the start room of the first floor")
	var tutorial: ControlsTutorial = tutorials[0] as ControlsTutorial
	assert_string_contains(tutorial.line_text(0), "Se déplacer")


func test_the_start_room_is_entered_in_the_middle_with_every_door_free_to_use() -> void:
	_harness.start_floor(SEED)
	var run: Run = _harness.run
	var room: Room = run.current_room()
	assert_eq(_harness.player.global_position, room.to_global(room.frame_px() / 2.0))
	assert_eq(run.floor_map.current, run.floor_layout.start)
	assert_eq(run.floor_map.visited.size(), 1)


func test_the_other_rooms_load_in_the_background_and_the_run_collects_them() -> void:
	_harness.start_floor(SEED)
	var run: Run = _harness.run
	var loader: RoomLoader = run.room_loader()
	assert_not_null(loader)
	var distinct: Dictionary[String, bool] = {}
	for placement: FloorLayout.Placement in run.floor_layout.cells.values():
		distinct[placement.info.path] = true
	assert_eq(loader.pending_count(), distinct.size() - 1, "every room but the start room was requested")
	var waited: int = 0
	while waited < 300:
		var all_ready: bool = true
		for path: String in distinct:
			all_ready = all_ready and (path == run.current_room().scene_file_path or loader.is_ready(path))
		if all_ready:
			break
		waited += 1
		await get_tree().process_frame
	for path: String in distinct:
		assert_true(path == run.current_room().scene_file_path or loader.is_ready(path), path)


func test_a_room_requested_as_the_arena_has_no_floor() -> void:
	var options: RunOptions = RunOptions.new()
	options.mode = RunOptions.Mode.ARENA
	var run: Run = (load("res://run/run.tscn") as PackedScene).instantiate() as Run
	run.setup(options)
	_harness.add_child(run)
	assert_true(run.current_room() is Arena)
	assert_null(run.floor_layout)
	assert_null(run.room_loader())


func test_the_tutorial_only_shows_in_the_start_room() -> void:
	_harness.start_floor(SEED)
	var run: Run = _harness.run
	var layout: FloorLayout = run.floor_layout
	var side: int = layout.door_sides(layout.start)[0]
	run.travel(side)
	var other: Room = run.current_room()
	assert_eq(other.get_children().filter(func(child: Node) -> bool: return child is ControlsTutorial).size(), 0)
	run.travel((side + 2) % 4)
	assert_eq(run.current_room().get_children().filter(func(child: Node) -> bool: return child is ControlsTutorial).size(), 1, "back in the start room: the help is there")
