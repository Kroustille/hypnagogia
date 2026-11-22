class_name LullabyDef
extends ShooterDef
## Values of La Berceuse (FR30), on top of the shooter values. Distances in tiles, speed in tiles per second.
## Neutral defaults (0): the values live in lullaby.tres; a missing one is reported by the validation in _ready().

## Closest it stays to the player (center to center): closer, it walks away.
@export_range(0.0, 30.0, 0.5, "or_greater") var min_distance: float = 0.0
## Farthest it stays from the player (center to center): farther, it walks closer.
@export_range(0.0, 30.0, 0.5, "or_greater") var max_distance: float = 0.0
## Walking speed, toward or away from the player.
@export_range(0.0, 20.0, 0.1, "or_greater") var move_speed: float = 0.0
