class_name Banner
extends Control
## A short announcement under the HUD band: a title and two lines (an item: name, bonus, cost), shown for a few seconds
## (story 5.1; story 5.7 reuses it for synergies). Display only: texts are translation keys given by Events.banner_requested.
## A new request replaces the one on screen. Runs on real time, whatever the game clock does.

## Seconds on screen.
const DURATION: float = 3.0
const WIDTH: float = 360.0
const LINE_HEIGHT: float = 14.0
const BACKGROUND_COLOR: Color = Color(0.04, 0.035, 0.08, 0.85)
const TITLE_COLOR: Color = Color(0.95, 0.85, 0.4)
const BONUS_COLOR: Color = Color(0.7, 0.95, 0.75)
const COST_COLOR: Color = Color(0.95, 0.6, 0.6)
const PADDING: float = 4.0

var _time_left: float = 0.0
var _title: Label
var _bonus: Label
var _cost: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(WIDTH, LINE_HEIGHT * 3.0 + PADDING * 2.0)
	position = Vector2((Const.VIEWPORT.x - WIDTH) / 2.0, Const.HUD_BAND_HEIGHT + 8.0)
	_title = _make_line("Title", 0, TITLE_COLOR)
	_bonus = _make_line("Bonus", 1, BONUS_COLOR)
	_cost = _make_line("Cost", 2, COST_COLOR)
	visible = false
	set_process(false)
	Events.banner_requested.connect(show_banner)


func _process(delta: float) -> void:
	_time_left -= delta
	if _time_left <= 0.0:
		hide_banner()


## Shows the banner now, replacing the current one. An empty key leaves its line blank.
func show_banner(title_key: StringName, bonus_key: StringName, cost_key: StringName) -> void:
	_title.text = _translated(title_key)
	_bonus.text = _translated(bonus_key)
	_cost.text = _translated(cost_key)
	_time_left = DURATION
	visible = true
	set_process(true)


func hide_banner() -> void:
	_time_left = 0.0
	visible = false
	set_process(false)


func is_showing() -> bool:
	return visible


## The three lines on screen (checks).
func lines() -> PackedStringArray:
	return PackedStringArray([_title.text, _bonus.text, _cost.text])


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND_COLOR)


func _translated(key: StringName) -> String:
	return tr(key) if key != &"" else ""


func _make_line(line_name: String, row: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.name = line_name
	label.position = Vector2(PADDING, PADDING + row * LINE_HEIGHT)
	label.size = Vector2(WIDTH - PADDING * 2.0, LINE_HEIGHT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override(&"font_color", color)
	add_child(label)
	return label
