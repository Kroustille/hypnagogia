extends GutTest
## A pre-drawn room plays its waves from its markers, in order, and is cleared once (story 4.2, AC 4 to 6).

const ROOM_001: String = "res://rooms/pool/onset/onset_combat_001.tscn"
const START_ROOM: String = "res://tests/fixtures/rooms/start_room.tscn"
## Generous ceilings, in ticks: the first wave comes after 1 s and each following one 2 s after the previous is cleared.
const WAVE_TICKS: int = 400

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func _cleared_count() -> int:
	return get_signal_emit_count(Events, "room_cleared")


func test_waves_follow_the_markers_in_order_and_the_room_is_cleared_once() -> void:
	watch_signals(Events)
	_harness.start(ROOM_001)
	assert_eq(_harness.living_enemies().size(), 0, "nothing before the first wave delay")
	var appeared: bool = await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	assert_true(appeared, "wave 0 brings its three markers")
	assert_eq(_harness.living_names(), PackedStringArray(["sleepwalker_1", "sleepwalker_2", "sleepwalker_3"]))
	assert_eq(_cleared_count(), 0)

	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.living_names() == PackedStringArray(["night_light_4", "night_light_5", "sleepwalker_6"]), WAVE_TICKS)
	assert_eq(_harness.living_names(), PackedStringArray(["night_light_4", "night_light_5", "sleepwalker_6"]), "wave 1: its markers, in tree order")
	assert_eq(_cleared_count(), 0, "a cleared wave that is not the last one clears nothing")

	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _cleared_count() > 0, WAVE_TICKS)
	assert_eq(_cleared_count(), 1, "the room is cleared after the last wave")
	assert_eq(_harness.room.wave_runner().state_name(), "DONE")
	await _harness.ticks(WAVE_TICKS)
	assert_eq(_cleared_count(), 1, "cleared once only")
	assert_eq(_harness.living_enemies().size(), 0, "nothing appears again")


func test_waves_start_in_the_order_of_their_wave_value() -> void:
	_harness.start(ROOM_001)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS)
	var runner: WaveRunner = _harness.room.wave_runner()
	assert_eq(runner.wave_number(), 1)
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return runner.wave_number() == 2, WAVE_TICKS)
	assert_eq(runner.wave_number(), 2)


func test_later_waves_keep_the_room_lucidity_and_the_single_reinforcement() -> void:
	_harness.start(ROOM_001)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	# A dive to the lowest tier calls the one reinforcement of the fight.
	_harness.player.lucidity.set_value(0)
	await _harness.ticks(2)
	assert_eq(_harness.room.pending_reinforcement_count(), 1, "the reinforcement is announced")
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 4, WAVE_TICKS)
	assert_eq(_harness.living_enemies().size(), 4, "it appears: one more enemy in wave 0")
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.room.wave_runner().wave_number() == 2, WAVE_TICKS)
	await _harness.ticks(2)
	assert_eq(_harness.room.pending_reinforcement_count(), 0, "begin_wave does not rearm the reinforcement")
	assert_eq(_harness.living_enemies().size(), 3, "wave 1 has only its own markers")
	assert_eq(_harness.player.lucidity.room_tier, Lucidity.Tier.TOTAL_ABANDON, "the room tier is not reset")


func test_a_room_without_enemy_marker_stays_open_and_runs_no_wave() -> void:
	watch_signals(Events)
	_harness.start(START_ROOM)
	await _harness.ticks(WAVE_TICKS)
	assert_null(_harness.room.wave_runner(), "no wave runner")
	assert_eq(_cleared_count(), 0)
	for door: Door in _harness.room.doors():
		assert_true(_harness.door_is_open(door), "door %s stays open" % Door.Side.find_key(door.side))


