extends GutTest
## SaveService (story 6.7): atomic JSON write, quarantine, injectable folder.

var _dir: SaveDir


func before_each() -> void:
	_dir = SaveDir.new()


func after_each() -> void:
	_dir.restore()


func _put(name: String, text: String) -> String:
	var path: String = _dir.file(name)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	return path


func test_the_injected_folder_is_where_files_go() -> void:
	assert_eq(SaveService.path_of("a.json"), _dir.path + "/a.json")
	assert_ne(SaveService.directory(), "user://")


func test_a_written_file_reads_back_the_same_without_a_temporary_file() -> void:
	var path: String = _dir.file("a.json")
	var data: Dictionary = {"n": 3, "name": "x", "list": ["a", "b"], "nested": {"k": true}}
	assert_true(SaveService.write_json(path, data))
	var read: Variant = SaveService.read_json(path)
	assert_eq(SaveService.last_read_status, SaveService.Status.OK)
	assert_eq(JsonView.d(read), JsonView.d(JSON.parse_string(JSON.stringify(data))))
	assert_false(FileAccess.file_exists(path + ".tmp"))


func test_a_write_replaces_the_previous_content() -> void:
	var path: String = _dir.file("a.json")
	SaveService.write_json(path, {"v": 1})
	SaveService.write_json(path, {"v": 2})
	assert_eq(JsonView.n(JsonView.d(SaveService.read_json(path))["v"]), 2)


func test_a_write_into_a_missing_folder_fails_and_returns_false() -> void:
	var path: String = _dir.path + "/nope/a.json"
	assert_false(SaveService.write_json(path, {}))
	assert_push_error("cannot write")
	assert_false(FileAccess.file_exists(path))


func test_a_missing_file_gives_null_without_quarantine() -> void:
	var path: String = _dir.file("none.json")
	assert_true(SaveService.read_json(path) == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.MISSING)
	assert_false(FileAccess.file_exists(path + ".corrupt"))


func test_an_unreadable_file_is_renamed_and_an_older_quarantine_is_replaced() -> void:
	var path: String = _put("a.json", "{ not json")
	_put("a.json.corrupt", "old")
	assert_true(SaveService.read_json(path) == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.CORRUPT)
	assert_false(FileAccess.file_exists(path))
	assert_eq(FileAccess.get_file_as_string(path + ".corrupt"), "{ not json")


func test_a_root_that_is_not_an_object_is_corrupt() -> void:
	var path: String = _put("a.json", "[1, 2]")
	assert_true(SaveService.read_json(path) == null)
	assert_true(FileAccess.file_exists(path + ".corrupt"))
