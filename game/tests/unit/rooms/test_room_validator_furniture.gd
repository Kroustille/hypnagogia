extends GutTest
## RoomValidator, furniture and triggers (story 4.4, AC 8): each faulty fixture is reported for its own rule.

const FIXTURES: String = "res://tests/fixtures/rooms/"


func _problems_of(fixture: String) -> PackedStringArray:
	return RoomValidator.validate(load(FIXTURES + fixture + ".tscn") as PackedScene)


func _assert_single_problem(fixture: String, fragment: String) -> void:
	var problems: PackedStringArray = _problems_of(fixture)
	assert_eq(problems.size(), 1, "%s: exactly one problem (%s)" % [fixture, problems])
	if problems.size() == 1:
		assert_string_contains(problems[0], fixture + ": ")
		assert_string_contains(problems[0], fragment)


## The room with furniture, edited in memory: the problems the validator reports for it.
func _problems_after(edit: Callable) -> PackedStringArray:
	var room: Room = (load(FIXTURES + "furniture_room.tscn") as PackedScene).instantiate() as Room
	edit.call(room)
	var problems: PackedStringArray = RoomValidator.validate_room(room, "mutant")
	room.free()
	return problems


func test_the_furniture_room_is_valid() -> void:
	assert_eq(_problems_of("furniture_room"), PackedStringArray())


func test_the_furniture_test_room_of_the_pool_is_valid_and_complete() -> void:
	var scene: PackedScene = load("res://rooms/pool/onset/onset_combat_005.tscn") as PackedScene
	assert_eq(RoomValidator.validate(scene), PackedStringArray())
	var room: Room = scene.instantiate() as Room
	var ids: Array[StringName] = []
	for piece: Furniture in room.furnitures():
		ids.append(piece.def.id)
	assert_true(ids.has(&"bed") and ids.has(&"chair") and ids.has(&"desk"), "bed, chair and desk: %s" % [ids])
	assert_eq(room.triggers().size(), 1, "one lamp")
	var waves: Dictionary = {}
	for spawn: EnemySpawn in room.enemy_spawns():
		waves[spawn.wave] = true
	assert_eq(waves.size(), 2, "two waves")
	room.free()


func test_furniture_without_def_is_reported() -> void:
	_assert_single_problem("furniture_no_def", "has no def")


func test_furniture_outside_the_playable_area_is_reported() -> void:
	_assert_single_problem("furniture_outside", "is outside the playable area")


func test_overlapping_furniture_is_reported() -> void:
	_assert_single_problem("furniture_overlap", "overlaps Furniture")


func test_furniture_on_a_wall_obstacle_or_pit_is_reported() -> void:
	var cases: Dictionary = {
		"Walls": ["is on a wall", Room.TILE_WALL], "HighObstacles": ["is on a high obstacle", Room.TILE_HIGH_OBSTACLE],
		"LowObstacles": ["is on a low obstacle", Room.TILE_LOW_OBSTACLE], "Pits": ["is on a pit", Room.TILE_PIT],
	}
	for layer_name: String in cases:
		var expected: String = cases[layer_name][0]
		var tile: int = cases[layer_name][1]
		var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
			# the desk of the fixture covers tiles (10, 12) and (11, 12)
			(room.get_node(layer_name) as TileMapLayer).set_cell(Vector2i(12, 13), tile, Vector2i.ZERO))
		assert_eq(problems.size(), 1, "%s: %s" % [layer_name, problems])
		if problems.size() == 1:
			assert_string_contains(problems[0], expected)
			assert_string_contains(problems[0], "Furniture")


func test_furniture_cutting_a_door_is_reported() -> void:
	_assert_single_problem("furniture_cuts_door", "door is cut off from the")


func test_furniture_cutting_an_enemy_marker_is_reported() -> void:
	_assert_single_problem("furniture_cuts_enemy", "is cut off from the doors")


func test_a_marker_on_furniture_is_reported() -> void:
	var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
		var spawn: EnemySpawn = EnemySpawn.new()
		spawn.name = "OnBed"
		spawn.enemy = load("res://data/enemies/sleepwalker.tres") as EnemyDef
		spawn.position = (Vector2(5, 4) + Vector2(1.5, 1.5)) * Const.TILE_SIZE # a tile of the bed
		room.get_node("EnemySpawns").add_child(spawn))
	assert_true("\n".join(problems).contains("is on a furniture"), str(problems))


func test_trigger_without_kind_is_reported() -> void:
	_assert_single_problem("trigger_no_kind", "has no kind")


func test_trigger_with_an_unknown_kind_is_reported() -> void:
	var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
		room.triggers()[0].kind = &"fountain")
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "unknown kind")


func test_furniture_with_an_invalid_size_is_reported() -> void:
	var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
		var piece: Furniture = room.furnitures()[0]
		piece.def = piece.def.duplicate() as FurnitureDef # never edit the shared resource
		piece.def.size = Vector2i(0, 1))
	assert_eq(problems.size(), 1, str(problems))
	if problems.size() == 1:
		assert_string_contains(problems[0], "has an invalid size")


func test_furniture_with_invalid_max_hp_is_reported() -> void:
	for bad: float in [0.0, -5.0, INF, NAN]:
		var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
			var piece: Furniture = room.furnitures()[0]
			piece.def = piece.def.duplicate() as FurnitureDef
			piece.def.max_hp = bad)
		assert_eq(problems.size(), 1, "max_hp %s: %s" % [bad, problems])
		if problems.size() == 1:
			assert_string_contains(problems[0], "has invalid max_hp")


func test_furniture_off_a_tile_center_is_reported() -> void:
	for shift: Vector2 in [Vector2(8, 0), Vector2(0, -8), Vector2(3, 0)]:
		var problems: PackedStringArray = _problems_after(func(room: Room) -> void:
			room.furnitures()[0].position += shift)
		assert_eq(problems.size(), 1, "shift %s: %s" % [shift, problems])
		if problems.size() == 1:
			assert_string_contains(problems[0], "is not on a tile center")
