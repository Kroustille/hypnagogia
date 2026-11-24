class_name Door
extends Node2D
## A door of a room (story 4.2). It sits at a canonical place of its side of the wall frame (middle of the side,
## Tuning.ROOM.door_width_tiles wide) and is made of wall tiles of the room's Walls layer: closed or sealed it puts
## them back, open it removes them. Shots, enemies and the Glide ray therefore respect it with no code of their own.
## Crossing a door arrives with story 4.8.

enum Side { N, E, S, W }
## SEALED: no neighbour, stays a wall for good. CLOSED: a wall for now (fight in progress). OPEN: passable.
enum State { SEALED, CLOSED, OPEN }

## The tile of the Walls layer a closed door is made of (source of the onset tileset).
const WALL_SOURCE_ID: int = 1

signal state_changed(state: State)

@export var side: Door.Side = Door.Side.N
var state: State = State.OPEN

var _walls: TileMapLayer
var _frame_cells: Vector2i = Vector2i.ZERO


## The wall cells of a door on a side of a frame of frame_cells cells, in frame coordinates.
static func cells_for(door_side: Door.Side, frame_cells: Vector2i) -> Array[Vector2i]:
	var width: int = Tuning.ROOM.door_width_tiles
	var cells: Array[Vector2i] = []
	for i: int in width:
		match door_side:
			Side.N:
				cells.append(Vector2i((frame_cells.x - width) / 2 + i, 0))
			Side.S:
				cells.append(Vector2i((frame_cells.x - width) / 2 + i, frame_cells.y - 1))
			Side.W:
				cells.append(Vector2i(0, (frame_cells.y - width) / 2 + i))
			Side.E:
				cells.append(Vector2i(frame_cells.x - 1, (frame_cells.y - width) / 2 + i))
	return cells


## Center of the door in pixels, in frame coordinates.
static func center_for(door_side: Door.Side, frame_cells: Vector2i) -> Vector2:
	var cells: Array[Vector2i] = cells_for(door_side, frame_cells)
	var sum: Vector2 = Vector2.ZERO
	for cell: Vector2i in cells:
		sum += (Vector2(cell) + Vector2(0.5, 0.5)) * Const.TILE_SIZE
	return sum / cells.size()


## Binds the door to the Walls layer of its room, puts it at its canonical place and applies its state.
func attach(walls: TileMapLayer, frame_cells: Vector2i) -> void:
	_walls = walls
	_frame_cells = frame_cells
	position = center_for(side, frame_cells)
	_apply()


## The wall tiles of this door, in frame coordinates.
func cells() -> Array[Vector2i]:
	return cells_for(side, _frame_cells)


## Shuts the door (a fight begins). A sealed door stays as it is.
func close() -> void:
	_set_state(State.CLOSED)


## Opens the door (the room is cleared). A sealed door stays as it is.
func open() -> void:
	_set_state(State.OPEN)


## No neighbour on this side: the door is a wall for good.
func seal() -> void:
	state = State.SEALED
	_apply()
	state_changed.emit(state)


func is_blocking() -> bool:
	return state != State.OPEN


func _set_state(next: State) -> void:
	if state == State.SEALED or state == next:
		return
	state = next
	_apply()
	state_changed.emit(state)


func _apply() -> void:
	if _walls == null:
		return
	for cell: Vector2i in cells():
		if is_blocking():
			_walls.set_cell(cell, WALL_SOURCE_ID, Vector2i.ZERO)
		else:
			_walls.erase_cell(cell)
	# Physics bodies of a TileMapLayer follow a cell change one step late: force them now, so the door is solid
	# (or free) on this very tick.
	_walls.update_internals()
