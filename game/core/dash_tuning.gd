class_name DashTuning
extends Resource
## Balancing values of the player's dash. Read-only at runtime (see Tuning.DASH).
## Distances are in tiles, durations in seconds: tick and pixel conversion happens in Dash.

## Tiles covered by a full dash.
@export_range(0.5, 10.0, 0.1, "or_greater") var distance: float = 3.0
## Seconds of movement.
@export_range(0.001, 1.0, 0.001, "or_greater") var duration: float = 0.18
## Seconds of invulnerability, counted from the start of the dash.
@export_range(0.0, 1.0, 0.001, "or_greater") var invulnerability_duration: float = 0.15
## Seconds of cooldown, counted from the end of the dash.
@export_range(0.0, 5.0, 0.01, "or_greater") var cooldown: float = 0.6
## Seconds before the end of the cooldown during which a press is remembered.
@export_range(0.0, 1.0, 0.01, "or_greater") var input_buffer: float = 0.1
