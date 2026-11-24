class_name SheepDef
extends EnemyDef
## Values of Le Mouton (FR29). Distances in tiles, speeds in tiles per second, durations in seconds.
## Neutral defaults (0): the values live in sheep.tres; a missing one is reported by the validation in _ready().

## Motionless rest between two attacks (after the spawn, after a stun, after a charge stopped by an enemy).
@export_range(0.0, 10.0, 0.05, "or_greater") var rest_duration: float = 0.0
## Duration of the scraping, before the backup (at least Tuning.COMBAT.min_telegraph).
@export_range(0.0, 10.0, 0.05, "or_greater") var telegraph_duration: float = 0.0
## Length of the backup, away from the charge direction.
@export_range(0.0, 10.0, 0.1, "or_greater") var backup_distance: float = 0.0
## Speed of the backup.
@export_range(0.0, 20.0, 0.1, "or_greater") var backup_speed: float = 0.0
## Speed of the charge.
@export_range(0.0, 40.0, 0.1, "or_greater") var charge_speed: float = 0.0
## Safety net: a charge that has covered this many tiles without touching anything stops, with no stun (story 4.3:
## a pit or an open door would let it run forever). 0 = no limit. Above the diagonal of a one-screen room.
@export_range(0.0, 200.0, 0.5, "or_greater") var max_charge_distance: float = 0.0
## Duration of the stun after hitting a wall.
@export_range(0.0, 10.0, 0.05, "or_greater") var stun_duration: float = 0.0
