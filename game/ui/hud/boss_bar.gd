class_name BossBar
extends Control
## Health bar of the boss, at the bottom of the screen (story 6.1): its name and a fill of hit points over the maximum.
## Display only: shown by Events.boss_engaged, followed by Events.boss_health_changed, hidden at 0 hit points (the boss
## died or left the room) and when a run starts or ends.

const BAR_SIZE: Vector2 = Vector2(320.0, 14.0)
const BOTTOM_MARGIN: float = 2.0
const BACKGROUND_COLOR: Color = Color(0.04, 0.035, 0.08, 0.85)
const FILL_COLOR: Color = Color(0.75, 0.2, 0.25)
const BORDER_COLOR: Color = Color(0.95, 0.9, 0.8)
const NAME_COLOR: Color = Color(1.0, 1.0, 1.0)
const NAME_FONT_SIZE: int = 9
## Translation key of the name of each boss, by BossDef.id.
const NAME_KEYS: Dictionary = {&"professor": &"BOSS_PROFESSOR_NAME"}

var _share: float = 1.0
var _label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = BAR_SIZE
	position = Vector2((Const.VIEWPORT.x - BAR_SIZE.x) / 2.0, Const.VIEWPORT.y - BAR_SIZE.y - BOTTOM_MARGIN)
	_label = Label.new()
	_label.name = "Name"
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.size = BAR_SIZE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
	_label.add_theme_color_override("font_color", NAME_COLOR)
	add_child(_label)
	visible = false
	Events.boss_engaged.connect(_on_boss_engaged)
	Events.boss_health_changed.connect(_on_boss_health_changed)
	Events.run_started.connect(hide_bar)
	Events.run_ended.connect(_on_run_ended)


## Fill, from 0 to 1.
func share() -> float:
	return _share


func hide_bar() -> void:
	visible = false


func _on_boss_engaged(boss_id: StringName, _max_hp: float) -> void:
	var key: StringName = NAME_KEYS.get(boss_id, &"")
	_label.text = tr(key) if key != &"" else ""
	_share = 1.0
	visible = true
	queue_redraw()


func _on_boss_health_changed(hp: float, max_hp: float) -> void:
	if hp <= 0.0 or not (max_hp > 0.0):
		hide_bar()
		return
	_share = clampf(hp / max_hp, 0.0, 1.0)
	queue_redraw()


func _on_run_ended(_outcome: int) -> void:
	hide_bar()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, BAR_SIZE), BACKGROUND_COLOR)
	draw_rect(Rect2(Vector2.ONE, Vector2((BAR_SIZE.x - 2.0) * _share, BAR_SIZE.y - 2.0)), FILL_COLOR)
	draw_rect(Rect2(Vector2.ZERO, BAR_SIZE), BORDER_COLOR, false)
