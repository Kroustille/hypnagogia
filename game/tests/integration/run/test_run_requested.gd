extends GutTest
## Events.run_requested restarts the Run on the asked room; the default plays the floor, the arena stays one request away (stories 4.2 and 4.8).

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const ROOM_002: String = "res://rooms/pool/onset/onset_combat_002.tscn"

var _main: Node


func before_each() -> void:
	Main.start_in_bedroom = false
	_main = MAIN_SCENE.instantiate()
	add_child(_main)
	await get_tree().process_frame


func after_each() -> void:
	remove_child(_main)
	_main.queue_free()


func _current_room() -> Room:
	return get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Room


func test_the_default_run_plays_the_floor_and_the_arena_is_one_request_away() -> void:
	assert_false(_current_room() is Arena)
	assert_eq(_current_room().room_type, Room.RoomType.START)
	Events.run_requested.emit(RunOptions.Mode.ARENA, 0, false, "")
	await get_tree().process_frame
	assert_true(_current_room() is Arena)


func test_run_requested_in_room_mode_plays_that_room_then_back_to_the_arena() -> void:
	Events.run_requested.emit(RunOptions.Mode.ROOM, 0, false, ROOM_002)
	await get_tree().process_frame
	assert_eq(_current_room().scene_file_path, ROOM_002)
	assert_false(_current_room() is Arena)
	Events.run_requested.emit(RunOptions.Mode.ARENA, 0, false, "")
	await get_tree().process_frame
	assert_true(_current_room() is Arena)


func test_a_seeded_request_uses_its_seed() -> void:
	Events.run_requested.emit(RunOptions.Mode.ROOM, 123456, true, ROOM_002)
	await get_tree().process_frame
	var run: Run = get_tree().get_first_node_in_group(Const.GROUP_ROOM).get_parent().get_parent() as Run
	assert_eq(run.rng.run_seed, 123456)
