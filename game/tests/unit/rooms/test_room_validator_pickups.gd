extends GutTest
## RoomValidator, pedestals (story 5.2, AC 7): the treasure room needs a reachable item spot away from the doors.

const TREASURE: String = "res://rooms/pool/onset/onset_treasure_001.tscn"
const COMBAT: String = "res://rooms/pool/onset/onset_combat_001.tscn"


## The room of the scene edited in memory: the problems the validator reports for it.
func _problems_after(path: String, edit: Callable) -> PackedStringArray:
	var room: Room = (load(path) as PackedScene).instantiate() as Room
	edit.call(room)
	var problems: PackedStringArray = RoomValidator.validate_room(room, "mutant")
	room.free()
	return problems


func _spot(room: Room) -> PickupSpot:
	return room.pickup_spots()[0]


func _has_problem(problems: PackedStringArray, fragment: String) -> bool:
	for problem: String in problems:
		if problem.contains(fragment):
			return true
	return false


func test_the_treasure_room_of_the_pool_is_valid_and_has_an_item_spot() -> void:
	assert_eq(_problems_after(TREASURE, func(_room: Room) -> void: pass), PackedStringArray())
	var room: Room = (load(TREASURE) as PackedScene).instantiate() as Room
	assert_eq(room.pickup_spots().size(), 1)
	assert_eq(room.pickup_spots()[0].slot, PickupSpot.Slot.ITEM)
	room.free()


func test_a_treasure_room_without_spot_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(TREASURE, func(room: Room) -> void: _spot(room).free())
	assert_true(_has_problem(problems, "without an ITEM PickupSpot"), str(problems))


func test_a_treasure_room_with_only_a_heart_spot_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(TREASURE, func(room: Room) -> void: _spot(room).slot = PickupSpot.Slot.HEART)
	assert_true(_has_problem(problems, "without an ITEM PickupSpot"), str(problems))


func test_a_spot_on_a_wall_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(TREASURE, func(room: Room) -> void:
		var walls: TileMapLayer = room.get_node("Walls") as TileMapLayer
		walls.set_cell(Vector2i(18, 10), Room.TILE_WALL, Vector2i.ZERO)
		_spot(room).position = Vector2(18.5, 10.5) * Const.TILE_SIZE)
	assert_true(_has_problem(problems, "is on a wall"), str(problems))


func test_a_spot_near_a_door_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(TREASURE, func(room: Room) -> void:
		_spot(room).position = Vector2(19.0, 2.5) * Const.TILE_SIZE) # two tiles under the north door
	assert_true(_has_problem(problems, "tiles from the N door"), str(problems))


func test_a_spot_cut_off_from_the_doors_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(TREASURE, func(room: Room) -> void:
		var walls: TileMapLayer = room.get_node("Walls") as TileMapLayer
		for offset: Vector2i in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0),
				Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
			walls.set_cell(Vector2i(18, 10) + offset, Room.TILE_WALL, Vector2i.ZERO)
		_spot(room).position = Vector2(18.5, 10.5) * Const.TILE_SIZE)
	assert_true(_has_problem(problems, "cut off from the doors"), str(problems))


func test_a_spot_in_a_combat_room_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(COMBAT, func(room: Room) -> void:
		var spot: PickupSpot = PickupSpot.new()
		spot.name = "Spot"
		spot.position = Vector2(18.5, 9.5) * Const.TILE_SIZE
		var container: Node2D = Node2D.new() # a room built before the node existed has none
		container.name = "PickupSpots"
		room.add_child(container)
		container.add_child(spot))
	assert_true(_has_problem(problems, "not a treasure room"), str(problems))


func test_the_builder_reads_the_pickup_directive_and_reports_typos() -> void:
	var builder: RoomBuilder = RoomBuilder.new()
	var errors: PackedStringArray = PackedStringArray()
	var row: String = ".".repeat(36)
	var rows: PackedStringArray = PackedStringArray()
	for i: int in 19:
		rows.append(row)
	var grid: String = "\n".join(rows)
	var room: Room = builder.build("type: treasure\nsize: screen\n%s\ndoor N\npickup armor 3 4\npickup crown 1 1\npickup item x 1\n" % grid, errors)
	assert_eq(errors.size(), 2, str(errors))
	assert_eq(room.pickup_spots().size(), 1)
	assert_eq(room.pickup_spots()[0].slot, PickupSpot.Slot.ARMOR)
	room.free()
	builder.free()


const SHOP: String = "res://rooms/pool/onset/onset_shop_001.tscn"


func test_the_shop_of_the_pool_has_its_five_stalls_and_is_valid() -> void:
	assert_eq(_problems_after(SHOP, func(_room: Room) -> void: pass), PackedStringArray())
	var room: Room = (load(SHOP) as PackedScene).instantiate() as Room
	assert_eq(room.pickup_spots().size(), 5)
	room.free()


func test_a_shop_with_four_stalls_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(SHOP, func(room: Room) -> void:
		for spot: PickupSpot in room.pickup_spots():
			if spot.slot == PickupSpot.Slot.HEART:
				spot.free())
	assert_true(_has_problem(problems, "shop needs 1 HEART"), str(problems))


func test_a_shop_with_overlapping_stalls_is_refused() -> void:
	var problems: PackedStringArray = _problems_after(SHOP, func(room: Room) -> void:
		var spots: Array[PickupSpot] = room.pickup_spots()
		spots[1].position = spots[0].position)
	assert_true(_has_problem(problems, "overlaps"), str(problems))
