class_name EconomyTuning
extends Resource
## Balancing values of the shards and the drops (story 5.4). Read-only at runtime (see Tuning.ECONOMY).
## The shop prices join this Resource with story 5.5.

## Shards a cleared combat room gives before the tier multiplier (drawn between the two, both included).
@export_range(0, 100, 1, "or_greater") var shards_min: int = 1
@export_range(0, 100, 1, "or_greater") var shards_max: int = 3
## Chance (0 to 1) that a cleared combat room leaves a drop, before the tier multiplier of the loot.
@export_range(0.0, 1.0, 0.01) var drop_chance: float = 0.3
## Shards of a "shards" drop.
@export_range(1, 100, 1, "or_greater") var shard_drop_amount: int = 3
## Half-hearts a heart drop heals, half-hearts of armor an armor drop gives.
@export_range(1, 10, 1, "or_greater") var heart_drop_half_hearts: int = 1
@export_range(1, 10, 1, "or_greater") var armor_drop_half_hearts: int = 1
