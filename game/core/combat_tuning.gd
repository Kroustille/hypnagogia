class_name CombatTuning
extends Resource
## Balancing values of the player's health and of a basic hit. Read-only at runtime (see Tuning.COMBAT).
## Hearts are stored in half-hearts (integers): Health counts in whole half-hearts, no conversion needed.
## Durations are in seconds; tick conversion happens in Health.

## Half-hearts the player starts a run with (3 hearts).
@export_range(1, 48, 1, "or_greater") var starting_half_hearts: int = 6
## Cap of heart containers plus armor, in half-hearts (12 hearts, armor included).
@export_range(1, 48, 1, "or_greater") var heart_cap_half_hearts: int = 24
## Half-hearts removed by a basic hit (floors 1 and 2).
@export_range(1, 48, 1, "or_greater") var hit_damage_half_hearts: int = 1
## Invulnerability after a hit, in seconds.
@export_range(0.0, 10.0, 0.05, "or_greater") var hit_invulnerability_duration: float = 1.0
