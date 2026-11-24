extends GutTest
## run.json (story 6.8): written, read, erased, quarantined, always inside the injected folder.

var _dir: SaveDir


func before_each() -> void:
	_dir = SaveDir.new()


func after_each() -> void:
	_dir.restore()


func _put(name: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(_dir.file(name), FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _snapshot() -> RunSnapshot:
	var snapshot: RunSnapshot = RunSnapshot.new()
	snapshot.state.run_seed = 4242
	snapshot.health = {"half_hearts": 6, "max_half_hearts": 6, "armor": 0, "max_lost": 0}
	snapshot.lucidity = 80
	snapshot.rng_states = {"combat:0": str(1 << 60)}
	return snapshot


func test_a_written_night_is_read_back_and_erased() -> void:
	assert_false(SaveService.has_run())
	assert_true(SaveService.write_run(_snapshot()))
	assert_true(SaveService.has_run())
	assert_true(FileAccess.file_exists(_dir.file("run.json")), "in the injected folder")
	assert_false(FileAccess.file_exists(_dir.file("run.json.tmp")), "no temporary file left")
	var back: RunSnapshot = SaveService.read_run()
	assert_not_null(back)
	assert_eq(back.state.run_seed, 4242)
	assert_eq(JsonView.s(back.rng_states["combat:0"]), str(1 << 60))
	SaveService.delete_run()
	assert_false(SaveService.has_run())
	SaveService.delete_run() # nothing to erase: no error
	assert_true(SaveService.read_run() == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.MISSING)


func test_a_second_write_replaces_the_first() -> void:
	SaveService.write_run(_snapshot())
	var second: RunSnapshot = _snapshot()
	second.state.run_seed = 77
	SaveService.write_run(second)
	assert_eq(SaveService.read_run().state.run_seed, 77)


func test_invalid_json_is_quarantined() -> void:
	_put("run.json", "{ not json")
	assert_true(SaveService.read_run() == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.CORRUPT)
	assert_false(SaveService.has_run())
	assert_true(FileAccess.file_exists(_dir.file("run.json.corrupt")))


func test_a_future_version_is_quarantined_not_read() -> void:
	var data: Dictionary = _snapshot().to_dict()
	data["schema_version"] = RunSnapshot.SCHEMA_VERSION + 1
	_put("run.json", JSON.stringify(data))
	assert_true(SaveService.read_run() == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.CORRUPT)
	assert_true(FileAccess.file_exists(_dir.file("run.json.corrupt")))


func test_a_failed_write_is_reported_and_leaves_the_old_file() -> void:
	SaveService.write_run(_snapshot())
	DirAccess.make_dir_absolute(_dir.file("run.json.tmp")) # a folder where the temporary file goes: the write cannot open it
	var second: RunSnapshot = _snapshot()
	second.state.run_seed = 5
	assert_false(SaveService.write_run(second))
	assert_push_error("cannot write")
	DirAccess.remove_absolute(_dir.file("run.json.tmp"))
	assert_eq(SaveService.read_run().state.run_seed, 4242, "the night saved before is intact")


func test_a_quarantine_that_fails_reads_run_json_as_unreadable() -> void:
	_put("run.json", "{ not json")
	DirAccess.make_dir_recursive_absolute(_dir.file("run.json.corrupt/inner")) # a folder that cannot be replaced by a file
	assert_true(SaveService.read_run() == null)
	assert_eq(SaveService.last_read_status, SaveService.Status.UNREADABLE)
	assert_push_error("cannot quarantine")
	assert_true(SaveService.has_run(), "the file stays where it is")
	DirAccess.remove_absolute(_dir.file("run.json.corrupt/inner"))
	DirAccess.remove_absolute(_dir.file("run.json.corrupt"))
