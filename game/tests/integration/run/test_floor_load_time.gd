extends GutTest
## The floor loads in under 2 s (story 6.9, NFR3): from the request of a run to the first tick the player controls the
## start room. Headless threshold: it does not replace the measure on the reference machine (disk, GPU).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
## The budget, in ms, of this check only (not a game value).
const BUDGET_MSEC: int = 2000

var _main: Main
var _ready_times: Array[Vector2i] = []


func before_each() -> void:
	Main.start_in_bedroom = false
	_ready_times.clear()
	Events.floor_ready.connect(_on_floor_ready)
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func after_each() -> void:
	Events.floor_ready.disconnect(_on_floor_ready)
	GameClock.paused = false
	RoomLoader.collect_orphans(true)
	remove_child(_main)
	_main.queue_free()


func _on_floor_ready(startup_ms: int, load_ms: int) -> void:
	_ready_times.append(Vector2i(startup_ms, load_ms))


func test_the_first_floor_is_ready_within_the_budget() -> void:
	assert_eq(_ready_times.size(), 1, "announced once at launch")
	assert_lte(_ready_times[0].y, BUDGET_MSEC)
	assert_lte(_ready_times[0].x, _ready_times[0].y, "the run is part of the whole request")


func test_every_new_night_is_ready_within_the_budget_and_written_in_the_telemetry() -> void:
	for index: int in 3:
		Events.run_requested.emit(RunOptions.Mode.FLOOR, -1, false, "")
		await wait_physics_frames(2)
	assert_eq(_ready_times.size(), 4)
	for times: Vector2i in _ready_times:
		assert_lte(times.y, BUDGET_MSEC)
		assert_gte(times.x, 0)
	var detail: Dictionary = Telemetry.session().events.filter(func(event: Dictionary) -> bool: return event["type"] == "run_start").back()
	assert_true(detail.has("load_ms"))
	assert_lte(int(str(detail["load_ms"])), BUDGET_MSEC)
