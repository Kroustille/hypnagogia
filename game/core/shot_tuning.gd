class_name ShotTuning
extends Resource
## Balancing values of the player's shot and of its impact feedback. Read-only at runtime (see Tuning.SHOT).
## Distances are in tiles, durations in seconds: pixel conversion happens in BulletManager.fire() for the
## bullet and in SpriteKick callers for the visual offsets; tick conversion happens in Shooter and HitFeedback.

## Damage per shot, in enemy HP.
@export_range(0.0, 100.0, 0.5, "or_greater") var damage: float = 10.0
## Shots per second.
@export_range(0.1, 30.0, 0.1, "or_greater") var fire_rate: float = 4.0
## Bullet speed, in tiles per second.
@export_range(0.1, 50.0, 0.1, "or_greater") var bullet_speed: float = 14.0
## Side of the shot hitbox, in tiles (0.25 tile = 4 px). The bullet collides as the inscribed circle.
@export_range(0.0, 2.0, 0.0625, "or_greater") var hitbox_size: float = 0.25
## Seconds before the bullet disappears. A safety net, not a range: walls stop every shot long before.
@export_range(0.1, 60.0, 0.1, "or_greater") var lifetime: float = 10.0
## Player sprite recoil on each shot, in tiles (0.0625 tile = 1 px).
@export_range(0.0, 1.0, 0.0625, "or_greater") var recoil_distance: float = 0.0625
## Duration of that recoil, in seconds.
@export_range(0.0, 1.0, 0.01, "or_greater") var recoil_duration: float = 0.05
## Duration of the white flash of a target hit by a shot, in seconds.
@export_range(0.0, 1.0, 0.01, "or_greater") var impact_flash_duration: float = 0.05
## Visual knockback of a target hit by a shot, in tiles (0.125 tile = 2 px).
@export_range(0.0, 1.0, 0.0625, "or_greater") var impact_knockback_distance: float = 0.125
## Duration of that knockback, in seconds.
@export_range(0.0, 1.0, 0.01, "or_greater") var impact_knockback_duration: float = 0.05
