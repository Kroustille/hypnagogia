extends GutTest
## The Run carries a RunState and, in FLOOR mode, generates the floor of its seed (story 4.7, AC 2, 9).

const RUN_SCENE: PackedScene = preload("res://run/run.tscn")
const DEF_PATH: String = "res://data/floors/onset.tres"

var _run: Run


func after_each() -> void:
	if _run != null:
		if _run.get_parent() != null:
			_run.get_parent().remove_child(_run)
		_run.queue_free()
		_run = null


func _start(options: RunOptions) -> Run:
	_run = RUN_SCENE.instantiate() as Run
	_run.setup(options) # before add_child()
	add_child(_run)
	return _run


func _options(mode: RunOptions.Mode, seed_value: int, seeded: bool) -> RunOptions:
	var options: RunOptions = RunOptions.new()
	options.mode = mode
	options.seed_value = seed_value
	options.seeded = seeded
	return options


func _expected_signature(seed_value: int) -> String:
	var def: FloorDef = load(DEF_PATH) as FloorDef
	return FloorGenerator.generate(def, RoomCatalog.pool(def.pool_dir), RunRng.new(seed_value), 0).signature()


func test_defaults_of_the_run_state() -> void:
	var state: RunState = RunState.new()
	assert_eq(state.run_seed, 0)
	assert_false(state.seeded)
	assert_eq(state.floor_index, 0)
	assert_eq(RunOptions.new().seed_value, -1, "no seed asked by default")


func test_a_seeded_run_keeps_its_seed_in_its_state() -> void:
	var run: Run = _start(_options(RunOptions.Mode.ARENA, 4242, true))
	assert_eq(run.state.run_seed, 4242)
	assert_true(run.state.seeded)
	assert_eq(run.state.floor_index, 0)
	assert_eq(run.rng.run_seed, 4242)
	assert_null(run.floor_layout, "the arena run generates no floor")


func test_a_run_without_a_seed_draws_one() -> void:
	var run: Run = _start(_options(RunOptions.Mode.ARENA, 4242, false))
	assert_false(run.state.seeded)
	assert_eq(run.state.run_seed, run.rng.run_seed)
	var negative: Run = _start(_options(RunOptions.Mode.ARENA, -1, true))
	assert_false(negative.state.seeded, "seeded with no seed value is a drawn seed")
	assert_gte(negative.state.run_seed, 0)


func test_a_floor_run_generates_the_floor_of_its_seed() -> void:
	var run: Run = _start(_options(RunOptions.Mode.FLOOR, 123456, true))
	assert_not_null(run.floor_layout)
	assert_true(run.floor_layout.valid, run.floor_layout.failure)
	assert_eq(run.floor_layout.signature(), _expected_signature(123456))
	assert_gt(run.floor_layout.attempts, 0)


func test_the_floor_does_not_depend_on_what_the_run_did_before() -> void:
	var run: Run = _start(_options(RunOptions.Mode.ARENA, 777, true))
	run.rng.stream(RunRng.COMBAT).randi() # the fight draws first
	run.rng.stream(RunRng.COSMETIC).randi()
	assert_eq(run.ensure_floor().signature(), _expected_signature(777))
	assert_same(run.ensure_floor(), run.floor_layout, "generated once")


func test_run_options_from_a_request_know_the_floor_mode() -> void:
	var options: RunOptions = RunOptions.from_request(RunOptions.Mode.FLOOR, 9, true, "")
	assert_eq(options.mode, RunOptions.Mode.FLOOR)
	assert_eq(options.seed_value, 9)
	assert_eq(RunOptions.from_request(99, 0, false, "").mode, RunOptions.Mode.ARENA, "unknown mode: the arena")


func test_a_room_keeps_the_floor_index_of_its_stream() -> void:
	var room: Room = (load("res://rooms/pool/onset/onset_combat_001.tscn") as PackedScene).instantiate() as Room
	room.setup(null, RunRng.new(1), 3)
	assert_eq(room._floor_index, 3)
	room.free()


func test_logging_the_map_generates_the_floor_once() -> void:
	var run: Run = _start(_options(RunOptions.Mode.ARENA, 31337, true))
	assert_null(run.floor_layout)
	run.log_floor_map() # what the F1 panel's G key calls
	assert_not_null(run.floor_layout)
	assert_eq(run.floor_layout.signature(), _expected_signature(31337))
	assert_true(run.floor_layout.to_text().contains("N"), "the map shows the nightmare room")
