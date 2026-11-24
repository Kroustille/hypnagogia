extends GutTest
## A damaged profile at launch (story 6.7): set aside, new profile, a notice, the game stays playable.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

var _dir: SaveDir
var _main: Main


func before_each() -> void:
	_dir = SaveDir.new()
	Main.start_in_bedroom = false


func after_each() -> void:
	RoomLoader.collect_orphans(true)
	if _main != null:
		remove_child(_main)
		_main.queue_free()
		_main = null
	_dir.restore()


func _write(text: String) -> void:
	var file: FileAccess = FileAccess.open(SaveService.path_of(Profile.FILE_NAME), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _launch() -> void:
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func _notice() -> Notice:
	return _main.find_children("*", "Notice", true, false)[0] as Notice


func test_a_broken_file_is_quarantined_and_the_game_starts_with_a_message() -> void:
	_write("{ broken")
	await _launch()
	var path: String = SaveService.path_of(Profile.FILE_NAME)
	assert_false(FileAccess.file_exists(path))
	assert_true(FileAccess.file_exists(path + ".corrupt"))
	assert_true(_notice().visible)
	assert_eq((_notice().get_child(0) as Label).text, tr(&"UI_PROFILE_CORRUPT"))
	assert_not_null(get_tree().get_first_node_in_group(Const.GROUP_RUN), "the game is playable")


func test_a_newer_version_is_quarantined_too() -> void:
	_write('{"schema_version": 99}')
	await _launch()
	assert_true(FileAccess.file_exists(SaveService.path_of(Profile.FILE_NAME) + ".corrupt"))
	assert_true(_notice().visible)


func test_no_file_means_a_new_profile_without_a_message() -> void:
	await _launch()
	assert_false(_notice().visible)
	assert_false(FileAccess.file_exists(SaveService.path_of(Profile.FILE_NAME)))


func test_the_last_wake_minute_of_the_profile_reaches_the_bedroom_clock() -> void:
	var profile: Profile = Profile.new()
	profile.last_wake_minute = 1425
	assert_true(profile.save(SaveService.path_of(Profile.FILE_NAME)))
	await _launch()
	assert_eq(_main._last_wake_minute, 1425)
