class_name EnemySpawn
extends Marker2D
## Where an enemy of a pre-drawn room appears (story 4.2). Child of the room's EnemySpawns node; the position is in
## room coordinates (origin = top-left corner of the wall frame). The room turns its markers into waves on entry.

## The enemy to spawn. A marker without one is reported by the room validator.
@export var enemy: EnemyDef
## Index of the wave this enemy belongs to, from 0.
@export_range(0, 20, 1) var wave: int = 0
