class_name LucidityTuning
extends Resource
## Balancing values of the lucidity gauge. Read-only at runtime (see Tuning.LUCIDITY).
## Gain, spend and danger values join this Resource with the stories that need them (3.2 to 3.7).

## Top of the gauge: a run starts here and gains never go above it (FR16).
@export_range(1, 1000, 1, "or_greater") var max_value: int = 100
## Lowest value of each tier, in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon, Total abandon),
## strictly decreasing, the last one being 0 (FR17: 76, 51, 26, 1, 0).
@export var tier_floors: PackedInt32Array = PackedInt32Array([76, 51, 26, 1, 0])

## Distance from the player's hurtbox rectangle under which a passing enemy bullet is a graze (tiles, FR22).
@export_range(0.1, 5.0, 0.05, "or_greater") var graze_radius: float = 1.0
## Lucidity gained by a graze.
@export_range(0, 100, 1, "or_greater") var graze_gain: int = 2
## Lucidity gained when the dash invulnerability avoids a bullet that would have hit (per bullet).
@export_range(0, 100, 1, "or_greater") var perfect_dash_gain: int = 5
## Lucidity gained when the room is cleared (a wave is emptied).
@export_range(0, 100, 1, "or_greater") var room_cleared_gain: int = 5
## Most lucidity grazes can give since Lucidity.begin_room().
@export_range(0, 1000, 1, "or_greater") var graze_cap_per_room: int = 20
