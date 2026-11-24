class_name PowerCooldown
extends RefCounted
## Recharge of a power, counted in game ticks like Dash: clock_scale per physics tick (1.0 normal, 0.25 under F4,
## 0.0 paused). No Timer, no accumulated delta.

var _total_ticks: float = 0.0
var _left: float = 0.0


## Starts the recharge. The duration in seconds is converted to physics ticks here.
func start(seconds: float) -> void:
	_total_ticks = maxf(seconds, 0.0) * Engine.physics_ticks_per_second
	_left = _total_ticks


## Advances by one physics tick.
func tick(clock_scale: float) -> void:
	if _left > 0.0:
		_left = maxf(_left - clock_scale, 0.0)


func is_ready() -> bool:
	return _left <= 0.0


## 0.0 just after start(), 1.0 when ready.
func progress() -> float:
	if _total_ticks <= 0.0:
		return 1.0
	return 1.0 - _left / _total_ticks
