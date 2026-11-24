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
	var rect: Rect2i = Rect2i(layout.start, Vector2i.ONE)
	for cell: Vector2i in layout.cells:
		rect = rect.expand(cell).expand(cell + Vector2i.ONE)
	return rect
