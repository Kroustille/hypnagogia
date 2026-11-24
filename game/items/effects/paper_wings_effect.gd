class_name PaperWingsEffect
extends ItemEffect
## Paper wings (story 5.6): the player flies over pits until a hit takes the wings away for a few seconds.
## Over a pit when the hit lands, the player falls back to the last safe cell, without the fall damage.

## Seconds of the player group left before the wings come back; 0 = flying.
var _suspended_left: float = 0.0


func required_params() -> Array[StringName]:
	return [&"suspend_seconds"]


func attach(new_carrier: BuildCarrier) -> void:
	if carrier != null:
		return
	super.attach(new_carrier)
	carrier.hit_taken.connect(_on_hit_taken)
	if _suspended_left <= 0.0:
		_grant_flight()


func detach() -> void:
	if carrier == null:
		return
	carrier.hit_taken.disconnect(_on_hit_taken)
	carrier.stats.clear_modifier(modifier_source(), StatBlock.Stat.CAN_FLY_OVER_PITS)
	wants_tick = false
	super.detach()


func tick(dt: float) -> void:
	if carrier == null or _suspended_left <= 0.0:
		return
	_suspended_left -= dt
	if _suspended_left <= 0.0:
		_suspended_left = 0.0
		wants_tick = false
		_grant_flight()


## True while a hit keeps the wings away.
func is_suspended() -> bool:
	return _suspended_left > 0.0


func _grant_flight() -> void:
	carrier.stats.set_modifier(modifier_source(), StatBlock.Stat.CAN_FLY_OVER_PITS, StatBlock.Kind.ADD_FLAT, 1.0)


func _on_hit_taken(_lost: int, _source: int) -> void:
	if carrier.player.health.is_dead():
		return
	_suspended_left = param(&"suspend_seconds")
	wants_tick = _suspended_left > 0.0
	carrier.stats.clear_modifier(modifier_source(), StatBlock.Stat.CAN_FLY_OVER_PITS)
	if _suspended_left <= 0.0:
		_grant_flight()
		return
	carrier.player.fall_if_over_pit()
