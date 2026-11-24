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
## Radius of the lamp's dazzle around it, in tiles, measured center to center (story 4.4).
@export_range(0.5, 10.0, 0.25, "or_greater") var lamp_radius_tiles: float = 3.0
## Seconds a dazzled enemy stands still without attacking (story 4.4).
@export_range(0.1, 10.0, 0.1, "or_greater") var lamp_dazzle_duration: float = 1.0
## Seconds of each half of the fade to black between two rooms (story 4.8): to black, then back.
@export_range(0.0, 2.0, 0.01, "or_greater") var transition_duration: float = 0.12
## Seconds between the death of a boss and the end of the run by victory (story 6.4): the player cannot be hurt meanwhile.
@export_range(0.0, 10.0, 0.1, "or_greater") var boss_victory_delay: float = 2.0
