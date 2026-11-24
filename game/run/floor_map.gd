class_name FloorMap
extends RefCounted
## What the player did on the floor so far (story 4.8): the room they are in, the rooms they entered, the rooms whose
## fight is won. Cells are the cells of the FloorLayout. Written by the Run, read by the map (story 4.9) and the rooms
## it builds (a cleared room comes back open and empty).

## The cell of the room the player is in.
var current: Vector2i = Vector2i.ZERO
## Cells entered at least once.
var visited: Dictionary[Vector2i, bool] = {}
## Cells whose fight is won (or that hold none).
var cleared: Dictionary[Vector2i, bool] = {}


func mark_entered(cell: Vector2i) -> void:
	current = cell
	visited[cell] = true


func mark_cleared(cell: Vector2i) -> void:
	cleared[cell] = true


func is_visited(cell: Vector2i) -> bool:
	return visited.has(cell)


func is_cleared(cell: Vector2i) -> bool:
	return cleared.has(cell)


## How a cell appears on the map (story 4.9).
enum State { VISITED, UNEXPLORED }

## The floor the cells belong to; set by the Run once the floor is generated. Null: nothing to show.
var layout: FloorLayout


## What the map shows, sorted (y, then x): the rooms entered, and the rooms behind a door of an entered room (not
## yet entered). Each entry: cell, state (State), type (Room.RoomType), size_kind (Room.SizeKind), current, cleared,
## links (known cells it is connected to: both known and at least one of the two entered).
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if layout == null:
		return result
	var known: Dictionary[Vector2i, bool] = discovered()
	for cell: Vector2i in layout.sorted_cells():
		if not known.has(cell):
			continue
		var placement: FloorLayout.Placement = layout.cells[cell]
		var links: Array[Vector2i] = []
		for neighbor: Vector2i in layout.neighbors(cell):
			if known.has(neighbor) and (is_visited(cell) or is_visited(neighbor)):
				links.append(neighbor)
		result.append({
			&"cell": cell,
			&"state": State.VISITED if is_visited(cell) else State.UNEXPLORED,
			&"type": placement.room_type,
			&"size_kind": placement.info.size_kind if placement.info != null else Room.SizeKind.SCREEN,
			&"current": cell == current,
			&"cleared": is_cleared(cell),
			&"links": links,
		})
	return result


## Cells the player knows of: entered, or connected by a door to an entered cell.
func discovered() -> Dictionary[Vector2i, bool]:
	var known: Dictionary[Vector2i, bool] = {}
	if layout == null:
		return known
	for cell: Vector2i in visited:
		if not layout.has_cell(cell):
			continue
		known[cell] = true
		for neighbor: Vector2i in layout.neighbors(cell):
			known[neighbor] = true
	return known


## The grid rectangle of the whole floor (stable while the map fills up: the drawing does not rescale).
func bounds() -> Rect2i:
	if layout == null or layout.cells.is_empty():
		return Rect2i()
	if layout.grid.has_area():
		return layout.grid # the whole grid: stable and it does not reveal the floor extent
	var rect: Rect2i = Rect2i(layout.start, Vector2i.ONE)
	for cell: Vector2i in layout.cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect


## What the player did, as saved in run.json: the current cell, the cells entered and the cells cleared, as [x, y] pairs
## (the layout itself is not saved: the seed makes it again).
func to_dict() -> Dictionary:
	return {
		"current": cell_to_array(current),
		"visited": _cells_to_array(visited),
		"cleared": _cells_to_array(cleared),
	}


## The map of a saved dictionary (no layout), null when a cell is not an [x, y] pair of integers.
static func from_dict(data: Dictionary) -> FloorMap:
	var map: FloorMap = FloorMap.new()
	var current_cell: Vector2i = cell_from_variant(data.get("current"))
	if current_cell == NO_CELL:
		return null
	map.current = current_cell
	for field: String in ["visited", "cleared"]:
		var list: Variant = data.get(field)
		if typeof(list) != TYPE_ARRAY:
			return null
		var entries: Array = list
		for entry: Variant in entries:
			var cell: Vector2i = cell_from_variant(entry)
			if cell == NO_CELL:
				return null
			if field == "visited":
				map.visited[cell] = true
			else:
				map.cleared[cell] = true
	return map


## Returned by cell_from_variant() for what is not a cell.
const NO_CELL: Vector2i = Vector2i(-2147483648, -2147483648)


static func cell_to_array(cell: Vector2i) -> Array:
	return [cell.x, cell.y]


## The cell of an [x, y] array of two whole numbers (JSON gives floats), NO_CELL for anything else.
static func cell_from_variant(value: Variant) -> Vector2i:
	if typeof(value) != TYPE_ARRAY:
		return NO_CELL
	var pair: Array = value
	if pair.size() != 2:
		return NO_CELL
	var numbers: Array[int] = []
	for part: Variant in pair:
		if typeof(part) == TYPE_INT:
			numbers.append(part)
		elif typeof(part) == TYPE_FLOAT:
			var number: float = part
			if not is_finite(number) or absf(number) > 1.0e6 or floorf(number) != number:
				return NO_CELL
			numbers.append(int(number))
		else:
			return NO_CELL
	return Vector2i(numbers[0], numbers[1])


static func _cells_to_array(cells: Dictionary[Vector2i, bool]) -> Array:
	var list: Array = []
	var keys: Array[Vector2i] = cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for cell: Vector2i in keys:
		list.append(cell_to_array(cell))
	return list
