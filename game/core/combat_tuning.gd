class_name CombatTuning
extends Resource
## Balancing values of health, hits, telegraphs and spawns. Read-only at runtime (see Tuning.COMBAT).
## Hearts are stored in half-hearts (integers): Health counts in whole half-hearts, no conversion needed.
## Durations are in seconds, distances in tiles; tick conversion happens in Health and Telegraph.

## Half-hearts the player starts a run with (3 hearts).
@export_range(1, 48, 1, "or_greater") var starting_half_hearts: int = 6
## Cap of heart containers plus armor, in half-hearts (12 hearts, armor included).
@export_range(1, 48, 1, "or_greater") var heart_cap_half_hearts: int = 24
## Half-hearts removed by a basic hit (floors 1 and 2).
@export_range(1, 48, 1, "or_greater") var hit_damage_half_hearts: int = 1
## Invulnerability after a hit, in seconds.
@export_range(0.0, 10.0, 0.05, "or_greater") var hit_invulnerability_duration: float = 1.0
## Shortest telegraph of any enemy attack, in seconds (FR26: also under the danger multiplier, Abandon included).
@export_range(0.0, 5.0, 0.05, "or_greater") var min_telegraph: float = 0.4
## Closest an enemy may appear to the player, in tiles (FR31), center to center.
@export_range(0.0, 20.0, 0.25, "or_greater") var min_spawn_distance: float = 3.0
