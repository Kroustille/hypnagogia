class_name RoomValidator
extends RefCounted
## Checks the shape of a pre-drawn room (story 4.2): dimensions, doors, enemy and reinforcement markers. Pure: it only
## reads the scene, never adds it to the tree. One problem per line, "<room id>: <problem>"; an empty result means the
## room is valid. The checks of later stories (furniture, large rooms) join this class.

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
	_check_reachability(room, playable, frame, doors, problems)
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


## Every enemy marker and every door must be reachable on foot from the first door: floor without pit, wall or
## obstacle, 4-connected (story 4.3). Reinforcement markers must not sit on a pit.
static func _check_reachability(room: Room, playable: Vector2i, frame: Vector2i, doors: Array[Door], problems: PackedStringArray) -> void:
	var floor_layer: TileMapLayer = _layer(room, "Floor")
	if floor_layer == null or doors.is_empty():
		return
	if floor_layer.get_used_rect().size != playable:
		return # the layout problem is already reported
	var pits: TileMapLayer = _layer(room, "Pits")
	var blockers: Array[TileMapLayer] = []
	for layer_name: String in ["Walls", "HighObstacles", "LowObstacles", "Pits"]:
		var layer: TileMapLayer = _layer(room, layer_name)
		if layer != null:
			blockers.append(layer)
	var playable_rect: Rect2i = Rect2i(Vector2i.ONE, playable)
	var container: Node = room.get_node_or_null("ReinforcementSpawns")
	if container != null and pits != null:
		for child: Node in container.get_children():
			var reinforcement: ReinforcementSpawn = child as ReinforcementSpawn
			if reinforcement != null and pits.get_cell_source_id(Vector2i((reinforcement.position / Const.TILE_SIZE).floor())) != -1:
				problems.append("ReinforcementSpawn %s at %s is on a pit" % [reinforcement.name, reinforcement.position])
	var walkable: Callable = func(cell: Vector2i) -> bool:
		if not playable_rect.has_point(cell) or floor_layer.get_cell_source_id(cell) == -1:
			return false
		for layer: TileMapLayer in blockers:
			if layer.get_cell_source_id(cell) != -1:
				return false
		return true
	var door_entries: Array[Array] = []
	for door: Door in doors:
		var entries: Array[Vector2i] = _door_entries(door.side, frame)
		door_entries.append(entries)
	var start: Vector2i = Vector2i(-1, -1)
	for entry: Vector2i in door_entries[0]:
		if walkable.call(entry):
			start = entry
			break
	if start == Vector2i(-1, -1):
		problems.append("the %s door opens on blocked cells" % Door.Side.find_key(doors[0].side))
		return
	var reached: Dictionary[Vector2i, bool] = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var current: Vector2i = queue.pop_back()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + step
			if not reached.has(next) and walkable.call(next):
				reached[next] = true
				queue.append(next)
	for i: int in range(1, doors.size()):
		var door_reached: bool = false
		for entry: Vector2i in door_entries[i]:
			door_reached = door_reached or reached.has(entry)
		if not door_reached:
			problems.append("the %s door is cut off from the %s door" % [
				Door.Side.find_key(doors[i].side), Door.Side.find_key(doors[0].side)])
	for spawn: EnemySpawn in room.enemy_spawns():
		var spawn_cell: Vector2i = Vector2i((spawn.position / Const.TILE_SIZE).floor())
		if walkable.call(spawn_cell) and not reached.has(spawn_cell): # one on a blocker is reported by _check_enemies
			problems.append("EnemySpawn %s at %s is cut off from the doors" % [spawn.name, spawn.position])


## The playable cells right behind the wall cells of a door (frame coordinates).
static func _door_entries(side: Door.Side, frame: Vector2i) -> Array[Vector2i]:
	var inward: Vector2i = Vector2i.ZERO
	match side:
		Door.Side.N:
			inward = Vector2i.DOWN
		Door.Side.S:
			inward = Vector2i.UP
		Door.Side.W:
			inward = Vector2i.RIGHT
		Door.Side.E:
			inward = Vector2i.LEFT
	var entries: Array[Vector2i] = []
	for cell: Vector2i in Door.cells_for(side, frame):
		entries.append(cell + inward)
	return entries


static func _layer(room: Room, layer_name: String) -> TileMapLayer:
	return room.get_node_or_null(layer_name) as TileMapLayer
