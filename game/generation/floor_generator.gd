class_name FloorGenerator
extends RefCounted
## Assembles the floor of a run from its seed (story 4.7, architecture D10/D11). Pure: no node, no autoload, no global
## RNG; every draw is made in a stream of the RunRng, over lists sorted before the draw, so one seed gives one floor
## whatever the order of a Dictionary or of the file system.
##
## One attempt: the shape (stream `layout`), then the rooms (stream `rooms`).
##  1. The start cell is the center of the grid. Combat cells grow from it one at a time, next to one or two occupied
##     cells, linked to one of them (a tree); then each adjacent unlinked pair of cells may get a link (a loop).
##  2. The nightmare, treasure and shop cells are dead ends hung on a start or combat cell; the nightmare one is at
##     least def.min_nightmare_distance connections from the start.
##  3. Each cell gets a room of its type that has a door on every side the cell uses, never one already used.
## An attempt that cannot be completed is dropped and the layout is drawn again, up to def.max_attempts times.

## Occupied neighbours a free cell may have to receive a combat room.
const MAX_GROWTH_NEIGHBORS: int = 2


## The floor of floor_index. Never loops forever: after def.max_attempts failed attempts the layout is invalid
## (valid = false, failure says why); the caller reports it.
static func generate(def: FloorDef, pool: Array[RoomInfo], rng: RunRng, floor_index: int) -> FloorLayout:
	var failure: String = "no attempt allowed"
	for attempt: int in def.max_attempts:
		var layout: FloorLayout = _attempt(def, pool, rng, floor_index)
		layout.attempts = attempt + 1
		if layout.valid:
			return layout
		failure = layout.failure
		if attempt + 1 == def.max_attempts:
			layout.failure = "no valid floor after %d attempts: %s" % [def.max_attempts, failure]
			return layout
	var failed: FloorLayout = FloorLayout.new()
	failed.failure = failure
	return failed


static func _attempt(def: FloorDef, pool: Array[RoomInfo], rng: RunRng, floor_index: int) -> FloorLayout:
	var layout: FloorLayout = FloorLayout.new()
	layout.floor_index = floor_index
	var shape: RandomNumberGenerator = rng.stream(RunRng.LAYOUT, floor_index)
	var bounds: Rect2i = Rect2i(0, 0, def.grid_width, def.grid_height)
	layout.grid = bounds
	layout.start = Vector2i(def.grid_width / 2, def.grid_height / 2)
	layout.add_cell(layout.start, Room.RoomType.START)
	if not _grow(layout, bounds, def.combat_rooms, shape):
		layout.failure = "the grid has no free cell left for the combat rooms"
		return layout
	_add_loops(layout, def.loop_chance, shape)
	var dead_ends: Array[Room.RoomType] = []
	for i: int in def.nightmare_rooms:
		dead_ends.append(Room.RoomType.NIGHTMARE) # first: it is the most constrained
	for i: int in def.treasure_rooms:
		dead_ends.append(Room.RoomType.TREASURE)
	for i: int in def.shop_rooms:
		dead_ends.append(Room.RoomType.SHOP)
	var depths: Dictionary[Vector2i, int] = layout.depths_from(layout.start)
	for room_type: Room.RoomType in dead_ends:
		var minimum: int = def.min_nightmare_distance if room_type == Room.RoomType.NIGHTMARE else 1
		if not _add_dead_end(layout, bounds, room_type, minimum, depths, shape):
			layout.failure = "no dead end for a %s room" % Room.RoomType.find_key(room_type)
			return layout
	var chosen: RandomNumberGenerator = rng.stream(RunRng.ROOMS, floor_index)
	var missing: String = _choose_rooms(layout, pool, chosen)
	if not missing.is_empty():
		layout.failure = missing
		return layout
	layout.valid = true
	return layout


## Adds count combat cells, each next to one or two occupied cells and linked to one of them.
static func _grow(layout: FloorLayout, bounds: Rect2i, count: int, shape: RandomNumberGenerator) -> bool:
	for i: int in count:
		var eligible: Array[Vector2i] = []
		for cell: Vector2i in _grid_cells(bounds):
			if layout.has_cell(cell):
				continue
			var occupied: int = _occupied_neighbors(layout, cell).size()
			if occupied >= 1 and occupied <= MAX_GROWTH_NEIGHBORS:
				eligible.append(cell)
		if eligible.is_empty():
			return false
		var cell: Vector2i = eligible[shape.randi_range(0, eligible.size() - 1)]
		var parents: Array[Vector2i] = _occupied_neighbors(layout, cell)
		var parent: Vector2i = parents[shape.randi_range(0, parents.size() - 1)]
		layout.add_cell(cell, Room.RoomType.COMBAT)
		layout.connect_cells(cell, parent)
	return true


