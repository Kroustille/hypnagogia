class_name SpriteKick
extends RefCounted
## Offsets a Node2D (a sprite) for a short time, then puts it back at Vector2.ZERO.
## Counted in game ticks: the owner calls tick(clock_scale) from its _physics_process.
## Writes sprite.position only (offset and modulate stay free for other effects).

## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _sprite: Node2D
var _offset: Vector2 = Vector2.ZERO
var _ticks_left: float = 0.0


func _init(sprite: Node2D) -> void:
	_sprite = sprite


## Starts a kick. Replaying restarts it, without adding the offsets. A ZERO direction does not move.
func kick(direction: Vector2, distance_px: float, duration: float) -> void:
	_ticks_left = maxf(duration, 0.0) * Engine.physics_ticks_per_second
	_offset = direction * maxf(distance_px, 0.0)
	if _ticks_left <= TICK_EPSILON:
		_reset()
		return
	_sprite.position = _offset


func tick(clock_scale: float) -> void:
	if _ticks_left <= 0.0:
		return
	_ticks_left -= clock_scale
	if _ticks_left <= TICK_EPSILON:
		_reset()


func is_active() -> bool:
	return _ticks_left > 0.0


func _reset() -> void:
	_ticks_left = 0.0
	_offset = Vector2.ZERO
	_sprite.position = Vector2.ZERO
