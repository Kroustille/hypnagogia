class_name FloorMapView
extends Control
## The map of the floor (story 4.9): drawn over the game while the `map` action is held, hidden otherwise. The game is
## not paused (it never writes to GameClock). Placeholder shapes, no texture. Screen pixels (the UI layer follows the
## viewport, not the camera). Reads the held key from Input, not from _input: Tab is also ui_focus_next, so this
## control takes neither focus nor mouse.

## Free area of the screen for the cells (under the HUD band, above the legend).
const AREA: Rect2 = Rect2(32, 52, 576, 252)
## Biggest distance between two cell origins, and the gap left between two cells for the connections.
const MAX_PITCH: int = 40
const GAP: int = 8
## Where the legend sits.
const LEGEND_Y: int = 336

const COLOR_BACKDROP: Color = Color(0.02, 0.02, 0.06, 0.82)
const COLOR_VISITED: Color = Color(0.45, 0.5, 0.65)
const COLOR_UNEXPLORED: Color = Color(0.25, 0.27, 0.36)
const COLOR_LINK: Color = Color(0.45, 0.5, 0.65)
const COLOR_CURRENT: Color = Color(1.0, 0.9, 0.3)
const COLOR_TEXT: Color = Color(0.9, 0.9, 0.95)
const COLOR_CLEARED: Color = Color(0.1, 0.12, 0.2)
const COLOR_TREASURE: Color = Color(1.0, 0.8, 0.2)
const COLOR_SHOP: Color = Color(0.4, 0.9, 0.5)
const COLOR_NIGHTMARE: Color = Color(0.9, 0.3, 0.4)
const COLOR_START: Color = Color(0.9, 0.9, 0.95)

var _map: FloorMap
var _entries: Array[Dictionary] = []
var _bounds: Rect2i = Rect2i()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visible = false
	set_process(true)


## Reads this map from now on (null: nothing to show). Called by Main at the start of a run.
func bind(map: FloorMap) -> void:
	if _map != null and Events.room_entered.is_connected(_on_room_changed):
		Events.room_entered.disconnect(_on_room_changed)
		Events.room_cleared.disconnect(_on_room_cleared)
	_map = map
	if _map != null:
		Events.room_entered.connect(_on_room_changed)
		Events.room_cleared.connect(_on_room_cleared)
	_refresh()
	visible = false


func unbind() -> void:
	bind(null)


func _process(_delta: float) -> void:
	var wanted: bool = _map != null and _map.layout != null and not GameClock.paused \
			and Input.is_action_pressed(&"map")
	if wanted == visible:
		return
	visible = wanted
	if wanted:
		_refresh()


func _on_room_changed(_id: StringName, _x: int, _y: int) -> void:
	_refresh()


func _on_room_cleared(_room: Node, _tier: int) -> void:
	_refresh()


func _refresh() -> void:
	_entries.clear()
	if _map != null:
		_entries.assign(_map.entries())
	_bounds = _map.bounds() if _map != null else Rect2i()
	queue_redraw()


## The screen rectangle of a cell: cells sit on a regular grid that fits `bounds` in `area`, centred, integer
## coordinates. The gap between two rectangles is where the connections go.
static func cell_rect(cell: Vector2i, bounds: Rect2i, area: Rect2) -> Rect2:
	var pitch: int = int(minf(minf(area.size.x / maxf(bounds.size.x, 1), area.size.y / maxf(bounds.size.y, 1)), MAX_PITCH))
	pitch = maxi(pitch, GAP + 1)
	var total: Vector2i = bounds.size * pitch
	var origin: Vector2i = Vector2i(area.position) + (Vector2i(area.size) - total) / 2
	var top_left: Vector2i = origin + (cell - bounds.position) * pitch
	return Rect2(Vector2(top_left), Vector2(pitch - GAP, pitch - GAP))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), COLOR_BACKDROP)
	var font: Font = get_theme_default_font()
	var title: String = tr(&"UI_MAP_TITLE")
	draw_string(font, Vector2(0, 40), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 16, COLOR_TEXT)
	_draw_links()
	for entry: Dictionary in _entries:
		_draw_room(entry)
	_draw_legend(font)