func test_forcing_the_next_wave_after_the_last_one_finishes_the_room() -> void:
	watch_signals(Events)
	_harness.start(ROOM_001)
	var runner: WaveRunner = _harness.room.wave_runner()
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS)
	runner.force_next_wave() # wave 0 -> wave 1, the last one
	await _harness.ticks(2)
	assert_eq(runner.wave_number(), 2)
	runner.force_next_wave() # no wave is left: the room ends, wave 0 does not come back
	await _harness.ticks(2)
	assert_eq(runner.state_name(), "DONE")
	assert_eq(runner.wave_number(), 2, "no third wave")
	assert_eq(_cleared_count(), 1)
	assert_true(_harness.room.is_cleared())
	await _harness.ticks(WAVE_TICKS)
	assert_eq(_harness.living_enemies().size(), 0, "nothing appears again")


func test_an_apparition_is_moved_off_an_interior_wall_and_a_pit() -> void:
	_harness.start(ROOM_001)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS)
	var walls: TileMapLayer = _harness.room.get_node("Walls") as TileMapLayer
	var pits: TileMapLayer = _harness.room.get_node("Pits") as TileMapLayer
	var wall_cell: Vector2i = Vector2i(30, 5)
	var pit_cell: Vector2i = Vector2i(30, 15)
	walls.set_cell(wall_cell, Room.TILE_WALL, Vector2i.ZERO)
	pits.set_cell(pit_cell, Room.TILE_PIT, Vector2i.ZERO)
	var def: EnemyDef = load("res://data/enemies/sleepwalker.tres") as EnemyDef
	for cell: Vector2i in [wall_cell, pit_cell]:
		var requested: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * Const.TILE_SIZE
		var enemy: Enemy = _harness.room.spawn_enemy(def, requested)
		assert_not_null(enemy, "an enemy appears for %s" % cell)
		if enemy == null:
			continue
		var landed: Vector2i = Vector2i((_harness.room.to_local(enemy.global_position) / Const.TILE_SIZE).floor())
		assert_ne(landed, cell, "moved away from the cell %s" % cell)
		assert_eq(walls.get_cell_source_id(landed), -1, "not on a wall")
		assert_eq(pits.get_cell_source_id(landed), -1, "not on a pit")


func test_cancelling_an_announced_reinforcement_rearms_it() -> void:
	_harness.start(ROOM_001)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.player.lucidity.set_value(0)
	await _harness.ticks(2)
	assert_eq(_harness.room.pending_reinforcement_count(), 1, "announced")
	_harness.room.cancel_pending_reinforcements() # a wave that could not appear
	assert_eq(_harness.room.pending_reinforcement_count(), 0)
	var defs: Array[EnemyDef] = [load("res://data/enemies/sleepwalker.tres") as EnemyDef]
	_harness.room.begin_wave(defs)
	assert_eq(_harness.room.pending_reinforcement_count(), 1, "the next wave still gets its reinforcement")


func test_a_reinforcement_that_appeared_is_not_rearmed_by_a_cancel() -> void:
	_harness.start(ROOM_001)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.player.lucidity.set_value(0)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 4, WAVE_TICKS)
	assert_eq(_harness.room.pending_reinforcement_count(), 0)
	_harness.room.cancel_pending_reinforcements() # nothing was pending
	var defs: Array[EnemyDef] = [load("res://data/enemies/sleepwalker.tres") as EnemyDef]
	_harness.room.begin_wave(defs)
	assert_eq(_harness.room.pending_reinforcement_count(), 0, "one reinforcement per room")


func test_markers_without_enemy_leave_no_slot_and_no_entry() -> void:
	var room: Room = (load("res://tests/fixtures/rooms/enemy_missing.tscn") as PackedScene).instantiate() as Room
	var list: WaveList = room._make_wave_list()
	assert_eq(list.waves.size(), 1)
	assert_eq(list.waves[0].entries.size(), 2, "the marker without enemy is dropped")
	assert_eq(list.spawn_slots.size(), 2, "and so is its slot")
	room.free()
