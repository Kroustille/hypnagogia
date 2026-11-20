class_name PlayerMotor
extends RefCounted
## Pure speed logic of the player: no node, no scene, no clock.
## The caller passes a delta that is already scaled by GameClock.

## Technical floor for the acceleration and deceleration durations: never divide by zero.
const MIN_RAMP_TIME: float = 0.001

## Current velocity in px/s. Read-only for the outside.
var velocity: Vector2 = Vector2.ZERO

var _max_speed_px: float = 0.0
var _accel_px: float = 0.0
var _decel_px: float = 0.0


func _init(tuning: PlayerTuning) -> void:
	var acceleration_time: float = _safe_time(tuning.acceleration_time, "acceleration_time")
	var deceleration_time: float = _safe_time(tuning.deceleration_time, "deceleration_time")
	_max_speed_px = tuning.move_speed * Const.TILE_SIZE
	_accel_px = _max_speed_px / acceleration_time
	_decel_px = _max_speed_px / deceleration_time


## Advances the velocity by dt seconds toward the wished direction and returns it (px/s).
## wish comes from Input.get_vector (length <= 1).
func step(wish: Vector2, dt: float) -> Vector2:
	var target: Vector2 = wish * _max_speed_px
	var rate: float = _accel_px if wish != Vector2.ZERO else _decel_px
	velocity = velocity.move_toward(target, rate * dt)
	return velocity


func _safe_time(value: float, field: String) -> float:
	if value < MIN_RAMP_TIME:
		Log.error("input", "PlayerTuning.%s is %s, using %s" % [field, value, MIN_RAMP_TIME])
		assert(false, "Invalid PlayerTuning duration")
		return MIN_RAMP_TIME
	return value
