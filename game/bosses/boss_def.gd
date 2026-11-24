class_name BossDef
extends EnemyDef
## A boss (AR7, D4): an EnemyDef plus its phases. Every combat value lives in the .tres.

## Seconds the boss waits after it appears, while its title is written, before it attacks.
@export_range(0.0, 10.0, 0.1, "or_greater") var announce_duration: float = 0.0
## Sorted by decreasing hp_from; the first one applies from the start.
@export var phases: Array[BossPhase] = []
## Pop quiz: an attack that joins the fight for good once the room reaches Total abandon (DangerProfile.boss_extra_pattern).
## Null: this boss has none.
@export var extra_attack: BossAttack
## Translation key of the name shown on the health bar.
@export var name_key: StringName = &""


## "" when the whole def can fight, else the first problem found (phases, their attacks, the pop quiz).
func validate() -> String:
	for i: int in phases.size():
		if phases[i] == null:
			return "phase %d is null" % i
		var problem: String = phases[i].validate()
		if not problem.is_empty():
			return "phase %d: %s" % [i, problem]
	if extra_attack != null:
		var extra_problem: String = extra_attack.validate()
		if not extra_problem.is_empty():
			return "extra_attack: %s" % extra_problem
	return ""
