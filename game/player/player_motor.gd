class_name PlayerMotor
extends RefCounted
## Pure speed logic of the player: no node, no scene, no clock.
## The caller passes the real physics delta and applies the GameClock scale to the returned velocity.

## Technical floor for the acceleration and deceleration durations: never divide by zero.
const MIN_RAMP_TIME: float = 0.001

## Current velocity in px/s. Read-only for the outside.
var velocity: Vector2 = Vector2.ZERO

var _max_speed_px: float = 0.0
var _accel_px: float = 0.0
var _decel_px: float = 0.0
## Ramp durations kept (bounded) so a new maximum speed keeps the same feel.
var _acceleration_time: float = MIN_RAMP_TIME
var _deceleration_time: float = MIN_RAMP_TIME


func _init(tuning: PlayerTuning) -> void:
	# The safe values are stored first: in a debug build the assert below may abort _validate_time().
	_acceleration_time = maxf(tuning.acceleration_time, MIN_RAMP_TIME)
	_deceleration_time = maxf(tuning.deceleration_time, MIN_RAMP_TIME)
	set_max_speed(tuning.move_speed)
	_validate_time(tuning.acceleration_time, "acceleration_time")
	_validate_time(tuning.deceleration_time, "deceleration_time")


## New maximum speed in tiles per second (the MOVE_SPEED stat); the ramp durations stay the same, the velocity in
## progress is kept.
func set_max_speed(tiles_per_s: float) -> void:
	_max_speed_px = maxf(tiles_per_s, 0.0) * Const.TILE_SIZE
	_accel_px = _max_speed_px / _acceleration_time
	_decel_px = _max_speed_px / _deceleration_time


## Advances the velocity by dt seconds toward the wished direction and returns it (px/s).
## wish comes from Input.get_vector (length <= 1).
func step(wish: Vector2, dt: float) -> Vector2:
	var target: Vector2 = wish * _max_speed_px
	var rate: float = _accel_px if wish != Vector2.ZERO else _decel_px
	velocity = velocity.move_toward(target, rate * dt)
	return velocity


## Drops the speed (a fall back to a safe place).
func reset() -> void:
	velocity = Vector2.ZERO


func _validate_time(value: float, field: String) -> void:
	if value < MIN_RAMP_TIME:
		Log.error("input", "PlayerTuning.%s is %s, using %s" % [field, value, MIN_RAMP_TIME])
		assert(false, "Invalid PlayerTuning duration")
