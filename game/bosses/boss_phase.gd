class_name BossPhase
extends Resource
## One phase of a boss (an "épreuve"): the title written on the blackboard, the share of hit points from which it
## applies, and its attacks. Phases of a BossDef are sorted by decreasing hp_from.

## Translation key of the chalk title.
@export var title_key: StringName = &""
## The phase applies while the hit points are at or under this share of the maximum (1.0 = from the start).
@export_range(0.0, 1.0, 0.01) var hp_from: float = 1.0
## Every group of the phase runs at once.
@export var groups: Array[BossAttackSet] = []


## The attacks of all the groups, in order.
func attacks() -> Array[BossAttack]:
	var found: Array[BossAttack] = []
	for group: BossAttackSet in groups:
		if group != null:
			found.append_array(group.attacks)
	return found
