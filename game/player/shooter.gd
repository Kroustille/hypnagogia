class_name Shooter
extends RefCounted
## Pure fire rate logic of the player: no node, no scene. Counted in game ticks (clock_scale per physics tick).
## Firing is a held state, with no input buffer: a short press during the cooldown is lost.
## The cooldown runs at all times, during a dash too, so the rate never exceeds fire_rate however fast one clicks.

## Technical floor for the fire rate: never divide by zero.
const MIN_FIRE_RATE: float = 0.01
## Margin against floating point rounding when comparing the cooldown to zero.
const TICK_EPSILON: float = 1e-6

var _period_ticks: float = 0.0
var _cooldown_left: float = 0.0


func _init(tuning: ShotTuning) -> void:
	# The safe value is stored first: in a debug build the assert below may abort.
	var fire_rate: float = maxf(tuning.fire_rate, MIN_FIRE_RATE)
	_period_ticks = Engine.physics_ticks_per_second / fire_rate
	if not (tuning.fire_rate >= MIN_FIRE_RATE):
		Log.error("combat", "ShotTuning.fire_rate is %s, using %s" % [tuning.fire_rate, MIN_FIRE_RATE])
		assert(false, "Invalid ShotTuning fire_rate")


## Advances one physics tick. Returns true when one shot must be emitted on this tick.
## blocked (dash) prevents the shot but does not freeze the cooldown.
func tick(clock_scale: float, wants_fire: bool, blocked: bool) -> bool:
	if clock_scale <= 0.0:
		return false
	var was_cooling: bool = _cooldown_left > 0.0
	_cooldown_left -= clock_scale
	if wants_fire and not blocked and _cooldown_left <= TICK_EPSILON:
		# When the cooldown ends inside this tick, its overshoot (less than one tick) is carried over, so a
		# fractional period (8 shots/s = 7.5 ticks) keeps its exact average rate. A cooldown that was already
		# over carries nothing: waiting never builds up a burst.
		var carried: float = minf(_cooldown_left, 0.0) if was_cooling else 0.0
		_cooldown_left = carried + _period_ticks
		return true
	_cooldown_left = maxf(_cooldown_left, 0.0)
	return false
