class_name LucidityTuning
extends Resource
## Balancing values of the lucidity gauge. Read-only at runtime (see Tuning.LUCIDITY).
## Gain, spend and danger values join this Resource with the stories that need them (3.2 to 3.7).

## Top of the gauge: a run starts here and gains never go above it (FR16).
@export_range(1, 1000, 1, "or_greater") var max_value: int = 100
## Lowest value of each tier, in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon, Total abandon),
## strictly decreasing, the last one being 0 (FR17: 76, 51, 26, 1, 0).
@export var tier_floors: PackedInt32Array = PackedInt32Array([76, 51, 26, 1, 0])
