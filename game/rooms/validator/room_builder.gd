class_name RoomBuilder
extends Node
## Builds a room scene from an ASCII source text (story 4.2), run by tools/build_room.sh. The generated .tscn is the
## truth of the game and stays editable in Godot; the text is there for agents, who cannot paint.
##
## Source format (blank lines and lines starting with // are ignored):
##   type: combat          start | combat | treasure | shop | nightmare
##   phase: onset          optional, default onset: the scene lands in rooms/pool/<phase>/ (a lowercase word)
##   size: screen          screen (36x19 playable tiles) | wide (72x19) | tall (36x38)
##   grid: loose           optional, test fixtures only: the grid may differ from the playable area (an error otherwise)
##   <grid rows>           the playable area, one row per line: . floor, # wall, H high obstacle, L low obstacle, P pit
##   spawn <enemy> <wave> <x> <y>     enemy: sleepwalker, night_light, lullaby, sheep (none = no enemy, for fixtures)
##   reinforce <x> <y>
##   door <N|E|S|W>
##   furniture <bed|chair|desk> <x> <y>   (none = no def, for fixtures) the piece covers its size in tiles from (x, y) to the right and down
##   trigger <lamp> <x> <y>                 (none = no kind, for fixtures)
## x and y count playable tiles from 0 at the top-left of the grid; markers sit at the center of their tile.

const BASE_SCENE: PackedScene = preload("res://rooms/room_base.tscn")
const DOOR_SCENE: PackedScene = preload("res://rooms/door.tscn")
const OUTPUT_ROOT: String = "res://rooms/pool"
const ENEMIES: Dictionary = {
	"sleepwalker": "res://data/enemies/sleepwalker.tres",
	"night_light": "res://data/enemies/night_light.tres",
	"lullaby": "res://data/enemies/lullaby.tres",
	"sheep": "res://data/enemies/sheep.tres",
}
const FURNITURE_DIR: String = "res://data/furniture/"
const FURNITURE_KINDS: Array[String] = ["bed", "chair", "desk"]
const GRID_CHARS: String = ".#HLP"
## Waves a room may have (a wave number outside 0..MAX_WAVE is a typo).
const MAX_WAVE: int = 20
## Where the scene is written before being moved into the pool: a failed build never leaves a half-written room there.
const TEMP_SCENE: String = "user://room_builder_tmp.tscn"
## Lengths of the generated ids that Godot would otherwise draw at random on every save.
const ID_SUFFIX_LENGTH: int = 5
const MAX_UNIQUE_ID: int = 0x7FFFFFFF
const ROOM_TYPES: Dictionary = {
	"start": Room.RoomType.START, "combat": Room.RoomType.COMBAT, "treasure": Room.RoomType.TREASURE,
	"shop": Room.RoomType.SHOP, "nightmare": Room.RoomType.NIGHTMARE,
}
const SIZE_KINDS: Dictionary = {"screen": Room.SizeKind.SCREEN, "wide": Room.SizeKind.WIDE, "tall": Room.SizeKind.TALL}
const DOOR_SIDES: Dictionary = {"N": Door.Side.N, "E": Door.Side.E, "S": Door.Side.S, "W": Door.Side.W}

## Set by the `grid: loose` header: the grid is not checked against the playable area.
var _loose_grid: bool = false


func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		return # instantiated by a test: nothing to run
	await get_tree().process_frame # `--scene` never returns without a quit issued after the first frame
	get_tree().quit(run(args[0], args[1] if args.size() > 1 else ""))


