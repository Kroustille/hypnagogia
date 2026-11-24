extends Node
## Per-group time scale. Gameplay code multiplies its delta by scale(group).
## Never use Engine.time_scale, Timer nodes or create_timer() for gameplay.

enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }


## One timed slow (story 5.8): a factor on some groups until its seconds run out.
class Slow extends RefCounted:
	var token: Object
	var groups: Array[int] = []
	var factor: float = 1.0
	## Real seconds left (physics delta times global_multiplier); frozen while paused.
	var seconds_left: float = 0.0


var paused: bool = false
## Global time multiplier, composed with every group scale. Debug slow motion (F4) uses it.
## Clamped to [0, 1]: a scale above 1 is not a supported case (see deferred-work, story 1.2).
var global_multiplier: float = 1.0:
	set(value):
		global_multiplier = clampf(value, 0.0, 1.0)
## Product of the active slows, per group (1.0 without any).
var _scales: Dictionary[Group, float] = {}
var _slows: Array[Slow] = []


func _init() -> void:
	for group: Group in Group.values():
		_scales[group] = 1.0


func _ready() -> void:
	Events.run_started.connect(reset_slows)
	Events.run_ended.connect(_on_events_run_ended)


func _physics_process(delta: float) -> void:
	if paused or _slows.is_empty():
		return
	var elapsed: float = delta * global_multiplier
	var expired: bool = false
	for slow: Slow in _slows:
		slow.seconds_left -= elapsed
		expired = expired or slow.seconds_left <= 0.0
	if expired:
		for index: int in range(_slows.size() - 1, -1, -1):
			if _slows[index].seconds_left <= 0.0:
				_slows.remove_at(index)
		_recompute()


func scale(group: Group) -> float:
	return 0.0 if paused else _scales[group] * global_multiplier


## Slows these groups to factor (0..1) for seconds. One slow per token: the same token again restarts it. Slows of
## different tokens multiply. The duration counts real physics time (not the slowed time), frozen while paused.
func apply_slow(token: Object, groups: Array[Group], factor: float, seconds: float) -> void:
	assert(token != null and seconds > 0.0 and factor >= 0.0 and factor <= 1.0, "invalid slow")
	clear_slow(token)
	var slow: Slow = Slow.new()
	slow.token = token
	for group: Group in groups:
		slow.groups.append(group)
	slow.factor = factor
	slow.seconds_left = seconds
	_slows.append(slow)
	_recompute()


## Ends the slow of this token, if any.
func clear_slow(token: Object) -> void:
	for index: int in range(_slows.size()):
		if _slows[index].token == token:
			_slows.remove_at(index)
			_recompute()
			return


## Ends every slow (a new run, the end of a run).
func reset_slows() -> void:
	_slows.clear()
	_recompute()


## The slows running now (checks).
func slow_count() -> int:
	return _slows.size()


func _recompute() -> void:
	for group: Group in Group.values():
		_scales[group] = 1.0
	for slow: Slow in _slows:
		for group: int in slow.groups:
			_scales[group as Group] *= slow.factor


func _on_events_run_ended(_outcome: int) -> void:
	reset_slows()
