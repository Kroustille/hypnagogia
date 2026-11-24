extends GutTest
## Achievements (story 6.7): first victory, achievements, statistics, typed seeds, one write per event.

const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")

var _dir: SaveDir
var _profile: Profile
var _achievements: Achievements
var _path: String


func before_each() -> void:
	_dir = SaveDir.new()
	_path = SaveService.path_of(Profile.FILE_NAME)
	_profile = Profile.new()
	_achievements = Achievements.new()
	_achievements.setup(_profile, _path)
	add_child(_achievements)


func after_each() -> void:
	remove_child(_achievements)
	_achievements.free()
	_dir.restore()


func _start(seed_code: String = "ABCD", seeded: bool = false) -> void:
	Events.run_started.emit()
	Events.run_seeded.emit(seed_code, seeded)


func _stored() -> Dictionary:
	return JsonView.d(SaveService.read_json(_path))


func _end(outcome: int, minute: int = 1400) -> void:
	Events.wake_time_set.emit(minute)
	Events.run_ended.emit(outcome)


func test_the_first_victory_is_recorded_at_run_ended_with_its_statistics() -> void:
	_start("WXYZ")
	Events.item_acquired.emit(&"falling_tooth", 1)
	Events.boss_defeated.emit(&"professor")
	assert_false(FileAccess.file_exists(_path), "not written at boss_defeated")
	_end(Run.Outcome.VICTORY, 1405)
	var entry: Dictionary = JsonView.d(JsonView.d(_stored()["first_victories"])["professor"])
	assert_eq(JsonView.s(entry["seed"]), "WXYZ")
	assert_eq(JsonView.a(entry["items"]), ["falling_tooth"])
	assert_eq(JsonView.n(entry["wake_minute"]), 1405)
	assert_true(entry.has("date") and entry.has("duration"))
	assert_eq(_profile.victories, 1)


func test_a_second_victory_changes_nothing_but_the_counters() -> void:
	_start("AAAA")
	Events.boss_defeated.emit(&"professor")
	_end(Run.Outcome.VICTORY)
	_start("BBBB")
	Events.boss_defeated.emit(&"professor")
	_end(Run.Outcome.VICTORY)
	var kept: Dictionary = _profile.first_victories["professor"]
	assert_eq(JsonView.s(kept["seed"]), "AAAA")
	assert_eq(_profile.victories, 2)
	assert_eq(_profile.first_victories.size(), 1)


func test_a_defeat_after_the_boss_is_not_a_victory() -> void:
	_start()
	Events.boss_defeated.emit(&"professor")
	_end(Run.Outcome.DEATH)
	assert_true(_profile.first_victories.is_empty())


func test_total_abandon_room_and_synergy_three_once_each() -> void:
	_start()
	Events.room_cleared.emit(null, 0)
	assert_false(_profile.achievements.has("total_abandon_room"))
	Events.room_cleared.emit(null, Lucidity.Tier.TOTAL_ABANDON)
	Events.synergy_activated.emit(&"fall_2", 2)
	assert_false(_profile.achievements.has("synergy_three"), "a two item synergy is not enough")
	Events.synergy_activated.emit(&"fall_3", 3)
	var first: Dictionary = _profile.achievements["synergy_three"].duplicate()
	assert_true(JsonView.d(_stored()["achievements"]).has("total_abandon_room"))
	Events.synergy_activated.emit(&"fall_3", 3)
	Events.room_cleared.emit(null, Lucidity.Tier.TOTAL_ABANDON)
	assert_eq(_profile.achievements["synergy_three"] as Dictionary, first)
	assert_eq(_profile.achievements.size(), 2)


func test_a_death_updates_the_statistics_only() -> void:
	_start()
	Events.item_acquired.emit(&"falling_tooth", 1)
	_end(Run.Outcome.DEATH, 1380)
	var stats: Dictionary = JsonView.d(_stored()["stats"])
	assert_eq(JsonView.n(stats["runs"]), 1)
	assert_eq(JsonView.n(stats["deaths"]), 1)
	assert_eq(JsonView.n(stats["victories"]), 0)
	assert_eq(JsonView.n(stats["last_wake_minute"]), 1380)
	assert_true(JsonView.d(_stored()["first_victories"]).is_empty())
	assert_true(JsonView.d(_stored()["achievements"]).is_empty())
	assert_true(JsonView.a(_stored()["unlocks"]).is_empty())


func test_a_typed_seed_records_nothing() -> void:
	_start("SEED", true)
	Events.room_cleared.emit(null, Lucidity.Tier.TOTAL_ABANDON)
	Events.synergy_activated.emit(&"fall_3", 3)
	Events.boss_defeated.emit(&"professor")
	_end(Run.Outcome.VICTORY)
	assert_false(FileAccess.file_exists(_path))
	assert_eq(_profile.runs, 0)
	assert_eq(_profile.last_wake_minute, -1)
	assert_true(_profile.achievements.is_empty() and _profile.first_victories.is_empty())


func test_a_new_run_resets_the_typed_seed_state() -> void:
	_start("SEED", true)
	_start("FREE", false)
	Events.room_cleared.emit(null, Lucidity.Tier.TOTAL_ABANDON)
	assert_true(_profile.achievements.has("total_abandon_room"))


func test_a_locked_profile_is_never_written() -> void:
	_profile.writable = false
	_start()
	_end(Run.Outcome.DEATH)
	assert_false(FileAccess.file_exists(_path))


func test_the_player_build_reports_a_synergy_on_the_bus() -> void:
	var reported: Array[int] = []
	var on_synergy: Callable = func(_id: StringName, threshold: int) -> void: reported.append(threshold)
	Events.synergy_activated.connect(on_synergy)
	var harness: RoomHarness = RoomHarness.new()
	add_child(harness)
	harness.start("res://tests/fixtures/rooms/pit_band.tscn")
	harness.player.carrier.acquire(TOOTH)
	harness.player.carrier.acquire(preload("res://data/items/lead_legs.tres"))
	harness.release()
	Events.synergy_activated.disconnect(on_synergy)
	assert_eq(reported, [2] as Array[int])
