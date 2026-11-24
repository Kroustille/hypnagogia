class_name BossDef
extends EnemyDef
## A boss (AR7, D4): an EnemyDef plus its phases. Every combat value lives in the .tres.

## Seconds the boss waits after it appears, while its title is written, before it attacks.
@export_range(0.0, 10.0, 0.1, "or_greater") var announce_duration: float = 0.0
## Sorted by decreasing hp_from; the first one applies from the start.
@export var phases: Array[BossPhase] = []
## Translation key of the name shown on the health bar.
@export var name_key: StringName = &""
