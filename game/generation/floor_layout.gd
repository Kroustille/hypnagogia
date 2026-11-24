class_name FloorLayout
extends RefCounted
## The rooms of one floor and how they connect (story 4.7): one room per grid cell, an edge between two adjacent cells
## whose rooms both have a door on the shared side. The connections are exactly `edges()` / `neighbors()`: a door of a room
## not in `door_sides(cell)` stays sealed (4.8), even facing another door. Built by FloorGenerator, read by the floor (4.8) and the map (4.9).
## Every listing is sorted (y, then x): no result depends on the insertion order of a Dictionary.

## One room of the floor.
class Placement extends RefCounted:
	var cell: Vector2i = Vector2i.ZERO
	var room_type: Room.RoomType = Room.RoomType.COMBAT
	## Null until the generator has chosen the room (and in a layout that has no rooms yet).
	var info: RoomInfo

## Map glyph of each room type (to_text).
const GLYPHS: Dictionary = {
	Room.RoomType.START: "S", Room.RoomType.COMBAT: "C", Room.RoomType.TREASURE: "T",
	Room.RoomType.SHOP: "B", Room.RoomType.NIGHTMARE: "N",
}
## Grid step of each Door.Side (N, E, S, W).
const SIDE_STEPS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]

## False when the generator could not meet the constraints (the other fields are then meaningless).
var valid: bool = false
## Why the layout is invalid; empty when valid.
var failure: String = ""
## Layouts drawn before this one (1 = the first draw worked).
var attempts: int = 0
var floor_index: int = 0
var start: Vector2i = Vector2i.ZERO
## The grid rectangle the floor was generated in (set by FloorGenerator; empty for a hand-built layout).
var grid: Rect2i = Rect2i()
var cells: Dictionary[Vector2i, Placement] = {}
var _links: Dictionary[Vector2i, Array] = {}


func add_cell(cell: Vector2i, room_type: Room.RoomType) -> Placement:
	var placement: Placement = Placement.new()
	placement.cell = cell
	placement.room_type = room_type
	cells[cell] = placement
	_links[cell] = []
	return placement


## Connects two adjacent cells (both must exist).
func connect_cells(a: Vector2i, b: Vector2i) -> void:
	if _links[a].has(b):
		return
	_links[a].append(b)
	_links[b].append(a)


func has_cell(cell: Vector2i) -> bool:
	return cells.has(cell)


func are_connected(a: Vector2i, b: Vector2i) -> bool:
	return _links.has(a) and _links[a].has(b)


## Cells in the generator's order: y, then x.
func sorted_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	result.assign(cells.keys())
	result.sort_custom(_cell_before)
	return result


## Cells connected to this one, sorted.
func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if _links.has(cell):
		result.assign(_links[cell])
	result.sort_custom(_cell_before)
	return result


## Door.Side values of the doors this cell uses, sorted.
func door_sides(cell: Vector2i) -> Array[int]:
	var sides: Array[int] = []
	for neighbor: Vector2i in neighbors(cell):
		sides.append(side_towards(cell, neighbor))
	sides.sort()
	return sides


## The Door.Side of cell facing the adjacent cell other.
static func side_towards(cell: Vector2i, other: Vector2i) -> int:
	return SIDE_STEPS.find(other - cell)


## Connections on the shortest path between two cells; -1 when there is none.
func distance(a: Vector2i, b: Vector2i) -> int:
	var depths: Dictionary[Vector2i, int] = depths_from(a)
	return depths.get(b, -1)


## Distance of every cell reachable from origin.
func depths_from(origin: Vector2i) -> Dictionary[Vector2i, int]:
	var depths: Dictionary[Vector2i, int] = {}
	if not cells.has(origin):
		return depths
	depths[origin] = 0
	var queue: Array[Vector2i] = [origin]
	var head: int = 0
	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		for neighbor: Vector2i in neighbors(current):
			if not depths.has(neighbor):
				depths[neighbor] = depths[current] + 1
				queue.append(neighbor)
	return depths


## Every edge once, as [a, b] with a before b, sorted.
func edges() -> Array[Array]:
	var result: Array[Array] = []
	for cell: Vector2i in sorted_cells():
		for neighbor: Vector2i in neighbors(cell):
			if _cell_before(cell, neighbor):
				result.append([cell, neighbor])
	return result


## Cells of one room type, sorted.
func cells_of_type(room_type: Room.RoomType) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell: Vector2i in sorted_cells():
		if cells[cell].room_type == room_type:
			result.append(cell)
	return result


## ASCII map of the floor: one glyph per room, - and | for the connections (journal and F1).
func to_text() -> String:
	if cells.is_empty():
		return "(empty floor)"
	var bounds: Rect2i = Rect2i(start, Vector2i.ONE)
	for cell: Vector2i in cells:
		bounds = bounds.expand(cell).expand(cell + Vector2i.ONE)
	var rows: Array[String] = []
	for y: int in range(bounds.position.y, bounds.end.y):
		var line: String = ""
		var link_line: String = ""
		for x: int in range(bounds.position.x, bounds.end.x):
			var cell: Vector2i = Vector2i(x, y)
			line += GLYPHS[cells[cell].room_type] if cells.has(cell) else " "
			line += "-" if are_connected(cell, cell + Vector2i.RIGHT) else " "
			link_line += "|" if are_connected(cell, cell + Vector2i.DOWN) else " "
			link_line += " "
		rows.append(line.rstrip(" "))
		rows.append(link_line.rstrip(" "))
	rows.pop_back() # no link row under the last row
	return "\n".join(rows)


## Canonical text of the floor (rooms and connections, sorted): two layouts are the same exactly when it is.
func signature() -> String:
	if not valid:
		return "invalid"
	var parts: PackedStringArray = PackedStringArray()
	for cell: Vector2i in sorted_cells():
		var placement: Placement = cells[cell]
		parts.append("%d,%d=%s" % [cell.x, cell.y, placement.info.id if placement.info != null else &"?"])
	for edge: Array in edges():
		parts.append("%d,%d-%d,%d" % [edge[0].x, edge[0].y, edge[1].x, edge[1].y])
	return ";".join(parts)


## y first, then x.
static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
