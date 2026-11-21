class_name Dash
extends RefCounted
## Pure dash logic of the player: no node, no scene.
## Everything is counted in game ticks: one game tick is clock_scale at each physics tick
## (1.0 at normal speed, 0.25 under F4, 0.0 when paused). Durations come from DashTuning in seconds
## and are converted once, in _init. No Timer, no accumulated delta.

## Emitted by finish_tick(), after the movement of the dash.
signal ended

## Technical floor for the dash duration: never divide by zero.
const MIN_DURATION: float = 0.001
## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _duration_ticks: float = 0.0
var _invulnerability_ticks: float = 0.0
var _cooldown_ticks: float = 0.0
var _buffer_ticks: float = 0.0
var _speed_px_per_tick: float = 0.0

var _active: bool = false
var _invulnerable: bool = false
var _elapsed: float = 0.0
var _step: float = 0.0
var _direction: Vector2 = Vector2.ZERO
var _cooldown_left: float = 0.0
var _buffered: bool = false


func _init(tuning: DashTuning) -> void:
	# The safe values are stored first: in a debug build the assert below may abort _validate_duration().
	var ticks_per_second: float = Engine.physics_ticks_per_second
	var duration: float = maxf(tuning.duration, MIN_DURATION)
	_duration_ticks = duration * ticks_per_second
	_invulnerability_ticks = maxf(tuning.invulnerability_duration, 0.0) * ticks_per_second
	_cooldown_ticks = maxf(tuning.cooldown, 0.0) * ticks_per_second
	_buffer_ticks = maxf(tuning.input_buffer, 0.0) * ticks_per_second
	_speed_px_per_tick = maxf(tuning.distance, 0.0) * Const.TILE_SIZE / _duration_ticks
	_validate_duration(tuning.duration)


## Advances the dash by one physics tick. Call before move_and_slide().
## facing is a non-zero unit vector, frozen at the start of the dash. A buffered press keeps no direction:
## the dash leaves along the facing given on the tick it starts, not the one held when the press was made.
func tick(clock_scale: float, pressed: bool, facing: Vector2) -> void:
	if not _active and _cooldown_left > 0.0:
		_cooldown_left = maxf(_cooldown_left - clock_scale, 0.0)
	# While the clock is stopped (pause) nothing advances, so a press neither starts nor buffers a dash.
	if pressed and not _active and clock_scale > 0.0:
		if _cooldown_left <= 0.0:
			_start(facing)
		elif _cooldown_left <= _buffer_ticks:
			_buffered = true
	if not _active and _buffered and _cooldown_left <= 0.0:
		_start(facing)
	if _active:
		# Invulnerability follows the elapsed time before this tick's step: the tick that moves the player
		# first is covered, and the last tick of a short dash stays covered after finish_tick().
		_invulnerable = _elapsed < _invulnerability_ticks
		_step = minf(clock_scale, _duration_ticks - _elapsed)
		_elapsed += _step
	else:
		_invulnerable = false
		_step = 0.0


## Velocity in px/s to give to move_and_slide() for this tick, ZERO when inactive.
## move_and_slide() integrates with the unscaled physics delta, so the clock scale is already in _step.
func velocity(physics_delta: float) -> Vector2:
	if not _active or physics_delta <= 0.0:
		return Vector2.ZERO
	return _direction * _speed_px_per_tick * _step / physics_delta


## Closes the dash once its duration has elapsed. Call after move_and_slide().
func finish_tick() -> void:
	if _active and _elapsed >= _duration_ticks - TICK_EPSILON:
		_active = false
		_step = 0.0
		_cooldown_left = _cooldown_ticks
		ended.emit()


func is_active() -> bool:
	return _active


func is_invulnerable() -> bool:
	return _invulnerable


func _start(facing: Vector2) -> void:
	_active = true
	_elapsed = 0.0
	_direction = facing
	_buffered = false


func _validate_duration(value: float) -> void:
	if value < MIN_DURATION:
		Log.error("input", "DashTuning.duration is %s, using %s" % [value, MIN_DURATION])
		assert(false, "Invalid DashTuning duration")
