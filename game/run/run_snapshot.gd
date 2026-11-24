class_name RunSnapshot
extends RefCounted
## What run.json holds (story 6.8, architecture P3 and D12): the run as it was when the player came into a room, before
## anything of that room was drawn. Objects are referenced by id, never stored. Versioned like the profile: from_dict()
## runs the migrations, a file this game cannot read gives null and the caller quarantines it.

const SCHEMA_VERSION: int = 1
const FILE_NAME: String = "run.json"
## Migrations by the version they leave, like Profile.MIGRATIONS. Empty today (one schema).
const MIGRATIONS: Dictionary[int, Callable] = {}

var state: RunState = RunState.new()
## Content the profile had unlocked: the room pool, so the floor, depends on it.
var unlocks: Array[StringName] = []
## The room to enter again and the side the player came through (-1: the middle of the room).
var cell: Vector2i = Vector2i.ZERO
var entry_side: int = -1
## Cells entered and cleared (FloorMap.current is the cell above).
var map: FloorMap = FloorMap.new()
## The stocks of the rooms seen so far, by cell.
var stocks: Dictionary[Vector2i, RoomStock] = {}
## Health.export_state() of the player.
var health: Dictionary = {}
var lucidity: int = 0
## The items held in the order taken: id, max_half_hearts_paid, charge (-1 for an item without charge).
var items: Array[Dictionary] = []
## Id of the consumable carried, empty for none.
var consumable: StringName = &""
## RunRng.export_states(): decimal strings.
var rng_states: Dictionary = {}
## Hash of FloorLayout.signature(): a changed room pool makes another floor from the same seed.
var plan: String = ""


## The snapshot of a run about to enter a room, before the draws of that room. Nothing of it aliases the run.
static func capture(run: Run, player: Player, room_cell: Vector2i, side: int) -> RunSnapshot:
	var snapshot: RunSnapshot = RunSnapshot.new()
	snapshot.state = RunState.from_dict(run.state.to_dict())
	snapshot.unlocks = run.played_options().unlocks.duplicate()
	snapshot.cell = room_cell
	snapshot.entry_side = side
	snapshot.map = FloorMap.from_dict(run.floor_map.to_dict())
	for stock_cell: Vector2i in run.stocks:
		snapshot.stocks[stock_cell] = RoomStock.from_dict(run.stocks[stock_cell].to_dict())
	snapshot.health = player.health.export_state()
	snapshot.lucidity = player.lucidity.value
	var loadout: Loadout = player.carrier.loadout
	for owned: OwnedItem in loadout.items():
		snapshot.items.append({
			"id": String(owned.def.id),
			"paid": owned.max_half_hearts_paid,
			"charge": owned.charge if owned.def.active else -1,
		})
	snapshot.consumable = loadout.consumable.id if loadout.consumable != null else &""
	snapshot.rng_states = run.rng.export_states()
	snapshot.plan = run.floor_layout.signature().sha256_text()
	return snapshot


func to_dict() -> Dictionary:
	var unlock_ids: Array[String] = []
	for id: StringName in unlocks:
		unlock_ids.append(String(id))
	var stock_list: Array = []
	var stock_cells: Array[Vector2i] = stocks.keys()
	stock_cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	for stock_cell: Vector2i in stock_cells:
		stock_list.append({"cell": FloorMap.cell_to_array(stock_cell), "stock": stocks[stock_cell].to_dict()})
	return {
		"schema_version": SCHEMA_VERSION,
		"state": state.to_dict(),
		"unlocks": unlock_ids,
		"cell": FloorMap.cell_to_array(cell),
		"entry_side": entry_side,
		"map": map.to_dict(),
		"stocks": stock_list,
		"player": {
			"health": health,
			"lucidity": lucidity,
			"items": items,
			"consumable": String(consumable),
		},
		"rng": rng_states,
		"plan": plan,
	}


