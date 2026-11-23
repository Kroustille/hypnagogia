class_name Hud
extends Control
## HUD band (story 2.7): hearts, armor, shards, item slots and the place of the lucidity gauge, in the 24 px band
## above the room. Child of Main's UI layer, so it outlives each Run. Display only: it listens to Events and never
## reads or writes the game state (ui/ rule, architecture). Texts come from tr().

const BAND_COLOR: Color = Color(0.04, 0.035, 0.08)
const BAND_EDGE_COLOR: Color = Color(0.21, 0.18, 0.33)
const MARGIN: int = 6
const LUCIDITY_SLOT_SIZE: Vector2 = Vector2(160, 8)
const ITEM_SLOT_SIZE: Vector2 = Vector2(16, 16)
const ITEM_SLOT_GAP: int = 8
const SHARD_COLOR: Color = Color(0.85, 0.8, 0.4)

var _shards: int = 0 # static 0 until epic 5 (decision 4), then set from an Events signal

var _hearts: HeartRow
var _lucidity_slot: HudSlot
var _active_item_slot: HudSlot
var _consumable_slot: HudSlot
var _shards_label: Label


func _ready() -> void:
	custom_minimum_size = Vector2(0, Const.HUD_BAND_HEIGHT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_hearts = HeartRow.new()
	_hearts.name = "Hearts"
	@warning_ignore("integer_division")
	_hearts.position = Vector2(MARGIN, (Const.HUD_BAND_HEIGHT - HeartRow.ICON_SIZE.y) / 2)
	add_child(_hearts)
	Events.player_health_changed.connect(_on_events_player_health_changed)
	Events.player_hit.connect(_on_events_player_hit)

	_lucidity_slot = _make_slot("LucidityGaugeSlot", LUCIDITY_SLOT_SIZE, Vector2(
		(Const.VIEWPORT.x - LUCIDITY_SLOT_SIZE.x) / 2.0, (Const.HUD_BAND_HEIGHT - LUCIDITY_SLOT_SIZE.y) / 2.0))

	var slot_y: float = (Const.HUD_BAND_HEIGHT - ITEM_SLOT_SIZE.y) / 2.0
	var consumable_x: float = Const.VIEWPORT.x - MARGIN - ITEM_SLOT_SIZE.x
	var active_x: float = consumable_x - ITEM_SLOT_GAP - ITEM_SLOT_SIZE.x
	_consumable_slot = _make_slot("ConsumableSlot", ITEM_SLOT_SIZE, Vector2(consumable_x, slot_y))
	_active_item_slot = _make_slot("ActiveItemSlot", ITEM_SLOT_SIZE, Vector2(active_x, slot_y))

	_shards_label = Label.new()
	_shards_label.name = "ShardsLabel"
	_shards_label.position = Vector2(active_x - 70, 0)
	_shards_label.size = Vector2(48, Const.HUD_BAND_HEIGHT)
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shards_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shards_label)
	_refresh_shards()



func hearts() -> HeartRow:
	return _hearts


func lucidity_slot() -> HudSlot:
	return _lucidity_slot


func item_slots() -> Array[HudSlot]:
	return [_active_item_slot, _consumable_slot]


func shards_text() -> String:
	return _shards_label.text


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BAND_COLOR)
	draw_rect(Rect2(0, size.y - 1.0, size.x, 1.0), BAND_EDGE_COLOR)
	# Shard icon: a small diamond left of the count, drawn in code (placeholder look until epic 7).
	var center: Vector2 = Vector2(_shards_label.position.x + _shards_label.size.x + 10.0, size.y / 2.0)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -4), center + Vector2(3, 0), center + Vector2(0, 4), center + Vector2(-3, 0)]), SHARD_COLOR)


func _make_slot(slot_name: String, slot_size: Vector2, slot_position: Vector2) -> HudSlot:
	var slot: HudSlot = HudSlot.new()
	slot.name = slot_name
	slot.position = slot_position
	slot.size = slot_size
	add_child(slot)
	return slot


func _refresh_shards() -> void:
	_shards_label.text = tr(&"UI_HUD_SHARDS") % _shards


func _on_events_player_health_changed(half_hearts: int, max_half_hearts: int, armor: int) -> void:
	_hearts.set_state(half_hearts, max_half_hearts, armor)


func _on_events_player_hit(_damage: int, _source: int) -> void:
	_hearts.flash()