## Reads the source file and writes the scene. Returns the exit code. The scene is written only when the text is valid
## and, for a pool room (no explicit output: test fixtures are invalid on purpose), the built room passes the RoomValidator.
func run(source_path: String, output_path: String) -> int:
	var file: FileAccess = FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		printerr("build_room: cannot read %s" % source_path)
		return 1
	var errors: PackedStringArray = PackedStringArray()
	var room: Room = build(file.get_as_text(), errors)
	var room_name: String = source_path.get_file().get_basename()
	if room != null and errors.is_empty() and output_path.is_empty() and not _loose_grid:
		errors.append_array(RoomValidator.validate_room(room, room_name))
	if not errors.is_empty():
		for message: String in errors:
			printerr("%s: %s" % [source_path.get_file(), message])
		if room != null:
			room.free()
		return 1
	if output_path.is_empty():
		output_path = "%s/%s/%s.tscn" % [OUTPUT_ROOT, room.phase, room_name]
	var scene: PackedScene = PackedScene.new()
	var packed: Error = scene.pack(room)
	room.free()
	if packed != OK:
		printerr("build_room: cannot pack the room (%s)" % error_string(packed))
		return 1
	var saved: Error = ResourceSaver.save(scene, TEMP_SCENE)
	if saved != OK:
		printerr("build_room: cannot save %s (%s)" % [TEMP_SCENE, error_string(saved)])
		return 1
	var written: Error = _publish(TEMP_SCENE, output_path)
	if written != OK:
		printerr("build_room: cannot write %s (%s)" % [output_path, error_string(written)])
		return 1
	Log.info("room", "built %s" % output_path)
	return 0


## Copies the saved scene to its place with the ids Godot draws at random replaced by stable ones: building the same
## text twice gives the same file, so the diffs of the pool show real changes only.
func _publish(temp_path: String, output_path: String) -> Error:
	var text: String = FileAccess.get_file_as_string(temp_path)
	if text.is_empty():
		return FileAccess.get_open_error()
	var made: Error = DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if made != OK:
		return made
	var target: FileAccess = FileAccess.open(output_path, FileAccess.WRITE)
	if target == null:
		return FileAccess.get_open_error()
	target.store_string(stable_ids(text))
	target.close()
	DirAccess.remove_absolute(temp_path)
	return OK


## The scene text with deterministic ids: the suffix of every ext_resource and sub_resource id comes from what the
## resource is, the unique_id of every node from its path in the scene.
static func stable_ids(text: String) -> String:
	var lines: PackedStringArray = text.split("\n")
	var renames: Dictionary = {} # old id -> new id
	var unique: Dictionary = {} # unique_id values already given
	var node_ids: RegEx = RegEx.create_from_string("unique_id=\\d+")
	var attributes: RegEx = RegEx.create_from_string("(\\w+)=\"([^\"]*)\"")
	for index: int in lines.size():
		var line: String = lines[index]
		if line.begins_with("[ext_resource ") or line.begins_with("[sub_resource "):
			var found: Dictionary = {}
			for match: RegExMatch in attributes.search_all(line):
				found[match.get_string(1)] = match.get_string(2)
			var old_id: String = found.get("id", "")
			if old_id.is_empty():
				continue
			var key: String = found.get("path", found.get("type", "")) + ":" + old_id.get_slice("_", 0)
			var base: String = old_id.substr(0, old_id.rfind("_") + 1) if old_id.contains("_") else ""
			renames[old_id] = base + key.md5_text().substr(0, ID_SUFFIX_LENGTH)
		elif line.begins_with("[node "):
			var found: Dictionary = {}
			for match: RegExMatch in attributes.search_all(line):
				found[match.get_string(1)] = match.get_string(2)
			var path: String = "%s/%s" % [found.get("parent", ""), found.get("name", "")]
			var value: int = path.hash() & MAX_UNIQUE_ID
			while value == 0 or unique.has(value):
				value = (value + 1) & MAX_UNIQUE_ID
			unique[value] = true
			lines[index] = node_ids.sub(line, "unique_id=%d" % value)
	var result: String = "\n".join(lines)
	for old_id: String in renames:
		result = result.replace("\"%s\"" % old_id, "\"%s\"" % renames[old_id])
	return result


## The room described by the text: an instance of room_base.tscn with its layers, markers and doors filled in. Problems
## of the text are appended to errors (the room is still returned, as complete as possible). Null when the base scene
## does not give a Room (a script of the room does not compile).
func build(text: String, errors: PackedStringArray) -> Room:
	var room: Room = BASE_SCENE.instantiate() as Room
	if room == null:
		errors.append("room_base.tscn does not instantiate a Room (a script error?)")
		return null
	_loose_grid = false
	var grid: Array[String] = []
	var doors: Array[Door.Side] = []
	var serial: int = 0
	for raw: String in text.split("\n"):
		var line: String = raw.strip_edges()
		if line.is_empty() or line.begins_with("//"):
			continue
		if _is_grid_row(line):
			grid.append(line)
			continue
		if _is_header(line):
			_read_header(room, line, errors)
			continue
		var words: PackedStringArray = line.split(" ", false)
		serial += 1
		match words[0]:
			"spawn":
				_add_spawn(room, words, serial, errors)
			"reinforce":
				_add_reinforcement(room, words, serial, errors)
			"door":
				_add_door(room, words, doors, errors)
			"furniture":
				_add_furniture(room, words, serial, errors)
			"trigger":
				_add_trigger(room, words, serial, errors)
			_:
				errors.append("unknown line: %s" % line)
	if not _loose_grid:
		_check_grid(room, grid, errors)
	_paint(room, grid)
	return room


