class_name ChalkTitle
extends Control
## The title of a boss phase, written on the blackboard at the top of the room, letter by letter (story 6.1).
## Display only: it writes what Events.boss_announced gives (a translation key). Runs on real time, like the banner.

const CHARS_PER_SECOND: float = 12.0
## Seconds the finished title stays, then it goes.
const HOLD_SECONDS: float = 1.2
const FONT_SIZE: int = 20
const COLOR: Color = Color(0.93, 0.94, 0.9)
const WIDTH: float = 360.0
const HEIGHT: float = 26.0
const TOP: float = 28.0

var _text: String = ""
var _elapsed: float = 0.0
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WIDTH, HEIGHT)
	position = Vector2((Const.VIEWPORT.x - WIDTH) / 2.0, TOP)
	_label = Label.new()
	_label.name = "Title"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = size
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", FONT_SIZE)
	_label.add_theme_color_override("font_color", COLOR)
	add_child(_label)
	visible = false
	set_process(false)
	Events.boss_announced.connect(_on_boss_announced)
	Events.run_started.connect(hide_title)
	Events.run_ended.connect(_on_run_ended)
	Events.boss_defeated.connect(_on_boss_defeated)


func _process(delta: float) -> void:
	_elapsed += delta
	var shown: int = mini(int(_elapsed * CHARS_PER_SECOND), _text.length())
	_label.text = _text.substr(0, shown)
	if _elapsed >= _text.length() / CHARS_PER_SECOND + HOLD_SECONDS:
		hide_title()


## The letters written so far.
func written() -> String:
	return _label.text if visible else ""


func hide_title() -> void:
	visible = false
	set_process(false)


func _on_boss_announced(_boss_id: StringName, text_key: StringName) -> void:
	_text = tr(text_key)
	_elapsed = 0.0
	_label.text = ""
	visible = true
	set_process(true)


func _on_run_ended(_outcome: int) -> void:
	hide_title()


## The board is wiped as soon as the boss falls: no title during the victory wait (story 6.4, AC 1).
func _on_boss_defeated(_boss_id: StringName) -> void:
	hide_title()
