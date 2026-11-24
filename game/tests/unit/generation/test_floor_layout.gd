extends GutTest
## FloorLayout (story 4.7): neighbours, door sides, distance, text and signature, all independent of insertion order.

## A small floor:  S - C - T   with a C under S joined to the first C.
##                 |   |
##                 C - C
func _layout(reversed: bool) -> FloorLayout:
	var layout: FloorLayout = FloorLayout.new()
	var cells: Array = [
		[Vector2i(0, 0), Room.RoomType.START], [Vector2i(1, 0), Room.RoomType.COMBAT],
		[Vector2i(2, 0), Room.RoomType.TREASURE], [Vector2i(0, 1), Room.RoomType.COMBAT],
		[Vector2i(1, 1), Room.RoomType.COMBAT],
	]
	var links: Array = [
		[Vector2i(0, 0), Vector2i(1, 0)], [Vector2i(1, 0), Vector2i(2, 0)], [Vector2i(0, 0), Vector2i(0, 1)],
		[Vector2i(0, 1), Vector2i(1, 1)], [Vector2i(1, 1), Vector2i(1, 0)],
	]
	if reversed:
		cells.reverse()
		links.reverse()
	for entry: Array in cells:
		var cell: Vector2i = entry[0]
		var room_type: Room.RoomType = entry[1]
		layout.add_cell(cell, room_type)
	for link: Array in links:
		var a: Vector2i = link[0]
		var b: Vector2i = link[1]
		layout.connect_cells(a, b)
	layout.valid = true
	return layout


func test_neighbors_and_cells_are_sorted_whatever_the_insertion_order() -> void:
	for reversed: bool in [false, true]:
		var layout: FloorLayout = _layout(reversed)
		assert_eq(layout.sorted_cells(), [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1)])
		assert_eq(layout.neighbors(Vector2i(1, 0)), [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1)])


func test_door_sides_face_the_neighbors() -> void:
	var layout: FloorLayout = _layout(false)
	assert_eq(layout.door_sides(Vector2i(0, 0)), [Door.Side.E, Door.Side.S])
	assert_eq(layout.door_sides(Vector2i(1, 0)), [Door.Side.E, Door.Side.S, Door.Side.W])
	assert_eq(layout.door_sides(Vector2i(2, 0)), [Door.Side.W])
	assert_eq(FloorLayout.side_towards(Vector2i(1, 1), Vector2i(1, 0)), Door.Side.N)


func test_distance_counts_connections() -> void:
	var layout: FloorLayout = _layout(false)
	assert_eq(layout.distance(Vector2i(0, 0), Vector2i(0, 0)), 0)
	assert_eq(layout.distance(Vector2i(0, 0), Vector2i(2, 0)), 2)
	assert_eq(layout.distance(Vector2i(0, 1), Vector2i(2, 0)), 3, "by the shortest of the two ways")
	assert_eq(layout.distance(Vector2i(0, 0), Vector2i(7, 7)), -1, "unknown cell")


func test_edges_are_listed_once_and_sorted() -> void:
	var layout: FloorLayout = _layout(true)
	assert_eq(layout.edges().size(), 5)
	assert_eq(layout.edges()[0], [Vector2i(0, 0), Vector2i(1, 0)])


func test_text_map() -> void:
	assert_eq(_layout(false).to_text(), "S-C-T\n| |\nC-C")


func test_signature_does_not_depend_on_insertion_order_and_names_the_rooms() -> void:
	var one: FloorLayout = _layout(false)
	var two: FloorLayout = _layout(true)
	for layout: FloorLayout in [one, two]:
		for cell: Vector2i in layout.cells:
			layout.cells[cell].info = FakePool.make("room_%d_%d" % [cell.x, cell.y], layout.cells[cell].room_type, FakePool.ALL_DOORS)
	assert_eq(one.signature(), two.signature())
	assert_true(one.signature().contains("1,0=room_1_0"))
	two.cells[Vector2i(1, 1)].info = FakePool.make("other", Room.RoomType.COMBAT, FakePool.ALL_DOORS)
	assert_ne(one.signature(), two.signature(), "another room is another floor")


func test_an_invalid_layout_has_the_signature_invalid() -> void:
	assert_eq(FloorLayout.new().signature(), "invalid")
