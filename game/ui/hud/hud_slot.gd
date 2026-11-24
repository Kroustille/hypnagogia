class_name HudSlot
extends Control
## A framed place of the HUD (item slots, lucidity gauge place). Display only; the stories that fill it
## (epics 3 and 5) put a content in it, the frame stays.

const FRAME_COLOR: Color = Color(0.3, 0.27, 0.45)
## Inside margin of the placeholder icon, in pixels.
const ICON_MARGIN: float = 2.0
const CHARGE_BAR_HEIGHT: float = 3.0
const CHARGE_COLOR: Color = Color(0.6, 0.8, 1.0)
const CHARGE_EMPTY_COLOR: Color = Color(0.15, 0.15, 0.25)

var _content_color: Color = Color.TRANSPARENT
var _charge: int = 0
var _charge_max: int = 0
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


## A charge bar of charge_max segments under the icon (story 5.8); charge_max 0 hides it.
func set_charge(charge: int, charge_max: int) -> void:
	_charge = charge
	_charge_max = charge_max
	queue_redraw()


func charge() -> int:
	return _charge


func charge_max() -> int:
	return _charge_max


func clear_content() -> void:
	_charge = 0
	_charge_max = 0
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
	if _charge_max > 0:
		var segment_width: float = (size.x - ICON_MARGIN * 2.0) / _charge_max
		for index: int in range(_charge_max):
			var cell: Rect2 = Rect2(ICON_MARGIN + index * segment_width, size.y - ICON_MARGIN - CHARGE_BAR_HEIGHT, segment_width - 1.0, CHARGE_BAR_HEIGHT)
			draw_rect(cell, CHARGE_COLOR if index < _charge else CHARGE_EMPTY_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), FRAME_COLOR, false, 1.0)
