extends GutTest
## RoomValidator: the valid fixtures pass, each faulty one is reported for its own rule (story 4.2, AC 10).

const FIXTURES: String = "res://tests/fixtures/rooms/"


func _problems_of(fixture: String) -> PackedStringArray:
	return RoomValidator.validate(load(FIXTURES + fixture + ".tscn") as PackedScene)


func _assert_single_problem(fixture: String, fragment: String) -> void:
	var problems: PackedStringArray = _problems_of(fixture)
	assert_eq(problems.size(), 1, "%s: exactly one problem (%s)" % [fixture, problems])
	if problems.size() == 1:
		assert_string_contains(problems[0], fixture + ": ")
		assert_string_contains(problems[0], fragment)


func test_valid_combat_room_passes() -> void:
	assert_eq(_problems_of("valid"), PackedStringArray())


func test_start_room_needs_no_enemy_and_no_reinforcement() -> void:
	assert_eq(_problems_of("start_room"), PackedStringArray())


func test_wrong_dimensions_are_reported() -> void:
	_assert_single_problem("bad_size", "playable area is 30x10")


func test_room_without_door_is_reported() -> void:
	_assert_single_problem("no_door", "no door")


func test_enemy_too_close_to_a_door_is_reported() -> void:
	_assert_single_problem("spawn_near_door", "tiles from the N door")


func test_combat_room_without_reinforcement_is_reported() -> void:
	_assert_single_problem("no_reinforcement", "no ReinforcementSpawn")


func test_enemy_spawn_without_enemy_is_reported() -> void:
	_assert_single_problem("enemy_missing", "has no enemy")


func test_enemy_on_wall_obstacle_or_pit_is_reported() -> void:
	_assert_single_problem("enemy_on_wall", "is on a wall")
	_assert_single_problem("enemy_on_high_obstacle", "is on a high obstacle")
	_assert_single_problem("enemy_on_low_obstacle", "is on a low obstacle")
	_assert_single_problem("enemy_on_pit", "is on a pit")


func test_cells_outside_the_frame_are_reported() -> void:
	var room: Room = (load(FIXTURES + "valid.tscn") as PackedScene).instantiate() as Room
	(room.get_node("HighObstacles") as TileMapLayer).set_cell(Vector2i(40, 5), Room.TILE_HIGH_OBSTACLE, Vector2i.ZERO)
	(room.get_node("Walls") as TileMapLayer).set_cell(Vector2i(-1, 3), Room.TILE_WALL, Vector2i.ZERO)
	var problems: PackedStringArray = RoomValidator.validate_room(room, "mutant")
	room.free()
	assert_eq(problems.size(), 2, str(problems))
	assert_string_contains("\n".join(problems), "wall cell (-1, 3) outside the frame")
	assert_string_contains("\n".join(problems), "HighObstacles cell (40, 5) outside the playable area")


func test_the_nightmare_type_needs_no_reinforcement() -> void:
	var room: Room = (load(FIXTURES + "no_reinforcement.tscn") as PackedScene).instantiate() as Room
	room.room_type = Room.RoomType.NIGHTMARE
	var problems: PackedStringArray = RoomValidator.validate_room(room, "nightmare")
	room.free()
	assert_eq(problems, PackedStringArray())


func test_the_real_pool_is_valid_and_the_fixtures_are_not() -> void:
	var tool: ValidateRooms = ValidateRooms.new()
	assert_eq(tool.run("res://rooms/pool"), 0, "the pool passes")
	assert_ne(tool.run("res://tests/fixtures/rooms"), 0, "a pool holding faulty rooms fails")
	tool.free()


func test_room_info_reads_a_scene_and_scene_paths_are_sorted() -> void:
	var info: RoomInfo = RoomInfo.from_scene(load("res://rooms/pool/onset/onset_combat_001.tscn") as PackedScene)
	assert_eq(info.id, &"onset_combat_001")
	assert_eq(info.room_type, Room.RoomType.COMBAT)
	assert_eq(info.size_kind, Room.SizeKind.SCREEN)
	assert_eq(info.doors, [Door.Side.N, Door.Side.E, Door.Side.S, Door.Side.W] as Array[int])
	var paths: PackedStringArray = RoomInfo.scene_paths("res://rooms/pool")
	assert_eq(paths.size(), 6)
	var sorted: PackedStringArray = paths.duplicate()
	sorted.sort()
	assert_eq(paths, sorted)


func test_a_pit_wall_cutting_a_door_off_is_reported() -> void:
	_assert_single_problem("pits_cut_door", "the E door is cut off from the N door")


func test_an_enemy_marker_enclosed_by_pits_is_reported() -> void:
	_assert_single_problem("enemy_cut_off", "is cut off from the doors")


func test_a_reinforcement_marker_enclosed_by_pits_is_reported() -> void:
	_assert_single_problem("reinforcement_cut_off", "ReinforcementSpawn")


func test_a_player_spawn_enclosed_by_pits_is_reported() -> void:
	_assert_single_problem("player_cut_off", "player spawn is cut off from the doors")


func test_a_reinforcement_marker_on_a_pit_is_reported() -> void:
	_assert_single_problem("reinforcement_on_pit", "ReinforcementSpawn")


func test_the_pit_test_room_is_valid() -> void:
	assert_eq(RoomValidator.validate(load("res://rooms/pool/onset/onset_combat_004.tscn") as PackedScene), PackedStringArray())


func test_a_floor_hole_is_reported() -> void:
	_assert_single_problem("floor_hole", "1 playable cell(s) without floor")


func test_a_missing_frame_tile_is_reported() -> void:
	var room: Room = (load(FIXTURES + "valid.tscn") as PackedScene).instantiate() as Room
	(room.get_node("Walls") as TileMapLayer).erase_cell(Vector2i(10, 0))
	var problems: PackedStringArray = RoomValidator.validate_room(room, "mutant")
	room.free()
	assert_eq(problems, PackedStringArray(["mutant: frame wall missing at (10, 0)"]))


func test_a_reinforcement_marker_outside_the_grid_is_reported() -> void:
	var problems: PackedStringArray = _problems_of("reinforcement_outside")
	assert_eq(problems.size(), 1, str(problems))
	assert_string_contains("\n".join(problems), "ReinforcementSpawn")
	assert_string_contains("\n".join(problems), "outside the playable area")


func test_a_blocked_player_entry_cell_is_reported() -> void:
	_assert_single_problem("player_spawn_blocked", "player spawn at")


func test_two_doors_on_the_same_side_are_reported() -> void:
	var room: Room = (load(FIXTURES + "valid.tscn") as PackedScene).instantiate() as Room
	var twin: Door = (load("res://rooms/door.tscn") as PackedScene).instantiate() as Door
	twin.side = Door.Side.N
	room.get_node("Doors").add_child(twin)
	var problems: PackedStringArray = RoomValidator.validate_room(room, "mutant")
	room.free()
	assert_eq(problems, PackedStringArray(["mutant: two doors on the N side"]))


func test_a_wave_with_too_many_markers_is_reported() -> void:
	_assert_single_problem("wave_too_big", "wave 0 has 13 enemy markers")