## "key: value", the key a single word: a line holding a colon elsewhere is not a header.
static func _is_header(line: String) -> bool:
	var colon: int = line.find(":")
	return colon > 0 and not line.substr(0, colon).contains(" ")


static func _is_grid_row(line: String) -> bool:
	for i: int in line.length():
		if not GRID_CHARS.contains(line[i]):
			return false
	return true


func _read_header(room: Room, line: String, errors: PackedStringArray) -> void:
	var parts: PackedStringArray = line.split(":", true, 1)
	var key: String = parts[0].strip_edges()
	var value: String = parts[1].strip_edges()
	match key:
		"type":
			if ROOM_TYPES.has(value):
				room.room_type = ROOM_TYPES[value]
			else:
				errors.append("unknown room type: %s" % value)
		"phase":
			if value.is_valid_identifier() and value == value.to_lower():
				room.phase = StringName(value)
			else:
				errors.append("invalid phase: %s" % value)
		"grid":
			if value == "loose":
				_loose_grid = true
			else:
				errors.append("unknown grid mode: %s" % value)
		"size":
			if SIZE_KINDS.has(value):
				room.size_kind = SIZE_KINDS[value]
			else:
				errors.append("unknown size: %s" % value)
		_:
			errors.append("unknown header: %s" % key)


## The grid covers the playable area exactly: a short row would leave a cell without floor or wall.
func _check_grid(room: Room, grid: Array[String], errors: PackedStringArray) -> void:
	var playable: Vector2i = room.playable_tiles()
	if grid.size() != playable.y:
		errors.append("grid has %d rows, expected %d" % [grid.size(), playable.y])
	for row: int in grid.size():
		if grid[row].length() != playable.x:
			errors.append("grid row %d has %d characters, expected %d" % [row, grid[row].length(), playable.x])

## Floor under the whole grid, the frame of walls around the expected playable area, then the symbols of the grid.
func _paint(room: Room, grid: Array[String]) -> void:
	var floor_layer: TileMapLayer = room.get_node("Floor") as TileMapLayer
	var walls: TileMapLayer = room.get_node("Walls") as TileMapLayer
	var high: TileMapLayer = room.get_node("HighObstacles") as TileMapLayer
	var low: TileMapLayer = room.get_node("LowObstacles") as TileMapLayer
	var pits: TileMapLayer = room.get_node("Pits") as TileMapLayer
	var frame: Vector2i = room.frame_cells()
	for x: int in frame.x:
		walls.set_cell(Vector2i(x, 0), Room.TILE_WALL, Vector2i.ZERO)
		walls.set_cell(Vector2i(x, frame.y - 1), Room.TILE_WALL, Vector2i.ZERO)
	for y: int in frame.y:
		walls.set_cell(Vector2i(0, y), Room.TILE_WALL, Vector2i.ZERO)
		walls.set_cell(Vector2i(frame.x - 1, y), Room.TILE_WALL, Vector2i.ZERO)
	for row: int in grid.size():
		for column: int in grid[row].length():
			var cell: Vector2i = Vector2i(column + 1, row + 1)
			floor_layer.set_cell(cell, Room.TILE_FLOOR, Vector2i.ZERO)
			match grid[row][column]:
				"#":
					walls.set_cell(cell, Room.TILE_WALL, Vector2i.ZERO)
				"H":
					high.set_cell(cell, Room.TILE_HIGH_OBSTACLE, Vector2i.ZERO)
				"L":
					low.set_cell(cell, Room.TILE_LOW_OBSTACLE, Vector2i.ZERO)
				"P":
					pits.set_cell(cell, Room.TILE_PIT, Vector2i.ZERO)


