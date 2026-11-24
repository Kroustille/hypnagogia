extends GutTest
## RunSnapshot (story 6.8): the round trip through JSON text, what validate() refuses, the 64-bit random states.

const BIG_STATE: int = (1 << 62) + 12345


func _snapshot() -> RunSnapshot:
	var snapshot: RunSnapshot = RunSnapshot.new()
	snapshot.state.run_seed = (1 << 39) + 7
	snapshot.state.seeded = true
	snapshot.state.floor_index = 0
	snapshot.state.shards = 12
	snapshot.state.wake_minute = -1
	snapshot.state.play_seconds = 12.5
	snapshot.unlocks = [&"u1"]
	snapshot.cell = Vector2i(2, -1)
	snapshot.entry_side = 3
	snapshot.map.current = Vector2i(1, -1)
	snapshot.map.visited = {Vector2i(0, 0): true, Vector2i(1, -1): true}
	snapshot.map.cleared = {Vector2i(0, 0): true}
	var stock: RoomStock = RoomStock.new()
	var item: ItemDef = ItemCatalog.by_id(&"falling_tooth")
	var offer: RoomStock.Offer = stock.add_item(item, Vector2(100.5, 64.25), 6, false, -1)
	offer.taken = true
	stock.add_drop(RoomStock.Kind.SHARDS, 3, Vector2(8, 9))
	snapshot.stocks[Vector2i(1, -1)] = stock
	snapshot.health = {"half_hearts": 3, "max_half_hearts": 4, "armor": 2, "max_lost": 2}
	snapshot.lucidity = 55
	snapshot.items = [{"id": "falling_tooth", "paid": 2, "charge": -1}, {"id": "broken_alarm", "paid": 0, "charge": 1}]
	snapshot.consumable = &"coffee"
	var rng: RunRng = RunRng.new(snapshot.state.run_seed)
	rng.stream(RunRng.COMBAT, 0).state = BIG_STATE
	snapshot.rng_states = rng.export_states()
	return snapshot


func _through_json(snapshot: RunSnapshot) -> RunSnapshot:
	var text: String = JSON.stringify(snapshot.to_dict(), "\t")
	var parsed: Variant = JSON.parse_string(text)
	assert_true(parsed is Dictionary, "the text is a JSON object")
	return RunSnapshot.from_dict(JsonView.d(parsed))


func test_a_snapshot_comes_back_equal_after_a_round_trip_through_json_text() -> void:
	var original: RunSnapshot = _snapshot()
	var back: RunSnapshot = _through_json(original)
	assert_not_null(back)
	assert_eq(JSON.stringify(back.to_dict(), "", true), JSON.stringify(original.to_dict(), "", true))
	assert_eq(back.state.run_seed, original.state.run_seed, "the 40 bit seed survives")
	assert_eq(back.cell, Vector2i(2, -1))
	assert_eq(back.state.play_seconds, 12.5, "the playing time goes on after a resume")
	assert_eq(back.map.visited.size(), 2)
	assert_true(back.map.is_cleared(Vector2i(0, 0)))
	assert_eq(back.consumable, &"coffee")
	var stock: RoomStock = back.stocks[Vector2i(1, -1)]
	assert_eq(stock.offers.size(), 2)
	assert_eq(stock.offers[0].item.id, &"falling_tooth")
	assert_eq(stock.offers[0].position, Vector2(100.5, 64.25))
	assert_true(stock.offers[0].taken)
	assert_false(stock.offers[0].armed)
	assert_eq(stock.offers[0].price, 6)
	assert_eq(stock.offers[1].kind, RoomStock.Kind.SHARDS)
	assert_eq(stock.offers[1].amount, 3)


func test_a_random_state_above_2_pow_53_survives_the_json_text() -> void:
	var back: RunSnapshot = _through_json(_snapshot())
	var rng: RunRng = RunRng.new(back.state.run_seed)
	assert_eq(rng.restore_states(back.rng_states), 1)
	assert_eq(rng.stream(RunRng.COMBAT, 0).state, BIG_STATE, "all 64 bits are kept")


