class_name RingPulse
extends Node2D
## Placeholder ring that widens and fades around a point (story 3.3), until epic 7. No full-screen flash.
## Counted in game ticks of GameClock.Group.FX in _physics_process, then frees itself.

const RING_WIDTH: float = 2.0
const MAX_ALPHA: float = 0.8
const POINT_COUNT: int = 48
## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _max_radius: float = 0.0
var _color: Color = Color.WHITE
var _ticks_total: float = 1.0
var _ticks_elapsed: float = 0.0


## Call before add_child(). radius in pixels, duration in seconds.
func setup(max_radius: float, color: Color, duration: float) -> void:
	_max_radius = max_radius
	_color = color
	_ticks_total = maxf(duration * Engine.physics_ticks_per_second, 1.0)


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _physics_process(_delta: float) -> void:
	_ticks_elapsed += GameClock.scale(GameClock.Group.FX)
	if _ticks_elapsed >= _ticks_total - TICK_EPSILON:
		queue_free()
		return
	queue_redraw()


## Fraction of the lifetime elapsed, 0..1.
func progress() -> float:
	return clampf(_ticks_elapsed / _ticks_total, 0.0, 1.0)


func _draw() -> void:
	var t: float = progress()
	var color: Color = Color(_color, MAX_ALPHA * (1.0 - t))
	draw_arc(Vector2.ZERO, maxf(_max_radius * t, 1.0), 0.0, TAU, POINT_COUNT, color, RING_WIDTH)
