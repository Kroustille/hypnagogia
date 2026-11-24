class_name FreeFallEffect
extends ItemEffect
## Free fall (story 5.6): the damage bonus grows by a step each full second without being hit, up to a cap. A hit
## (a fall into a pit included) takes half a heart more when the bonus is up, and the bonus starts over.

const EPSILON: float = 0.0001

## Seconds of the player group since the last hit.
var _elapsed: float = 0.0
var _bonus: float = 0.0


func required_params() -> Array[StringName]:
	return [&"rate", &"max_bonus", &"step_seconds"]


func attach(new_carrier: BuildCarrier) -> void:
	if carrier != null:
		return
	super.attach(new_carrier)
	wants_tick = true
	carrier.hit_incoming.connect(_on_hit_incoming)
	_apply(0.0)


func detach() -> void:
	if carrier == null:
		return
	carrier.hit_incoming.disconnect(_on_hit_incoming)
	carrier.stats.clear_modifier(modifier_source(), StatBlock.Stat.DAMAGE)
	wants_tick = false
	super.detach()


func tick(dt: float) -> void:
	if carrier == null:
		return
	_elapsed += dt
	var step: float = maxf(param(&"step_seconds"), EPSILON)
	var steps: float = floorf(_elapsed / step + EPSILON)
	_apply(minf(steps * param(&"rate"), param(&"max_bonus")))


## The bonus now (0 to max_bonus).
func bonus() -> float:
	return _bonus


func _apply(bonus_now: float) -> void:
	if is_equal_approx(bonus_now, _bonus):
		return
	_bonus = bonus_now
	if _bonus > 0.0:
		carrier.stats.set_modifier(modifier_source(), StatBlock.Stat.DAMAGE, StatBlock.Kind.ADD_PERCENT, _bonus)
	else:
		carrier.stats.clear_modifier(modifier_source(), StatBlock.Stat.DAMAGE)


func _on_hit_incoming(info: DamageInfo) -> void:
	if _bonus > 0.0:
		info.amount += 1.0
	_elapsed = 0.0
	_apply(0.0)
