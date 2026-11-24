class_name Notice
extends Control
## A short message at the bottom of the screen that fades out by itself (story 6.7): news that must not stop the game.
## Runs on real time. The text is a translation key.

const HOLD_SECONDS: float = 6.0
const FADE_SECONDS: float = 1.0
const FONT_SIZE: int = 12
const COLOR: Color = Color(0.93, 0.94, 0.9)
const HEIGHT: float = 24.0
const BOTTOM_MARGIN: float = 12.0

var _label: Label
var _elapsed: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(Const.VIEWPORT.x, HEIGHT)
	position = Vector2(0.0, Const.VIEWPORT.y - HEIGHT - BOTTOM_MARGIN)
	_label = Label.new()
	_label.name = "Text"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = size
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", COLOR)
	add_child(_label)
	visible = false
	set_process(false)


## Shows the translation of key for a few seconds.
func show_key(key: StringName) -> void:
	_label.text = tr(key)
	_elapsed = 0.0
	modulate.a = 1.0
	visible = true
	set_process(true)


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= HOLD_SECONDS + FADE_SECONDS:
		visible = false
		set_process(false)
	elif _elapsed > HOLD_SECONDS:
		modulate.a = 1.0 - (_elapsed - HOLD_SECONDS) / FADE_SECONDS
