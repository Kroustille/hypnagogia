class_name GlideTuning
extends Resource
## Balancing values of the Glide power (story 3.4). Read-only at runtime (see Tuning.GLIDE).

## Lucidity spent by one use.
@export_range(1, 1000, 1, "or_greater") var cost: int = 20
## Seconds before Glide can be used again, counted in game time.
@export_range(0.0, 30.0, 0.05, "or_greater") var cooldown: float = 1.0
## Farthest destination from the player (tiles): cursor beyond it, or stick at full tilt.
@export_range(0.5, 20.0, 0.1, "or_greater") var max_distance: float = 6.0
## Distance with the stick just past its dead zone, or released (tiles).
@export_range(0.0, 20.0, 0.1, "or_greater") var min_stick_distance: float = 2.0
## Invulnerability after arriving (seconds, game time). Ordinary invulnerability: no graze, no perfect dash.
@export_range(0.0, 5.0, 0.05, "or_greater") var arrival_invulnerability: float = 0.1
## A trip shorter than this (tiles) is refused without spending anything.
@export_range(0.0, 5.0, 0.05, "or_greater") var min_travel: float = 0.5
