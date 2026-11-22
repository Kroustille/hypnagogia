class_name EnemyDef
extends Resource
## What every enemy has in common (AR9, D4). Each enemy adds its own values in a subclass (SleepwalkerDef...).
## Defaults are neutral (0): the GDD values live in the .tres, and a forgotten field is reported, not inherited.
## Read-only at runtime: one Def is shared by every enemy of its kind. Distances in tiles, durations in seconds;
## the conversion to pixels happens once, in the enemy's setup()/_ready().

## Identifier for logs, waves (story 2.6) and telemetry (story 2.8).
@export var id: StringName = &""
## Scene instantiated by room.spawn_enemy().
@export var scene: PackedScene
## Hit points (FR27). Neutral default: an enemy that forgets it is reported (HitPoints), never given another's value.
@export_range(0.0, 1000.0, 1.0, "or_greater") var max_hp: float = 0.0
## Physical body, in tiles: blocks and is blocked by walls, the player and other enemies.
@export var body_size: Vector2 = Vector2.ZERO
## Zone the player's shots hit, in tiles.
@export var hurtbox_size: Vector2 = Vector2.ZERO
## Contact damage zone, in tiles. Larger than the body: bodies block each other, so a zone of the body's size would never touch.
@export var contact_size: Vector2 = Vector2.ZERO
