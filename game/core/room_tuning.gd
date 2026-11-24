class_name RoomTuning
extends Resource
## Balancing values of the pre-drawn rooms (story 4.2). Read-only at runtime (see Tuning.ROOM).

## Width of a door opening along its side of the wall frame, in tiles.
@export_range(1, 6, 1) var door_width_tiles: int = 2
## Seconds between the player entering a pre-drawn room and its first wave.
@export_range(0.0, 10.0, 0.1, "or_greater") var first_wave_delay: float = 1.0
## Seconds between a wave being cleared and the next one in a pre-drawn room.
@export_range(0.0, 10.0, 0.1, "or_greater") var wave_pause: float = 2.0
## Where the player appears when entering a room, in tiles inside the door (read by story 4.8).
@export_range(1.0, 10.0, 0.25, "or_greater") var player_entry_distance: float = 3.0
