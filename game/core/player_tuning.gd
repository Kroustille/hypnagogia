class_name PlayerTuning
extends Resource
## Balancing values of the player's movement. Read-only at runtime (see Tuning.PLAYER).
## Distances are in tiles, durations in seconds: pixel conversion happens in PlayerMotor and Player.

## Maximum speed, in tiles per second.
@export_range(0.5, 20.0, 0.1, "or_greater") var move_speed: float = 6.0
## Seconds to go from standstill to maximum speed.
@export_range(0.001, 1.0, 0.001, "or_greater") var acceleration_time: float = 0.06
## Seconds to go from maximum speed to standstill.
@export_range(0.001, 1.0, 0.001, "or_greater") var deceleration_time: float = 0.04
## Side of the square hitbox, in tiles (0.375 tile = 6 px).
@export_range(0.0625, 2.0, 0.0625, "or_greater") var hitbox_size: float = 0.375
