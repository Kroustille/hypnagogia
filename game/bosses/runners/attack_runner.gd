class_name AttackRunner
extends RefCounted
## Runs one BossAttack for a Boss (D2: the state of an attack lives here, never in the shared Resource). It has no clock
## of its own: the boss calls tick() once per physics tick with the clock scale of the ENEMIES group and the room's pace.
## One subclass per BossAttack.Kind; make() is the only place that maps a kind to its runner.

var _boss: Boss
var _attack: BossAttack


## Null, with a Log.error, for a kind that has no runner.
static func make(attack: BossAttack) -> AttackRunner:
	if attack == null:
		Log.error("combat", "no attack to run")
		return null
	match attack.kind:
		BossAttack.Kind.ROW:
			return RowRunner.new()
	Log.error("combat", "no runner for the attack kind %d" % attack.kind)
	return null


func setup(boss: Boss, attack: BossAttack) -> void:
	_boss = boss
	_attack = attack


## clock_step: GameClock.scale(ENEMIES) (the telegraph counts in it only, the minimum telegraph is in real seconds of
## game time); pace: Room.danger.pace_mult (the cadence only). Overridden by each kind.
func tick(_clock_step: float, _pace: float) -> void:
	pass


## Drops what is pending (a sign on screen, a row about to appear). The boss calls it on a phase change, a death, the
## end of the run. A stopped runner never fires again.
func stop() -> void:
	pass
