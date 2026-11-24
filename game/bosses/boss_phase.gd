class_name BossPhase
extends Resource
## One phase of a boss (an "épreuve"): the title written on the blackboard, the share of hit points from which it
## applies, and its attacks. Phases of a BossDef are sorted by decreasing hp_from.

const MIN_ALTERNATE_SECONDS: float = 1.0

## Translation key of the chalk title.
@export var title_key: StringName = &""
## The phase applies while the hit points are at or under this share of the maximum (1.0 = from the start).
@export_range(0.0, 1.0, 0.01) var hp_from: float = 1.0
## Every group of the phase runs at once, unless alternate_seconds is set.
@export var groups: Array[BossAttackSet] = []
## Seconds each group runs before the next one takes over, in order and in a loop, starting with the first (0 = all the
## groups run at once). The attacks that leave stop; their chalks in flight go on.
@export_range(0.0, 60.0, 0.5, "or_greater") var alternate_seconds: float = 0.0
## Attacks that run during the whole phase, whatever group is active (the Professor's ruler).
@export var extras: Array[BossAttack] = []


## The attacks of all the groups, in order (the extras not included).
func attacks() -> Array[BossAttack]:
	var found: Array[BossAttack] = []
	for group: BossAttackSet in groups:
		if group != null:
			found.append_array(group.attacks)
	return found


## The attacks of one group, empty for an index out of range.
func group_attacks(index: int) -> Array[BossAttack]:
	var found: Array[BossAttack] = []
	if index >= 0 and index < groups.size() and groups[index] != null:
		found.append_array(groups[index].attacks)
	return found


## True when the groups take turns.
func alternates() -> bool:
	return alternate_seconds > 0.0 and groups.size() > 1


## "" when the phase is playable, else why not.
func validate() -> String:
	if not is_finite(alternate_seconds) or alternate_seconds < 0.0:
		return "alternate_seconds %s must be finite and >= 0" % alternate_seconds
	if alternate_seconds > 0.0 and alternate_seconds < MIN_ALTERNATE_SECONDS:
		return "alternate_seconds %s is under %s: the groups would swap every few ticks" % [alternate_seconds, MIN_ALTERNATE_SECONDS]
	if alternate_seconds > 0.0 and groups.size() < 2:
		return "alternate_seconds needs at least two groups"
	for attack: BossAttack in attacks() + extras:
		if attack == null:
			return "a null attack"
		var problem: String = attack.validate()
		if not problem.is_empty():
			return problem
	return ""
