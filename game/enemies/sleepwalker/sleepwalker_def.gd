class_name SleepwalkerDef
extends EnemyDef
## Values of Le Somnambule (FR27). Distances in tiles, speeds in tiles per second, durations in seconds.

## Walking speed toward the player.
@export_range(0.0, 20.0, 0.1, "or_greater") var walk_speed: float = 2.5
## Distance under which it raises its arms (center to center).
@export_range(0.0, 20.0, 0.1, "or_greater") var rush_trigger_range: float = 2.0
## Duration of the raised arms, before the rush (at least Tuning.COMBAT.min_telegraph).
@export_range(0.0, 5.0, 0.05, "or_greater") var telegraph_duration: float = 0.4
## Speed of the rush.
@export_range(0.0, 40.0, 0.1, "or_greater") var rush_speed: float = 5.0
## Duration of the rush.
@export_range(0.0, 5.0, 0.05, "or_greater") var rush_duration: float = 0.6
