extends GutTest
## Profile (story 6.7): round trip through JSON, migrations, refused versions.


func _round_trip(profile: Profile) -> Profile:
	return Profile.from_dict(JsonView.d(JSON.parse_string(JSON.stringify(profile.to_dict()))))


func test_a_profile_survives_json_with_its_integers() -> void:
	var profile: Profile = Profile.new()
	profile.runs = 5
	profile.victories = 2
	profile.deaths = 3
	profile.last_wake_minute = 1405
	profile.first_victories["professor"] = {"seed": "WXYZ", "duration": 400, "items": ["a", "b"], "wake_minute": 17, "date": "x"}
	profile.achievements["synergy_three"] = {"seed": 9, "duration": 10, "items": [], "wake_minute": -1, "date": "y"}
	var back: Profile = _round_trip(profile)
	assert_eq(back.runs, 5)
	assert_eq(back.deaths, 3)
	assert_eq(back.last_wake_minute, 1405)
	assert_eq(typeof(back.last_wake_minute), TYPE_INT)
	var entry: Dictionary = back.first_victories["professor"]
	assert_eq(JsonView.s(entry["seed"]), "WXYZ")
	assert_eq(typeof(entry["duration"]), TYPE_INT)
	assert_eq(JsonView.a(entry["items"]), ["a", "b"])
	assert_true(back.achievements.has("synergy_three"))
	assert_true(back.unlocks.is_empty())


func test_the_dictionary_carries_the_schema_version() -> void:
	assert_eq(JsonView.n(Profile.new().to_dict()["schema_version"]), Profile.SCHEMA_VERSION)


func test_a_fake_migration_runs_one_version_at_a_time() -> void:
	var migrations: Dictionary = {
		1: func(data: Dictionary) -> Dictionary:
			data["stats"] = {"runs": 7}
			return data,
		2: func(data: Dictionary) -> Dictionary:
			data["achievements"] = {"from_two": {}}
			return data,
	}
	var profile: Profile = Profile.from_dict({"schema_version": 1}, migrations, 3)
	assert_not_null(profile)
	assert_eq(profile.runs, 7)
	assert_true(profile.achievements.has("from_two"))
	assert_eq(JsonView.n(Profile.migrate({"schema_version": 1}, migrations, 3)["schema_version"]), 3)


func test_a_missing_migration_refuses_the_file() -> void:
	assert_null(Profile.from_dict({"schema_version": 1}, {}, 2))
	assert_push_error("no migration")


func test_a_newer_version_is_refused() -> void:
	assert_null(Profile.from_dict({"schema_version": Profile.SCHEMA_VERSION + 1}))


func test_a_missing_or_wrong_version_is_refused() -> void:
	assert_null(Profile.from_dict({}))
	assert_null(Profile.from_dict({"schema_version": "1"}))
	assert_null(Profile.from_dict({"schema_version": 1.5}))
	assert_null(Profile.from_dict({"schema_version": 0}))
