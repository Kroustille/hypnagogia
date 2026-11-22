class_name SleepwalkerDef
extends EnemyDef
## Values of Le Somnambule (FR27). Distances in tiles, speeds in tiles per second, durations in seconds.
## Neutral defaults (0): the values live in sleepwalker.tres; a missing one is reported by the validation in _ready().

## Walking speed toward the player.
@export_range(0.0, 20.0, 0.1, "or_greater") var walk_speed: float = 0.0
## Distance under which it raises its arms (center to center).
@export_range(0.0, 20.0, 0.1, "or_greater") var rush_trigger_range: float = 0.0
## Duration of the raised arms, before the rush (at least Tuning.COMBAT.min_telegraph).
@export_range(0.0, 10.0, 0.05, "or_greater") var telegraph_duration: float = 0.0
## Speed of the rush.
@export_range(0.0, 40.0, 0.1, "or_greater") var rush_speed: float = 0.0
## Duration of the rush.
@export_range(0.0, 10.0, 0.05, "or_greater") var rush_duration: float = 0.0
