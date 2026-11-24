class_name RoomValidator
extends RefCounted
## Checks the shape of a pre-drawn room (story 4.2): dimensions, doors, enemy and reinforcement markers. Pure: it only
## reads the scene, never adds it to the tree. One problem per line, "<room id>: <problem>"; an empty result means the
## room is valid. The checks of later stories (pits, furniture, large rooms) join this class.

## Enemies never appear closer than this to a door, in tiles (the player may enter there), even when the door ends up sealed.
const MIN_SPAWN_DOOR_DISTANCE_TILES: float = 3.0
## Room types that may have no reinforcement marker: they hold no enemy, or (nightmare) the GDD forbids reinforcements.
const REINFORCEMENT_FREE_TYPES: Array[Room.RoomType] = [
	Room.RoomType.START, Room.RoomType.TREASURE, Room.RoomType.SHOP, Room.RoomType.NIGHTMARE,
]


## Problems of a room scene. A scene whose root is not a Room is reported, not crashed on.
static func validate(scene: PackedScene) -> PackedStringArray:
	var id: String = scene.resource_path.get_file().get_basename()
	var node: Node = scene.instantiate()
	var room: Room = node as Room
	if room == null:
		node.free()
		return PackedStringArray(["%s: root is not a Room" % id])
	var problems: PackedStringArray = validate_room(room, id)
	room.free()
	return problems


## Problems of an instantiated room (outside the tree).
static func validate_room(room: Room, id: String) -> PackedStringArray:
	var problems: PackedStringArray = PackedStringArray()
	var playable: Vector2i = room.playable_tiles()
	var frame: Vector2i = playable + Vector2i(2, 2)
	_check_layout(room, playable, frame, problems)
	var doors: Array[Door] = room.doors()
	if doors.is_empty():
		problems.append("no door")
	_check_enemies(room, playable, frame, doors, problems)
	_check_reinforcements(room, problems)
	var tagged: PackedStringArray = PackedStringArray()
	for problem: String in problems:
		tagged.append("%s: %s" % [id, problem])
	return tagged


static func _check_layout(room: Room, playable: Vector2i, frame: Vector2i, problems: PackedStringArray) -> void:
	var floor_layer: TileMapLayer = _layer(room, "Floor")
	var walls: TileMapLayer = _layer(room, "Walls")
	if floor_layer == null or walls == null:
		problems.append("Floor or Walls layer missing")
		return
	var floor_rect: Rect2i = floor_layer.get_used_rect()
	if floor_rect.size != playable or floor_rect.position != Vector2i.ONE:
		problems.append("playable area is %dx%d tiles at %s, expected %dx%d at (1, 1)" % [
			floor_rect.size.x, floor_rect.size.y, floor_rect.position, playable.x, playable.y])
	var frame_rect: Rect2i = Rect2i(Vector2i.ZERO, frame)
	var playable_rect: Rect2i = Rect2i(Vector2i.ONE, playable)
	for cell: Vector2i in walls.get_used_cells():
		if not frame_rect.has_point(cell):
			problems.append("wall cell %s outside the frame" % cell)
	for layer_name: String in ["Floor", "LowObstacles", "HighObstacles", "Pits"]:
		var layer: TileMapLayer = _layer(room, layer_name)
		if layer == null:
			continue
		for cell: Vector2i in layer.get_used_cells():
			if not playable_rect.has_point(cell):
				problems.append("%s cell %s outside the playable area" % [layer_name, cell])


static func _check_enemies(room: Room, playable: Vector2i, frame: Vector2i, doors: Array[Door], problems: PackedStringArray) -> void:
	var spawns: Array[EnemySpawn] = room.enemy_spawns()
	if spawns.is_empty() and room.room_type == Room.RoomType.COMBAT:
		problems.append("combat room without EnemySpawn")
	var playable_rect: Rect2i = Rect2i(Vector2i.ONE, playable)
	var blockers: Dictionary = {
		"wall": _layer(room, "Walls"), "high obstacle": _layer(room, "HighObstacles"),
		"low obstacle": _layer(room, "LowObstacles"), "pit": _layer(room, "Pits"),
	}
	for spawn: EnemySpawn in spawns:
		var label: String = "EnemySpawn %s (wave %d) at %s" % [spawn.name, spawn.wave, spawn.position]
		if spawn.enemy == null:
			problems.append("%s has no enemy" % label)
		var cell: Vector2i = Vector2i((spawn.position / Const.TILE_SIZE).floor())
		if not playable_rect.has_point(cell):
			problems.append("%s is outside the playable area" % label)
		for kind: String in blockers:
			var layer: TileMapLayer = blockers[kind]
			if layer != null and layer.get_cell_source_id(cell) != -1:
				problems.append("%s is on a %s" % [label, kind])
		for door: Door in doors:
			var distance: float = spawn.position.distance_to(Door.center_for(door.side, frame)) / Const.TILE_SIZE
			if distance < MIN_SPAWN_DOOR_DISTANCE_TILES:
				problems.append("%s is %.1f tiles from the %s door (minimum %.0f)" % [
					label, distance, Door.Side.find_key(door.side), MIN_SPAWN_DOOR_DISTANCE_TILES])


static func _check_reinforcements(room: Room, problems: PackedStringArray) -> void:
	if REINFORCEMENT_FREE_TYPES.has(room.room_type) or room.is_nightmare:
		return
	var container: Node = room.get_node_or_null("ReinforcementSpawns")
	var count: int = 0
	if container != null:
		for child: Node in container.get_children():
			if child is ReinforcementSpawn:
				count += 1
	if count == 0:
		problems.append("no ReinforcementSpawn")


static func _layer(room: Room, layer_name: String) -> TileMapLayer:
	return room.get_node_or_null(layer_name) as TileMapLayer
