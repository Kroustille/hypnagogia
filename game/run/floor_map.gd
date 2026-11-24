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
