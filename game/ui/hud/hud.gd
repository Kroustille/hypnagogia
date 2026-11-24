class_name Hud
extends Control
## HUD band (story 2.7): hearts, armor, shards, item slots and the place of the lucidity gauge, in the 24 px band
## above the room. Child of Main's UI layer, so it outlives each Run. Display only: it listens to Events and never
## reads or writes the game state (ui/ rule, architecture). Texts come from tr().

const BAND_COLOR: Color = Color(0.04, 0.035, 0.08)
const BAND_EDGE_COLOR: Color = Color(0.21, 0.18, 0.33)
const MARGIN: int = 6
const LUCIDITY_SLOT_SIZE: Vector2 = Vector2(160, 8)
## Room right of the gauge for the tier name, up to the shards.
const TIER_LABEL_WIDTH: int = 110
const TIER_NAME_KEYS: Array[StringName] = [
	&"UI_LUCIDITY_LUCID", &"UI_LUCIDITY_FLOATING", &"UI_LUCIDITY_DRIFT", &"UI_LUCIDITY_ABANDON",
	&"UI_LUCIDITY_TOTAL_ABANDON",
]
const ITEM_SLOT_SIZE: Vector2 = Vector2(16, 16)
const ITEM_SLOT_GAP: int = 8
const SHARD_COLOR: Color = Color(0.85, 0.8, 0.4)
## Hues a consumable id picks its placeholder icon color from.
const CONSUMABLE_HUE_STEPS: int = 360

var _shards: int = 0 # follows Events.shards_changed (story 5.4)

var _hearts: HeartRow
var _lucidity_slot: HudSlot
var _lucidity_gauge: LucidityGauge
var _tier_label: Label
var _tier: int = -1
var _active_item_slot: HudSlot
var _consumable_slot: HudSlot
var _shards_label: Label
var _banner: Banner


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
	_lucidity_gauge = LucidityGauge.new()
	_lucidity_gauge.name = "LucidityGauge"
	_lucidity_gauge.position = _lucidity_slot.position
	_lucidity_gauge.size = LUCIDITY_SLOT_SIZE
	add_child(_lucidity_gauge) # a sibling over the frame: the slot itself stays empty
	_tier_label = Label.new()
	_tier_label.name = "TierLabel"
	_tier_label.position = Vector2(_lucidity_slot.position.x + LUCIDITY_SLOT_SIZE.x + MARGIN, 0)
	_tier_label.size = Vector2(TIER_LABEL_WIDTH, Const.HUD_BAND_HEIGHT)
	_tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_tier_label)
	Events.lucidity_value_changed.connect(_on_events_lucidity_value_changed)
	Events.lucidity_tier_changed.connect(_on_events_lucidity_tier_changed)

	var slot_y: float = (Const.HUD_BAND_HEIGHT - ITEM_SLOT_SIZE.y) / 2.0
	var consumable_x: float = Const.VIEWPORT.x - MARGIN - ITEM_SLOT_SIZE.x
	var active_x: float = consumable_x - ITEM_SLOT_GAP - ITEM_SLOT_SIZE.x
	_consumable_slot = _make_slot("ConsumableSlot", ITEM_SLOT_SIZE, Vector2(consumable_x, slot_y))
	_active_item_slot = _make_slot("ActiveItemSlot", ITEM_SLOT_SIZE, Vector2(active_x, slot_y))
	Events.consumable_changed.connect(_on_events_consumable_changed)
	Events.run_started.connect(_on_events_run_started)
	Events.shards_changed.connect(_on_events_shards_changed)

	_shards_label = Label.new()
	_shards_label.name = "ShardsLabel"
	_shards_label.position = Vector2(active_x - 70, 0)
	_shards_label.size = Vector2(48, Const.HUD_BAND_HEIGHT)
	_shards_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_shards_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_shards_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_shards_label)
	_refresh_shards()

	_banner = Banner.new()
	_banner.name = "Banner"
	add_child(_banner)



func banner() -> Banner:
	return _banner


func hearts() -> HeartRow:
	return _hearts


func lucidity_slot() -> HudSlot:
	return _lucidity_slot


func item_slots() -> Array[HudSlot]:
	return [_active_item_slot, _consumable_slot]


func lucidity_gauge() -> LucidityGauge:
	return _lucidity_gauge


func tier_text() -> String:
	return _tier_label.text


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


## The carried consumable: a colored square (the color follows the id) with the initial of its name; empty id = free slot.
func _on_events_consumable_changed(id: StringName, name_key: StringName) -> void:
	if id == &"":
		_consumable_slot.clear_content()
		return
	var name_text: String = tr(name_key)
	var color: Color = Color.from_hsv(float(id.hash() % CONSUMABLE_HUE_STEPS) / CONSUMABLE_HUE_STEPS, 0.55, 0.45)
	_consumable_slot.set_content(color, name_text.left(1))


## The total of shards the player holds.
func _on_events_shards_changed(total: int) -> void:
	_shards = total
	_refresh_shards()


## A new run starts with nothing in the slot.
func _on_events_run_started() -> void:
	_consumable_slot.clear_content()


func _on_events_player_health_changed(half_hearts: int, max_half_hearts: int, armor: int) -> void:
	_hearts.set_state(half_hearts, max_half_hearts, armor)


func _on_events_player_hit(_damage: int, _source: int) -> void:
	_hearts.flash()


func _on_events_lucidity_tier_changed(_tier_value: int, _previous_tier: int) -> void:
	_lucidity_gauge.flash()

func _on_events_lucidity_value_changed(value: int, tier: int) -> void:
	_lucidity_gauge.set_state(value, tier)
	if tier != _tier:
		_tier = tier
		_tier_label.text = tr(TIER_NAME_KEYS[clampi(tier, 0, TIER_NAME_KEYS.size() - 1)])
