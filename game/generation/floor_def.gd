class_name FloorDef
extends Resource
## Parameters of the floor of one phase (story 4.7): what it holds and how the generator may lay it out. No value of
## this kind lives in the generator.

## Phase of the night (the folder of the room pool is rooms/pool/<phase>).
@export var phase: StringName = &"onset"
## Folder searched for the pre-drawn rooms.
@export_dir var pool_dir: String = "res://rooms/pool/onset"
## Rooms of each kind besides the start room (one start room is always placed).
@export_range(0, 40, 1) var combat_rooms: int = 12
@export_range(0, 4, 1) var treasure_rooms: int = 1
@export_range(0, 4, 1) var shop_rooms: int = 1
@export_range(0, 4, 1) var nightmare_rooms: int = 1
## The nightmare room is at least this many connections from the start.
@export_range(1, 20, 1) var min_nightmare_distance: int = 4
## Bounds of the grid, in cells (one room = one cell).
@export_range(3, 30, 1) var grid_width: int = 9
@export_range(3, 30, 1) var grid_height: int = 7
## Chance, for each pair of adjacent start/combat rooms left unconnected, of getting a connection (a loop).
@export_range(0.0, 1.0, 0.05) var loop_chance: float = 0.2
## New draws of the layout allowed when the constraints cannot be met, before the floor is declared invalid.
@export_range(1, 1000, 1) var max_attempts: int = 100


## Rooms of the floor, start room included.
func total_rooms() -> int:
	return 1 + combat_rooms + treasure_rooms + shop_rooms + nightmare_rooms
