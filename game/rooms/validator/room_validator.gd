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
	var sides: Dictionary = {}
	for door: Door in doors:
		if sides.has(door.side):
			problems.append("two doors on the %s side" % Door.Side.find_key(door.side))
		sides[door.side] = true
	_check_player_spawn(room, playable, problems)
	_check_enemies(room, playable, frame, doors, problems)
	_check_reinforcements(room, playable, problems)
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
	else:
		var holes: int = playable.x * playable.y - floor_layer.get_used_cells().size()
		if holes != 0:
			problems.append("%d playable cell(s) without floor" % holes)
	var frame_rect: Rect2i = Rect2i(Vector2i.ZERO, frame)
	for x: int in frame.x:
		for y: int in [0, frame.y - 1]:
			_require_frame_wall(walls, Vector2i(x, y), problems)
	for y: int in range(1, frame.y - 1):
		for x: int in [0, frame.x - 1]:
			_require_frame_wall(walls, Vector2i(x, y), problems)
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


## The frame is complete: doors are walls in the scene (they open at runtime).
static func _require_frame_wall(walls: TileMapLayer, cell: Vector2i, problems: PackedStringArray) -> void:
	if walls.get_cell_source_id(cell) == -1:
		problems.append("frame wall missing at %s" % cell)


## The player enters at the center of the room (until story 4.8): that cell must be free.
static func _check_player_spawn(room: Room, playable: Vector2i, problems: PackedStringArray) -> void:
	var position: Vector2 = room.to_local(room.player_spawn_position())
	_check_marker_cell("player spawn at %s" % position, position, Rect2i(Vector2i.ONE, playable), _blockers(room), problems)

static func _check_enemies(room: Room, playable: Vector2i, frame: Vector2i, doors: Array[Door], problems: PackedStringArray) -> void:
	var spawns: Array[EnemySpawn] = room.enemy_spawns()
	if spawns.is_empty() and room.room_type == Room.RoomType.COMBAT:
		problems.append("combat room without EnemySpawn")
	var playable_rect: Rect2i = Rect2i(Vector2i.ONE, playable)
	var blockers: Dictionary = _blockers(room)
	_check_wave_sizes(spawns, problems)
	for spawn: EnemySpawn in spawns:
		var label: String = "EnemySpawn %s (wave %d) at %s" % [spawn.name, spawn.wave, spawn.position]
		if spawn.enemy == null:
			problems.append("%s has no enemy" % label)
		_check_marker_cell(label, spawn.position, playable_rect, blockers, problems)
		for door: Door in doors:
			var distance: float = spawn.position.distance_to(Door.center_for(door.side, frame)) / Const.TILE_SIZE
			if distance < MIN_SPAWN_DOOR_DISTANCE_TILES:
				problems.append("%s is %.1f tiles from the %s door (minimum %.0f)" % [
					label, distance, Door.Side.find_key(door.side), MIN_SPAWN_DOOR_DISTANCE_TILES])


static func _check_reinforcements(room: Room, playable: Vector2i, problems: PackedStringArray) -> void:
	var blockers: Dictionary = _blockers(room)
	var container: Node = room.get_node_or_null("ReinforcementSpawns")
	var count: int = 0
	if container != null:
		for child: Node in container.get_children():
			var marker: ReinforcementSpawn = child as ReinforcementSpawn
			if marker != null:
				count += 1
				_check_marker_cell("ReinforcementSpawn %s at %s" % [marker.name, marker.position], marker.position,
						Rect2i(Vector2i.ONE, playable), blockers, problems)
	var exempt: bool = REINFORCEMENT_FREE_TYPES.has(room.room_type) or room.is_nightmare
	if count == 0 and not exempt:
		problems.append("no ReinforcementSpawn")


## The layers whose cells a marker or the player may not stand on, by label.
static func _blockers(room: Room) -> Dictionary:
	return {
		"wall": _layer(room, "Walls"), "high obstacle": _layer(room, "HighObstacles"),
		"low obstacle": _layer(room, "LowObstacles"), "pit": _layer(room, "Pits"),
	}


## A marker sits inside the playable area, on no wall, obstacle or pit.
static func _check_marker_cell(label: String, position: Vector2, playable_rect: Rect2i, blockers: Dictionary, problems: PackedStringArray) -> void:
	var cell: Vector2i = Vector2i((position / Const.TILE_SIZE).floor())
	if not playable_rect.has_point(cell):
		problems.append("%s is outside the playable area" % label)
		return # the layers below are not drawn out there
	for kind: String in blockers:
		var layer: TileMapLayer = blockers[kind]
		if layer != null and layer.get_cell_source_id(cell) != -1:
			problems.append("%s is on a %s" % [label, kind])


## A wave holds at most WaveRunner.MAX_WAVE_ENEMIES enemies: the markers beyond would be dropped, shifting the slots.
static func _check_wave_sizes(spawns: Array[EnemySpawn], problems: PackedStringArray) -> void:
	var sizes: Dictionary[int, int] = {}
	for spawn: EnemySpawn in spawns:
		if spawn.enemy != null and spawn.enemy.scene != null:
			sizes[spawn.wave] = sizes.get(spawn.wave, 0) + 1
	var waves: Array = sizes.keys()
	waves.sort()
	for wave: int in waves:
		if sizes[wave] > WaveRunner.MAX_WAVE_ENEMIES:
			problems.append("wave %d has %d enemy markers (maximum %d)" % [wave, sizes[wave], WaveRunner.MAX_WAVE_ENEMIES])


## Every enemy marker and every door must be reachable on foot from the first door: floor without pit, wall or
## obstacle, 4-connected (story 4.3).
static func _check_reachability(room: Room, playable: Vector2i, frame: Vector2i, doors: Array[Door], problems: PackedStringArray) -> void:
	var floor_layer: TileMapLayer = _layer(room, "Floor")
	if floor_layer == null or doors.is_empty():
		return
	if floor_layer.get_used_rect().size != playable:
		return # the layout problem is already reported
	var blockers: Array[TileMapLayer] = []
	for layer_name: String in ["Walls", "HighObstacles", "LowObstacles", "Pits"]:
		var layer: TileMapLayer = _layer(room, layer_name)
		if layer != null:
			blockers.append(layer)
	var playable_rect: Rect2i = Rect2i(Vector2i.ONE, playable)
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
