class_name RoomNav
extends RefCounted
## Navigation grid of a room (story 4.5, AR23): one AStarGrid2D cell per tile of the whole frame (walls included).
## Solid cells: walls, high and low obstacles, pits and the bodies of living furniture. Bodies of enemies never block
## (they push each other by physics). No node: built from a size and a list of blocked cells (from_room() reads a Room).
## Every position is in room coordinates (pixels from the corner of the wall frame), see origin for the world.
## Paths are throttled by the callers: take_path_slot() hands out at most max_paths_per_tick per physics tick.

## Sampling step of is_line_clear(), in pixels.
const LINE_STEP_PX: float = 4.0

## Number of path() calls so far (tests and the debug log).
var path_requests: int = 0
## Slots granted per physics tick by take_path_slot().
var max_paths_per_tick: int = 4
## Where the room sits in the world (a room is at the origin today): enemies subtract it from a global position.
var origin: Vector2 = Vector2.ZERO

var _grid: AStarGrid2D
var _size: Vector2i
var _slot_frame: int = -1
var _slots_used: int = 0
var _stagger_serial: int = 0


## cells_size: the whole frame in cells; blocked: cells to make solid at once.
func _init(cells_size: Vector2i, blocked: Array[Vector2i] = []) -> void:
	_size = Vector2i(maxi(cells_size.x, 1), maxi(cells_size.y, 1))
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, _size)
	_grid.cell_size = Vector2(Const.TILE_SIZE, Const.TILE_SIZE)
	_grid.offset = _grid.cell_size / 2.0 # paths aim at the center of the cells
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES # no cut corner
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update() # before any set_point_solid()
	for cell: Vector2i in blocked:
		set_blocked(cell, true)


## The grid of a room: walls, obstacles, pits and living furniture. Pieces destroyed later free their cells.
static func from_room(room: Room) -> RoomNav:
	var frame: Vector2i = room.frame_cells()
	var nav: RoomNav = RoomNav.new(frame, room.solid_cells())
	nav.origin = room.global_position
	nav.max_paths_per_tick = Tuning.COMBAT.max_paths_per_tick
	for piece: Furniture in room.furnitures():
		if not piece.is_destroyed():
			nav.set_cells_blocked(room.furniture_cells(piece), true)
			piece.destroyed.connect(nav.set_cells_blocked.bind(room.furniture_cells(piece), false), CONNECT_ONE_SHOT)
	return nav


func size_cells() -> Vector2i:
	return _size


func is_in_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


## Outside the grid counts as blocked.
func is_blocked(cell: Vector2i) -> bool:
	return not is_in_grid(cell) or _grid.is_point_solid(cell)


func set_blocked(cell: Vector2i, blocked: bool) -> void:
	if is_in_grid(cell):
		_grid.set_point_solid(cell, blocked)


func set_cells_blocked(cells: Array[Vector2i], blocked: bool) -> void:
	for cell: Vector2i in cells:
		set_blocked(cell, blocked)


func cell_of(point_px: Vector2) -> Vector2i:
	return Vector2i((point_px / Const.TILE_SIZE).floor())


func center_of(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * Const.TILE_SIZE


## Whether the caller may compute one path this physics tick (counts it). False past max_paths_per_tick: the caller
## keeps its previous path and asks again next tick.
func take_path_slot() -> bool:
	var frame: int = Engine.get_physics_frames()
	if frame != _slot_frame:
		_slot_frame = frame
		_slots_used = 0
	if _slots_used >= max_paths_per_tick:
		return false
	_slots_used += 1
	return true


## 0, 1, 2... one per caller: spreads the first recalculation of the enemies over the interval.
func next_stagger() -> int:
	_stagger_serial += 1
	return _stagger_serial - 1


## Cell centers from the start to the goal (start included), diagonals only when both neighbors are free. A blocked
## start or goal falls back to the nearest free cell (growing rings). No path (or no free cell at all): empty array.
func path(from_px: Vector2, to_px: Vector2) -> PackedVector2Array:
	path_requests += 1
	var start: Vector2i = nearest_free_cell(cell_of(from_px))
	var goal: Vector2i = nearest_free_cell(cell_of(to_px))
	if not is_in_grid(start) or not is_in_grid(goal) or is_blocked(start) or is_blocked(goal):
		return PackedVector2Array()
	return _grid.get_point_path(start, goal)


## The cell itself when free (and inside), else the nearest free one by distance between centers, ring by ring.
## (-1, -1) when the grid has no free cell.
func nearest_free_cell(cell: Vector2i) -> Vector2i:
	var clamped: Vector2i = cell.clamp(Vector2i.ZERO, _size - Vector2i.ONE)
	if not is_blocked(clamped):
		return clamped
	var best: Vector2i = Vector2i(-1, -1)
	for ring: int in range(1, maxi(_size.x, _size.y) + 1):
		var best_distance: float = INF
		for dy: int in range(-ring, ring + 1):
			for dx: int in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var candidate: Vector2i = clamped + Vector2i(dx, dy)
				if is_blocked(candidate):
					continue
				var distance: float = Vector2(candidate).distance_squared_to(Vector2(cell))
				if distance < best_distance:
					best_distance = distance
					best = candidate
		if best.x >= 0:
			return best
	return best


## True when the segment a-b and its two edges (offset by half_width_px on each side) touch no blocked cell.
func is_line_clear(a_px: Vector2, b_px: Vector2, half_width_px: float) -> bool:
	var line: Vector2 = b_px - a_px
	var length: float = line.length()
	var side: Vector2 = Vector2.ZERO
	if length > 1e-6:
		side = line.orthogonal() / length * half_width_px
	var steps: int = maxi(ceili(length / LINE_STEP_PX), 1)
	for i: int in steps + 1:
		var point: Vector2 = a_px.lerp(b_px, float(i) / steps)
		if is_blocked(cell_of(point)) or is_blocked(cell_of(point + side)) or is_blocked(cell_of(point - side)):
			return false
	return true