func test_restored_streams_continue_the_sequence_of_an_uninterrupted_stream() -> void:
	var live: RunRng = RunRng.new(99)
	for name: StringName in [RunRng.COMBAT, RunRng.DROPS]:
		for i: int in 5:
			live.stream(name, 0).randi()
	var saved: Dictionary = JsonView.d(JSON.parse_string(JSON.stringify(live.export_states())))
	var resumed: RunRng = RunRng.new(99)
	resumed.stream(RunRng.LAYOUT, 0).randi() # a stream used by the generation before the restore
	assert_eq(resumed.restore_states(saved), 2)
	for name: StringName in [RunRng.COMBAT, RunRng.DROPS]:
		for i: int in 4:
			assert_eq(resumed.stream(name, 0).randi(), live.stream(name, 0).randi(), "%s stream %d" % [name, i])


func test_validate_accepts_the_snapshot_and_refuses_bad_values() -> void:
	assert_eq(_snapshot().validate(), "")
	var snapshot: RunSnapshot = _snapshot()
	snapshot.state.run_seed = 1 << 40
	assert_ne(snapshot.validate(), "", "seed out of the 40 bits")
	snapshot = _snapshot()
	snapshot.state.run_seed = -1
	assert_ne(snapshot.validate(), "")
	snapshot = _snapshot()
	snapshot.entry_side = 7
	assert_ne(snapshot.validate(), "")


func test_validate_refuses_a_cell_outside_the_plan() -> void:
	var layout: FloorLayout = FloorLayout.new()
	layout.valid = true
	layout.cells[Vector2i(0, 0)] = FloorLayout.Placement.new()
	layout.start = Vector2i(0, 0)
	var snapshot: RunSnapshot = RunSnapshot.new()
	snapshot.cell = Vector2i(0, 0)
	snapshot.map.current = Vector2i(0, 0)
	assert_eq(snapshot.validate(layout), "")
	snapshot.cell = Vector2i(5, 5)
	assert_string_contains(snapshot.validate(layout), "not in the plan")
	snapshot.cell = Vector2i(0, 0)
	snapshot.stocks[Vector2i(3, 3)] = RoomStock.new()
	assert_string_contains(snapshot.validate(layout), "not in the plan")


func test_a_newer_version_or_a_missing_one_cannot_be_read() -> void:
	var data: Dictionary = _snapshot().to_dict()
	data["schema_version"] = RunSnapshot.SCHEMA_VERSION + 1
	assert_null(RunSnapshot.from_dict(data), "a future format is never read halfway")
	data.erase("schema_version")
	assert_true(RunSnapshot.from_dict(data) == null)


func test_a_mistyped_field_cannot_be_read() -> void:
	var data: Dictionary = _snapshot().to_dict()
	JsonView.d(data["state"])["seed"] = 12345 # a number where the text is expected
	assert_true(RunSnapshot.from_dict(data) == null)
	data = _snapshot().to_dict()
	data["cell"] = [1]
	assert_true(RunSnapshot.from_dict(data) == null)
	data = _snapshot().to_dict()
	JsonView.d(data["rng"])["combat:0"] = 12.5
	assert_true(RunSnapshot.from_dict(data) == null)


func test_an_unknown_item_in_a_stock_is_skipped_and_the_rest_is_kept() -> void:
	var data: Dictionary = _snapshot().to_dict()
	var stock_entry: Dictionary = JsonView.d(JsonView.a(data["stocks"])[0])
	var offers: Array = JsonView.a(JsonView.d(stock_entry["stock"])["offers"])
	JsonView.d(offers[0])["id"] = "removed_in_a_later_version"
	var back: RunSnapshot = RunSnapshot.from_dict(data)
	assert_not_null(back)
	assert_eq(back.stocks[Vector2i(1, -1)].offers.size(), 1)
	assert_eq(back.stocks[Vector2i(1, -1)].offers[0].kind, RoomStock.Kind.SHARDS)


func test_a_migration_brings_an_older_version_to_the_current_one() -> void:
	var data: Dictionary = _snapshot().to_dict()
	data["schema_version"] = 1
	var migrations: Dictionary = {1: func(old: Dictionary) -> Dictionary: return old}
	assert_true(RunSnapshot.from_dict(data, migrations, 2) != null)
	assert_true(RunSnapshot.from_dict(data, {}, 2) == null, "no migration, no reading")
	assert_push_error("no migration")
