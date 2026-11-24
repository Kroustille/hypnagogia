class_name HudSlot
extends Control
## A framed place of the HUD (item slots, lucidity gauge place). Display only; the stories that fill it
## (epics 3 and 5) put a content in it, the frame stays.

const FRAME_COLOR: Color = Color(0.3, 0.27, 0.45)
## Inside margin of the placeholder icon, in pixels.
const ICON_MARGIN: float = 2.0

var _content_color: Color = Color.TRANSPARENT
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = Label.new()
	_label.name = "Initial"
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	add_child(_label)


## Placeholder icon until epic 7: a colored square with a short text (the initial of the name).
func set_content(color: Color, label: String) -> void:
	_content_color = color
	_label.text = label
	_label.visible = true
	queue_redraw()


func clear_content() -> void:
	_content_color = Color.TRANSPARENT
	_label.text = ""
	_label.visible = false
	queue_redraw()


func has_content() -> bool:
	return _label.visible


## The text of the icon (checks).
func content_label() -> String:
	return _label.text


func _draw() -> void:
	if _label != null and _label.visible:
		draw_rect(Rect2(Vector2.ONE * ICON_MARGIN, size - Vector2.ONE * ICON_MARGIN * 2.0), _content_color)
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)
