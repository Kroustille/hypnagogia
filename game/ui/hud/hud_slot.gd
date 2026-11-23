class_name HudSlot
extends Control
## An empty framed place of the HUD (item slots, lucidity gauge place). Display only; the stories that fill it
## (epics 3 and 5) replace the content, the frame stays.

const FRAME_COLOR: Color = Color(0.3, 0.27, 0.45)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)