## The snapshot of data (after migration), null when the data cannot be read: wrong version, missing or mistyped field.
## Whether the values make sense (ranges, cells of the plan) is validate()'s job.
static func from_dict(data: Dictionary, migrations: Dictionary = MIGRATIONS, current_version: int = SCHEMA_VERSION) -> RunSnapshot:
	var migrated: Dictionary = Profile.migrate(data, migrations, current_version)
	if migrated.is_empty():
		return null
	var snapshot: RunSnapshot = RunSnapshot.new()
	var run_state: RunState = RunState.from_dict(_dict_of(migrated.get("state")))
	var floor_map: FloorMap = FloorMap.from_dict(_dict_of(migrated.get("map")))
	var player: Dictionary = _dict_of(migrated.get("player"))
	var cell_value: Vector2i = FloorMap.cell_from_variant(migrated.get("cell"))
	var side: Variant = migrated.get("entry_side")
	var lucidity_value: Variant = player.get("lucidity")
	var consumable_value: Variant = player.get("consumable", "")
	var rng: Variant = migrated.get("rng")
	var plan_value: Variant = migrated.get("plan")
	if run_state == null or floor_map == null or cell_value == FloorMap.NO_CELL or not RunRng.states_are_valid(rng) or typeof(plan_value) != TYPE_STRING:
		return null
	if not _is_number(side) or not _is_number(lucidity_value) or typeof(consumable_value) != TYPE_STRING:
		return null
	if typeof(migrated.get("unlocks", [])) != TYPE_ARRAY or typeof(player.get("items")) != TYPE_ARRAY \
			or typeof(migrated.get("stocks")) != TYPE_ARRAY or not Health.is_valid_state(player.get("health")):
		return null
	snapshot.state = run_state
	snapshot.map = floor_map
	snapshot.cell = cell_value
	snapshot.entry_side = RunState.whole(side)
	snapshot.lucidity = RunState.whole(lucidity_value)
	snapshot.consumable = StringName(RunState.text_of(consumable_value))
	var saved_health: Dictionary = _dict_of(player.get("health"))
	for key: String in ["half_hearts", "max_half_hearts", "armor", "max_lost"]:
		snapshot.health[key] = RunState.whole(saved_health[key]) # whole numbers again, not the floats of JSON
	snapshot.rng_states = _dict_of(rng).duplicate()
	snapshot.plan = RunState.text_of(plan_value)
	for id: Variant in _array_of(migrated.get("unlocks", [])):
		if typeof(id) != TYPE_STRING:
			return null
		snapshot.unlocks.append(StringName(RunState.text_of(id)))
	for entry: Variant in _array_of(player.get("items")):
		var item: Dictionary = _dict_of(entry)
		if typeof(item.get("id")) != TYPE_STRING or not _is_number(item.get("paid")) or not _is_number(item.get("charge")):
			return null
		snapshot.items.append({"id": item["id"], "paid": RunState.whole(item["paid"]), "charge": RunState.whole(item["charge"])})
	for entry: Variant in _array_of(migrated.get("stocks")):
		var stock_entry: Dictionary = _dict_of(entry)
		var stock_cell: Vector2i = FloorMap.cell_from_variant(stock_entry.get("cell"))
		var stock: RoomStock = RoomStock.from_dict(_dict_of(stock_entry.get("stock")))
		if stock_cell == FloorMap.NO_CELL or stock == null:
			return null
		snapshot.stocks[stock_cell] = stock
	return snapshot


## What is wrong with the values, "" when they make sense. layout: the floor made again from the seed, null to skip the
## checks against the plan.
func validate(layout: FloorLayout = null) -> String:
	if state.run_seed < 0 or state.run_seed >= (1 << RunRng.SEED_BITS):
		return "seed out of range"
	if state.floor_index < 0:
		return "negative floor index"
	if entry_side < -1 or entry_side > 3:
		return "entry side out of range"
	if lucidity < 0:
		return "negative lucidity"
	if layout == null:
		return ""
	if not layout.valid:
		return "the floor of the seed is invalid"
	if layout.signature().sha256_text() != plan:
		return "the floor of the seed changed"
	var cells: Array[Vector2i] = [cell] # map.current is not checked: it is (0, 0) before the first room, and the entry sets it
	cells.append_array(map.visited.keys())
	cells.append_array(map.cleared.keys())
	cells.append_array(stocks.keys())
	for checked: Vector2i in cells:
		if not layout.has_cell(checked):
			return "cell %s is not in the plan" % checked
	return ""


static func _dict_of(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}


static func _array_of(value: Variant) -> Array:
	return value if typeof(value) == TYPE_ARRAY else []


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
