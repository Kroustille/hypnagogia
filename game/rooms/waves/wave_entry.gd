class_name WaveEntry
extends Resource
## One line of a wave: an enemy kind and how many of it. Read-only at runtime.

@export var enemy: EnemyDef
@export_range(0, 50, 1, "or_greater") var count: int = 0
