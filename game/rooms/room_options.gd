class_name RoomOptions
extends RefCounted
## How a room is entered on a floor (story 4.8). Given to Room.setup() before add_child(). A room set up without it
## behaves as a stand-alone room: its doors as painted, a fight on entry, the player in the middle.

## The cell of the floor the room occupies.
var cell: Vector2i = Vector2i.ZERO
## True when link_sides tells which doors lead somewhere: the others are sealed (no door opens on the void).
var use_links: bool = false
## Door.Side values of the doors that connect to a neighbour room.
var link_sides: Array[int] = []
## The fight of this room was won on an earlier visit: doors open, nobody appears, nothing is announced again.
var already_cleared: bool = false
## Door.Side the player comes in by, -1 for the middle of the room (first room of a run).
var entry_side: int = -1
## What lies in the room (items to pick up); null for a stand-alone room, which then makes its own.
var stock: RoomStock
