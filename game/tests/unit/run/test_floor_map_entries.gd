extends GutTest
## What the map shows (story 4.9, AC 2 to 4): visited rooms, unexplored rooms behind a door, icons, cleared, current.

const A: Vector2i = Vector2i(0, 0)
const B: Vector2i = Vector2i(1, 0)
const C: Vector2i = Vector2i(2, 0)
const D: Vector2i = Vector2i(0, 1) # next to A on the grid, no door between them
const E: Vector2i = Vector2i(2, 1)

var _map: FloorMap


func before_each() -> void:
	# A - B - C, E under C (door), D under A (no door).
	var layout: FloorLayout = FloorLayout.new()
	layout.valid = true
	layout.start = A
	layout.add_cell(A, Room.RoomType.START)
	layout.add_cell(B, Room.RoomType.COMBAT)
	layout.add_cell(C, Room.RoomType.TREASURE)
	layout.add_cell(D, Room.RoomType.SHOP)
	layout.add_cell(E, Room.RoomType.NIGHTMARE)
	layout.connect_cells(A, B)
	layout.connect_cells(B, C)
	layout.connect_cells(C, E)
	var wide: RoomInfo = RoomInfo.new()
	wide.size_kind = Room.SizeKind.WIDE
	layout.cells[B].info = wide
	_map = FloorMap.new()
	_map.layout = layout


func _entry(cell: Vector2i) -> Dictionary:
	for entry: Dictionary in _map.entries():
		if entry[&"cell"] == cell:
			return entry
	return {}


func _int(cell: Vector2i, key: StringName) -> int:
	var value: int = _entry(cell)[key]
	return value


func _bool(cell: Vector2i, key: StringName) -> bool:
	var value: bool = _entry(cell)[key]
	return value


func _links(cell: Vector2i) -> Array[Vector2i]:
	var value: Array[Vector2i] = _entry(cell)[&"links"]
	return value


func _cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for entry: Dictionary in _map.entries():
		cells.append(entry[&"cell"])
	return cells


func test_nothing_is_shown_before_the_first_room_or_without_a_floor() -> void:
	assert_eq(_map.entries().size(), 0)
	assert_eq(FloorMap.new().entries().size(), 0)


func test_the_start_room_and_the_room_behind_its_door_only() -> void:
	_map.mark_entered(A)
	assert_eq(_cells(), [A, B] as Array[Vector2i], "D touches A on the grid but has no door")
	assert_eq(_int(A, &"state"), FloorMap.State.VISITED)
	assert_eq(_int(B, &"state"), FloorMap.State.UNEXPLORED)
	assert_true(_bool(A, &"current"))
	assert_false(_bool(B, &"current"))
	assert_eq(_links(A), [B] as Array[Vector2i])
	assert_eq(_links(B), [A] as Array[Vector2i], "a link between a visited and an unexplored room is drawn")


func test_three_rooms_visited() -> void:
	_map.mark_entered(A)
	_map.mark_entered(B)
	_map.mark_entered(C)
	assert_eq(_cells(), [A, B, C, E] as Array[Vector2i])
	assert_eq(_int(E, &"state"), FloorMap.State.UNEXPLORED)
	assert_eq(_bool(C, &"current"), true)
	assert_false(_bool(A, &"current"))
	assert_eq(_links(C), [B, E] as Array[Vector2i])


func test_special_rooms_carry_their_type_once_discovered() -> void:
	_map.mark_entered(B)
	assert_eq(_int(C, &"type"), Room.RoomType.TREASURE, "next to a visited room: the icon is known")
	assert_false(_cells().has(E), "two doors away: unknown")


func test_a_cleared_room_is_marked() -> void:
	_map.mark_entered(A)
	_map.mark_entered(B)
	_map.mark_cleared(B)
	assert_true(_bool(B, &"cleared"))
	assert_false(_bool(A, &"cleared"))


func test_a_big_room_is_one_cell_with_its_size_kind() -> void:
	_map.mark_entered(B)
	assert_eq(_int(B, &"size_kind"), Room.SizeKind.WIDE)
	assert_eq(_int(A, &"size_kind"), Room.SizeKind.SCREEN, "a room without info counts as one screen")


func test_the_entries_are_sorted_by_row_then_column() -> void:
	_map.mark_entered(C)
	_map.mark_entered(B)
	assert_eq(_cells(), [A, B, C, E] as Array[Vector2i])


func test_the_bounds_cover_the_whole_floor() -> void:
	assert_eq(_map.bounds(), Rect2i(0, 0, 3, 2))


func test_the_bounds_are_the_fixed_generation_grid() -> void:
	_map.layout.grid = Rect2i(-1, -1, 7, 5)
	assert_eq(_map.bounds(), Rect2i(-1, -1, 7, 5))
	_map.mark_entered(B)
	assert_eq(_map.bounds(), Rect2i(-1, -1, 7, 5), "stable while the map fills up")