func _draw_links() -> void:
	for entry: Dictionary in _entries:
		var cell: Vector2i = entry[&"cell"]
		var from: Rect2 = cell_rect(cell, _bounds, AREA)
		for link: Vector2i in entry[&"links"]:
			if not _cell_before(cell, link):
				continue
			var to: Rect2 = cell_rect(link, _bounds, AREA)
			draw_line(from.get_center().round(), to.get_center().round(), COLOR_LINK, 2.0)


func _draw_room(entry: Dictionary) -> void:
	var cell: Vector2i = entry[&"cell"]
	var room_type: Room.RoomType = entry[&"type"]
	var rect: Rect2 = cell_rect(cell, _bounds, AREA)
	var visited: bool = entry[&"state"] == FloorMap.State.VISITED
	var color: Color = COLOR_VISITED if visited else COLOR_UNEXPLORED
	if visited:
		draw_rect(rect, COLOR_CLEARED if entry[&"cleared"] else color)
		draw_rect(rect, color, false, 1.0)
	else:
		draw_rect(rect, COLOR_BACKDROP)
		draw_rect(rect, color, false, 1.0)
	if entry[&"size_kind"] != Room.SizeKind.SCREEN:
		draw_rect(rect.grow(-3), color, false, 1.0) # a big room: double outline
	if entry[&"current"]:
		draw_rect(rect.grow(2), COLOR_CURRENT, false, 2.0)
	_draw_icon(room_type, rect.get_center().round(), visited)
	if visited and entry[&"cleared"]:
		_draw_cleared_mark(rect)


func _draw_icon(room_type: Room.RoomType, center: Vector2, visited: bool) -> void:
	var tint: float = 1.0 if visited else 0.7
	match room_type:
		Room.RoomType.TREASURE:
			_draw_treasure_icon(center, tint)
		Room.RoomType.SHOP:
			_draw_shop_icon(center, tint)
		Room.RoomType.NIGHTMARE:
			_draw_nightmare_icon(center, tint)
		Room.RoomType.START:
			draw_rect(Rect2(center - Vector2(2, 2), Vector2(4, 4)), COLOR_START)
		_:
			pass


func _draw_treasure_icon(center: Vector2, tint: float) -> void:
	var points: PackedVector2Array = PackedVector2Array([
		center + Vector2(0, -5), center + Vector2(5, 0), center + Vector2(0, 5), center + Vector2(-5, 0)])
	draw_colored_polygon(points, COLOR_TREASURE * Color(tint, tint, tint))


func _draw_shop_icon(center: Vector2, tint: float) -> void:
	draw_circle(center, 5.0, COLOR_SHOP * Color(tint, tint, tint))


func _draw_nightmare_icon(center: Vector2, tint: float) -> void:
	var color: Color = COLOR_NIGHTMARE * Color(tint, tint, tint)
	draw_line(center + Vector2(-5, -5), center + Vector2(5, 5), color, 2.0)
	draw_line(center + Vector2(-5, 5), center + Vector2(5, -5), color, 2.0)


func _draw_cleared_mark(rect: Rect2) -> void:
	var corner: Vector2 = rect.end.round() - Vector2(6, 5)
	draw_line(corner + Vector2(0, 2), corner + Vector2(2, 4), COLOR_TEXT, 1.0)
	draw_line(corner + Vector2(2, 4), corner + Vector2(5, 0), COLOR_TEXT, 1.0)


func _draw_legend(font: Font) -> void:
	var types: Array[Room.RoomType] = [Room.RoomType.TREASURE, Room.RoomType.SHOP, Room.RoomType.NIGHTMARE]
	var keys: Array[StringName] = [&"UI_MAP_LEGEND_TREASURE", &"UI_MAP_LEGEND_SHOP", &"UI_MAP_LEGEND_NIGHTMARE"]
	var x: float = 160.0
	for i: int in types.size():
		var label: String = tr(keys[i])
		_draw_icon(types[i], Vector2(x, LEGEND_Y - 4), true)
		draw_string(font, Vector2(x + 10, LEGEND_Y), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, COLOR_TEXT)
		x += 110.0


static func _cell_before(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