## Each pair of adjacent cells that are not linked yet is linked with probability loop_chance (one draw per pair, in
## cell order). The cells are the start and combat ones: the dead ends do not exist yet.
static func _add_loops(layout: FloorLayout, loop_chance: float, shape: RandomNumberGenerator) -> void:
	for cell: Vector2i in layout.sorted_cells():
		for step: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
			var other: Vector2i = cell + step
			if layout.has_cell(other) and not layout.are_connected(cell, other):
				if shape.randf() < loop_chance:
					layout.connect_cells(cell, other)


## A dead end of room_type: a free cell with exactly one occupied neighbour, a start or combat cell at least
## min_distance - 1 connections from the start.
static func _add_dead_end(layout: FloorLayout, bounds: Rect2i, room_type: Room.RoomType, min_distance: int,
		depths: Dictionary[Vector2i, int], shape: RandomNumberGenerator) -> bool:
	var candidates: Array[Vector2i] = []
	var parents: Dictionary[Vector2i, Vector2i] = {}
	for cell: Vector2i in _grid_cells(bounds):
		if layout.has_cell(cell):
			continue
		var occupied: Array[Vector2i] = _occupied_neighbors(layout, cell)
		if occupied.size() != 1:
			continue
		var parent: Vector2i = occupied[0]
		var parent_type: Room.RoomType = layout.cells[parent].room_type
		if parent_type != Room.RoomType.COMBAT and parent_type != Room.RoomType.START:
			continue
		if depths[parent] + 1 < min_distance:
			continue
		candidates.append(cell)
		parents[cell] = parent
	if candidates.is_empty():
		return false
	var cell: Vector2i = candidates[shape.randi_range(0, candidates.size() - 1)]
	layout.add_cell(cell, room_type)
	layout.connect_cells(cell, parents[cell])
	return true


## Gives each cell a room. The cells with the most doors go first (the hardest to fill). Returns "" when done, else why not.
static func _choose_rooms(layout: FloorLayout, pool: Array[RoomInfo], chosen: RandomNumberGenerator) -> String:
	var ordered: Array[Vector2i] = layout.sorted_cells()
	ordered.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		var sides_a: int = layout.door_sides(a).size()
		var sides_b: int = layout.door_sides(b).size()
		if sides_a != sides_b:
			return sides_a > sides_b
		return a.y < b.y or (a.y == b.y and a.x < b.x))
	var by_id: Array[RoomInfo] = pool.duplicate()
	by_id.sort_custom(func(a: RoomInfo, b: RoomInfo) -> bool: return String(a.id) < String(b.id))
	var used: Dictionary[StringName, bool] = {}
	for cell: Vector2i in ordered:
		var placement: FloorLayout.Placement = layout.cells[cell]
		var sides: Array[int] = layout.door_sides(cell)
		var candidates: Array[RoomInfo] = []
		for info: RoomInfo in by_id:
			if info.room_type == placement.room_type and not used.has(info.id) and _has_doors(info, sides):
				candidates.append(info)
		if candidates.is_empty():
			return "no %s room left with doors %s" % [Room.RoomType.find_key(placement.room_type), sides]
		var info: RoomInfo = candidates[chosen.randi_range(0, candidates.size() - 1)]
		used[info.id] = true
		placement.info = info
	return ""


static func _has_doors(info: RoomInfo, sides: Array[int]) -> bool:
	for side: int in sides:
		if not info.doors.has(side):
			return false
	return true


## Occupied cells next to cell, in the order N, E, S, W.
static func _occupied_neighbors(layout: FloorLayout, cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for step: Vector2i in FloorLayout.SIDE_STEPS:
		if layout.has_cell(cell + step):
			result.append(cell + step)
	return result


## Every cell of the grid, y then x.
static func _grid_cells(bounds: Rect2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			result.append(Vector2i(x, y))
	return result