func _add_spawn(room: Room, words: PackedStringArray, serial: int, errors: PackedStringArray) -> void:
	if words.size() != 5 or not words[2].is_valid_int() or not _is_number(words[3]) or not _is_number(words[4]):
		errors.append("spawn needs: spawn <enemy> <wave> <x> <y>")
		return
	var spawn: EnemySpawn = EnemySpawn.new()
	if ENEMIES.has(words[1]):
		var enemy_path: String = ENEMIES[words[1]]
		spawn.enemy = load(enemy_path) as EnemyDef
	elif words[1] != "none":
		errors.append("unknown enemy: %s" % words[1])
	spawn.wave = words[2].to_int()
	if spawn.wave < 0 or spawn.wave > MAX_WAVE:
		errors.append("wave %d is outside 0..%d" % [spawn.wave, MAX_WAVE])
	spawn.position = _tile_center(words[3], words[4])
	_adopt(room, "EnemySpawns", spawn, "Spawn_%s_%d_%d" % [words[1], spawn.wave, serial])


func _add_reinforcement(room: Room, words: PackedStringArray, serial: int, errors: PackedStringArray) -> void:
	if words.size() != 3 or not _is_number(words[1]) or not _is_number(words[2]):
		errors.append("reinforce needs: reinforce <x> <y>")
		return
	var marker: ReinforcementSpawn = ReinforcementSpawn.new()
	marker.position = _tile_center(words[1], words[2])
	_adopt(room, "ReinforcementSpawns", marker, "Reinforcement_%d" % serial)


func _add_door(room: Room, words: PackedStringArray, doors: Array[Door.Side], errors: PackedStringArray) -> void:
	if words.size() != 2 or not DOOR_SIDES.has(words[1]):
		errors.append("door needs: door <N|E|S|W>")
		return
	var side: Door.Side = DOOR_SIDES[words[1]]
	if doors.has(side):
		errors.append("door %s declared twice" % words[1])
		return
	doors.append(side)
	var door: Door = DOOR_SCENE.instantiate() as Door
	door.side = side
	door.position = Door.center_for(side, room.frame_cells())
	_adopt(room, "Doors", door, "Door%s" % words[1])


func _add_furniture(room: Room, words: PackedStringArray, serial: int, errors: PackedStringArray) -> void:
	if words.size() != 4 or not _is_number(words[2]) or not _is_number(words[3]):
		errors.append("furniture needs: furniture <kind> <x> <y>")
		return
	var furniture: Furniture = Furniture.new()
	if FURNITURE_KINDS.has(words[1]):
		furniture.def = load(FURNITURE_DIR + words[1] + ".tres") as FurnitureDef
	elif words[1] != "none":
		errors.append("unknown furniture: %s" % words[1])
	furniture.position = _tile_center(words[2], words[3])
	_adopt(room, "Furnitures", furniture, "Furniture_%s_%d" % [words[1], serial])


func _add_trigger(room: Room, words: PackedStringArray, serial: int, errors: PackedStringArray) -> void:
	if words.size() != 4 or not _is_number(words[2]) or not _is_number(words[3]):
		errors.append("trigger needs: trigger <kind> <x> <y>")
		return
	var trigger: Trigger = Trigger.new()
	if Trigger.KNOWN_KINDS.has(StringName(words[1])):
		trigger.kind = StringName(words[1])
	elif words[1] != "none":
		errors.append("unknown trigger: %s" % words[1])
	trigger.position = _tile_center(words[2], words[3])
	_adopt(room, "Triggers", trigger, "Trigger_%s_%d" % [words[1], serial])


## Center of a playable tile, in pixels from the corner of the wall frame.
func _tile_center(x: String, y: String) -> Vector2:
	return (Vector2(x.to_float(), y.to_float()) + Vector2(1.5, 1.5)) * Const.TILE_SIZE


func _is_number(text: String) -> bool:
	return text.is_valid_float()


## Adds node under the container, owned by the room root so that packing saves it.
func _adopt(room: Room, container: String, node: Node, node_name: String) -> void:
	node.name = node_name
	room.get_node(container).add_child(node)
	node.owner = room
