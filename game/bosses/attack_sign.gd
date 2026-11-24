class_name AttackSign
extends Node2D
## The sign of a chalk attack (FR26): what the boss draws on the room before it strikes. Shapes: ROW (a band where the row
## will appear, its gap lit), BAND (a plain rectangle: where the ruler starts), LINE_ARROW (a line ending in an arrowhead:
## the direction of a ruler, the aim of a fan), RING (a ring around a point: the spiral starts). Owned by the runner that
## made it: the runner gives the progress of its own countdown (no clock here) and frees it. Added under the room.

enum Shape { ROW, BAND, LINE_ARROW, RING }

const BAND_HEIGHT_PX: float = 12.0
const BAND_COLOR: Color = Color(0.9, 0.9, 0.95, 0.35)
const GAP_COLOR: Color = Color(0.85, 1.0, 0.8, 0.5)
const LINE_COLOR: Color = Color(0.95, 0.9, 0.7, 0.8)
const LINE_WIDTH_PX: float = 2.0
const ARROW_HEAD_PX: float = 8.0
const RING_WIDTH_PX: float = 2.0

var _shape: Shape = Shape.ROW
var _band: Rect2 = Rect2()
var _gap_x: Vector2 = Vector2.ZERO
var _from: Vector2 = Vector2.ZERO
var _to: Vector2 = Vector2.ZERO
var _radius: float = 0.0
var _progress: float = 0.0


## ROW. band_x: left and right of the row, gap_x: left and right of the gap, y: center of the row; all in room pixels.
func setup(band_x: Vector2, gap: Vector2, y: float) -> void:
	_shape = Shape.ROW
	_band = Rect2(band_x.x, y - BAND_HEIGHT_PX / 2.0, band_x.y - band_x.x, BAND_HEIGHT_PX)
	_gap_x = gap
	_finish_setup()


## BAND: a rectangle in room pixels.
func setup_band(rect: Rect2) -> void:
	_shape = Shape.BAND
	_band = rect
	_finish_setup()


## LINE_ARROW: from one point to another, in room pixels (the head is at the second one).
func setup_arrow(from: Vector2, to: Vector2) -> void:
	_shape = Shape.LINE_ARROW
	_from = from
	_to = to
	_finish_setup()


## Moves the end of a LINE_ARROW (an aim that follows the player).
func set_arrow_end(to: Vector2) -> void:
	_to = to
	queue_redraw()


## RING: around a point, in room pixels.
func setup_ring(center: Vector2, radius: float) -> void:
	_shape = Shape.RING
	_from = center
	_radius = radius
	_finish_setup()


func shape() -> Shape:
	return _shape


## Rectangle of a ROW or BAND sign, in room pixels.
func band() -> Rect2:
	return _band


## Share of the telegraph elapsed, 0 to 1: the sign grows brighter.
func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func progress() -> float:
	return _progress


func _finish_setup() -> void:
	z_index = Const.Z_INDEX_COMBAT
	queue_redraw()


func _draw() -> void:
	var fade: float = 0.5 + 0.5 * _progress
	match _shape:
		Shape.ROW:
			draw_rect(_band, _faded(BAND_COLOR, fade))
			draw_rect(Rect2(_gap_x.x, _band.position.y, _gap_x.y - _gap_x.x, _band.size.y), _faded(GAP_COLOR, fade))
		Shape.BAND:
			draw_rect(_band, _faded(BAND_COLOR, fade))
		Shape.LINE_ARROW:
			var color: Color = _faded(LINE_COLOR, fade)
			var along: Vector2 = (_to - _from).normalized()
			draw_line(_from, _to, color, LINE_WIDTH_PX)
			draw_line(_to, _to - along.rotated(0.5) * ARROW_HEAD_PX, color, LINE_WIDTH_PX)
			draw_line(_to, _to - along.rotated(-0.5) * ARROW_HEAD_PX, color, LINE_WIDTH_PX)
		Shape.RING:
			draw_arc(_from, _radius * (1.0 - 0.3 * _progress), 0.0, TAU, 48, _faded(LINE_COLOR, fade), RING_WIDTH_PX)


static func _faded(color: Color, fade: float) -> Color:
	var faded: Color = color
	faded.a *= fade
	return faded
