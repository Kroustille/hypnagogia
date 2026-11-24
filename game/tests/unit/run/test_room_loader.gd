extends GutTest
## Background loading of the rooms of a floor (story 4.8, AR17).

const ROOM_A: String = "res://rooms/pool/onset/onset_combat_002.tscn"
const ROOM_B: String = "res://rooms/pool/onset/onset_combat_003.tscn"
const MAX_WAIT_MSEC: int = 10000


func test_a_requested_scene_becomes_ready_and_is_handed_over_once() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(PackedStringArray([ROOM_A, ROOM_B]))
	assert_eq(loader.pending_count(), 2)
	var start: int = Time.get_ticks_msec()
	while not loader.is_ready(ROOM_A) and Time.get_ticks_msec() - start < MAX_WAIT_MSEC:
		await get_tree().process_frame
	assert_true(loader.is_ready(ROOM_A), "the background load finishes")
	var scene: PackedScene = loader.scene_for(ROOM_A)
	assert_not_null(scene)
	assert_same(loader.scene_for(ROOM_A), scene, "the same scene again, no second collection")
	assert_true(loader.is_ready(ROOM_A))
	assert_eq(loader.pending_count(), 1, "the other room is still to collect")
	loader.drain()
	assert_eq(loader.pending_count(), 0)


func test_scene_for_waits_for_a_scene_that_is_not_ready() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(PackedStringArray([ROOM_B]))
	var scene: PackedScene = loader.scene_for(ROOM_B) # blocks until loaded
	assert_not_null(scene)
	assert_eq(loader.pending_count(), 0)


func test_a_path_never_requested_is_loaded_on_the_spot() -> void:
	var loader: RoomLoader = RoomLoader.new()
	assert_false(loader.is_ready(ROOM_A), "not requested: not ready")
	assert_not_null(loader.scene_for(ROOM_A))
	assert_true(loader.is_ready(ROOM_A))


func test_requesting_twice_does_not_double_the_request() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(PackedStringArray([ROOM_A]))
	loader.request_all(PackedStringArray([ROOM_A]))
	assert_eq(loader.pending_count(), 1)
	loader.drain()
