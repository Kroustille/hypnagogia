class_name ShooterDef
extends EnemyDef
## Firing values shared by the shooters (La Veilleuse, La Berceuse). Speeds in tiles per second, durations in seconds,
## angles in degrees (converted in the code). Neutral defaults (0): the values live in the .tres files; a missing one
## is reported by the validation in ShooterEnemy._ready().

## Fire cycle: from one telegraph start to the next, so from one volley to the next.
@export_range(0.0, 20.0, 0.1, "or_greater") var fire_interval: float = 0.0
## Glow / inhale before the volley (at least Tuning.COMBAT.min_telegraph).
@export_range(0.0, 10.0, 0.05, "or_greater") var telegraph_duration: float = 0.0
## Speed of the bullets.
@export_range(0.0, 20.0, 0.1, "or_greater") var bullet_speed: float = 0.0
## Bullets per volley.
@export_range(0, 16, 1, "or_greater") var bullet_count: int = 0
## Angle between two neighbouring bullets of the fan, in degrees (the fan is centered on the target).
@export_range(0.0, 180.0, 0.5, "or_greater") var spread_angle: float = 0.0
