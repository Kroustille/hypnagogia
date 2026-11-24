extends GutTest
## Leaving a run does not wait for the room loads in progress (story 4.11, deferred from 4.8): they are handed to the
## next loader, which collects them when they are over.

const ROOMS_DIR: String = "res://rooms/pool/onset"


func after_each() -> void:
	RoomLoader.collect_orphans(true)


func _paths() -> PackedStringArray:
	return RoomInfo.scene_paths(ROOMS_DIR)


func test_drain_leaves_no_pending_request_in_the_loader() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(_paths())
	assert_gt(loader.pending_count(), 0)
	loader.drain()
	assert_eq(loader.pending_count(), 0)


func test_the_requests_left_in_progress_are_collected_by_a_wait() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(_paths())
	loader.drain()
	RoomLoader.collect_orphans(true)
	assert_eq(RoomLoader.orphan_count(), 0)


func test_a_new_loader_can_ask_again_for_a_room_a_past_run_was_loading() -> void:
	var paths: PackedStringArray = _paths()
	var first: RoomLoader = RoomLoader.new()
	first.request_all(paths)
	first.drain()
	var second: RoomLoader = RoomLoader.new()
	second.request_all(paths)
	for path: String in paths:
		assert_not_null(second.scene_for(path), path)
	second.drain()


func test_drain_never_waits_for_a_load_in_progress() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(_paths())
	var pending: int = loader.pending_count()
	loader.status_of = func(_path: String) -> int: return ResourceLoader.THREAD_LOAD_IN_PROGRESS
	loader.drain()
	assert_eq(RoomLoader.orphan_count(), pending, "every request still loading is handed over, none awaited")
