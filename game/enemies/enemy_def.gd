class_name EnemyDef
extends Resource
## What every enemy has in common (AR9, D4). Each enemy adds its own values in a subclass (SleepwalkerDef...).
## Read-only at runtime: one Def is shared by every enemy of its kind. Distances in tiles, durations in seconds;
## the conversion to pixels happens once, in the enemy's setup()/_ready().

## Identifier for logs, waves (story 2.6) and telemetry (story 2.8).
@export var id: StringName = &""
## Scene instantiated by room.spawn_enemy().
@export var scene: PackedScene
## Hit points (FR27).
@export_range(1.0, 1000.0, 1.0, "or_greater") var max_hp: float = 30.0
## Physical body, in tiles: blocks and is blocked by walls, the player and other enemies.
@export var body_size: Vector2 = Vector2(0.625, 0.625)
## Zone the player's shots hit, in tiles.
@export var hurtbox_size: Vector2 = Vector2(0.75, 1.25)
## Contact damage zone, in tiles. Larger than the body: bodies block each other, so a zone of the body's size would never touch.
@export var contact_size: Vector2 = Vector2(0.75, 0.75)
