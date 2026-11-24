class_name ReinforcementSign
extends Node2D
## Placeholder announcement of a reinforcement (story 3.7), until epic 7: a circle that tightens on the spot where the
## enemy will appear. No flash. Counted in game ticks of GameClock.Group.ENEMIES, like the countdown it announces.
## The Arena owns it and frees it when the enemy appears (or when the wave ends).

const LINE_WIDTH: float = 2.0
const MIN_ALPHA: float = 0.35
const MAX_ALPHA: float = 0.9
const POINT_COUNT: int = 40
const DOT_RADIUS: float = 2.0
const TICK_EPSILON: float = 1e-6

var _start_radius: float = 0.0
var _color: Color = Color.WHITE
var _ticks_total: float = 1.0
var _ticks_elapsed: float = 0.0


## Call before add_child(). radius in pixels, duration in seconds.
func setup(start_radius: float, color: Color, duration: float) -> void:
	_start_radius = start_radius
	_color = color
	_ticks_total = maxf(duration * Engine.physics_ticks_per_second, 1.0)


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _physics_process(_delta: float) -> void:
	_ticks_elapsed = minf(_ticks_elapsed + GameClock.scale(GameClock.Group.ENEMIES), _ticks_total)
	queue_redraw()


## Fraction of the countdown elapsed, 0..1.
func progress() -> float:
	return clampf(_ticks_elapsed / _ticks_total, 0.0, 1.0)


func _draw() -> void:
	var t: float = progress()
	var color: Color = Color(_color, lerpf(MIN_ALPHA, MAX_ALPHA, t))
	draw_arc(Vector2.ZERO, maxf(_start_radius * (1.0 - t), DOT_RADIUS), 0.0, TAU, POINT_COUNT, color, LINE_WIDTH)
	draw_circle(Vector2.ZERO, DOT_RADIUS, color)
