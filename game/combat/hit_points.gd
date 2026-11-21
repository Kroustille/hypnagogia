class_name HitPoints
extends RefCounted
## Hit points of an enemy (floats: enemies count HP, the player counts half-hearts in Health).
## No armor, no invulnerability: a dead owner refuses every hit. Runtime state: the EnemyDef stays read-only.

var current: float = 0.0
var maximum: float = 0.0


## max_hp not finite or <= 0: bounded to 1 with Log.error + assert (AR28).
func _init(max_hp: float) -> void:
	var valid: bool = is_finite(max_hp) and max_hp > 0.0
	var safe: float = max_hp if valid else 1.0
	maximum = safe # set before the assert: a failed assert aborts the rest of the function in debug builds
	current = safe
	if not valid:
		Log.error("combat", "invalid max hp %s, bounded to %s" % [max_hp, safe])
		assert(false, "HitPoints needs a finite max_hp > 0")


## Returns the HP removed (at most current). 0 when dead, or when amount is not finite or <= 0
## (Log.error + assert: a refused hit).
func apply_damage(amount: float) -> float:
	if is_dead():
		return 0.0
	if not is_finite(amount) or amount <= 0.0:
		Log.error("combat", "invalid damage amount %s on hit points" % amount)
		assert(false, "Invalid hit points damage amount")
		return 0.0
	var removed: float = minf(amount, current)
	current -= removed
	return removed


func is_dead() -> bool:
	return current <= 0.0
