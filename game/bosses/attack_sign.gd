class_name AttackSign
extends Node2D
## The sign of a chalk row (FR26): a band where the row will appear, with its gap lit. Owned by the runner that made it:
## the runner gives the progress of its own countdown (no clock here) and frees it. Added under the room.

const BAND_HEIGHT_PX: float = 12.0
const BAND_COLOR: Color = Color(0.9, 0.9, 0.95, 0.35)
const GAP_COLOR: Color = Color(0.85, 1.0, 0.8, 0.5)

var _band: Rect2 = Rect2()
var _gap_x: Vector2 = Vector2.ZERO
var _progress: float = 0.0


## band_x: left and right of the row, gap_x: left and right of the gap, y: center of the row; all in room pixels.
func setup(band_x: Vector2, gap: Vector2, y: float) -> void:
	_band = Rect2(band_x.x, y - BAND_HEIGHT_PX / 2.0, band_x.y - band_x.x, BAND_HEIGHT_PX)
	_gap_x = gap
	z_index = Const.Z_INDEX_COMBAT
	queue_redraw()


## Share of the telegraph elapsed, 0 to 1: the sign grows brighter.
func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func progress() -> float:
	return _progress


func _draw() -> void:
	var fade: float = 0.5 + 0.5 * _progress
	var band_color: Color = BAND_COLOR
	band_color.a *= fade
	draw_rect(_band, band_color)
	var gap_color: Color = GAP_COLOR
	gap_color.a *= fade
	draw_rect(Rect2(_gap_x.x, _band.position.y, _gap_x.y - _gap_x.x, _band.size.y), gap_color)
