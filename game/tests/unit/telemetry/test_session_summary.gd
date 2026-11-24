extends GutTest
## The indicators of milestone B in the session (story 6.9): the duration and the outcome of each run, the time below
## Lucid, the attempts against the boss.

const BOSS: String = "professor"


func _session() -> TelemetrySession:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	return session


## A run of `seconds` of play with 10 s in the tier after Lucid (index 1) and the rest in Lucid, ended by outcome.
func _play_run(session: TelemetrySession, start: float, seconds: float, outcome: String) -> void:
	session.run_started(start)
	session.run_seeded("SEED%d" % session.runs, false)
	session.tier_changed(start + seconds - 10.0, Lucidity.Tier.FLOATING)
	session.advance_play(seconds)
	session.run_ended(start + seconds, outcome, 1419)


func test_each_run_has_its_duration_outcome_wake_and_seed() -> void:
	var session: TelemetrySession = _session()
	_play_run(session, 1.0, 100.0, TelemetrySession.OUTCOME_VICTORY)
	_play_run(session, 200.0, 40.0, TelemetrySession.OUTCOME_DEATH)
	assert_eq(session.runs_detail.size(), 2)
	var first: Dictionary = session.runs_detail[0]
	assert_eq(_s(first, "outcome"), "victory")
	assert_eq(_f(first, "duration_seconds"), 100.0)
	assert_eq(_s(first, "wake"), "23:39")
	assert_eq(_s(first, "seed"), "SEED1")
	assert_eq(_s(session.runs_detail[1], "outcome"), "death")
	assert_eq(_f(session.runs_detail[1], "duration_seconds"), 40.0)


func test_the_time_below_lucid_is_the_sum_of_the_tiers_after_the_first() -> void:
	var session: TelemetrySession = _session()
	session.run_started(0.0)
	session.tier_changed(30.0, Lucidity.Tier.FLOATING)
	session.tier_changed(40.0, Lucidity.Tier.DRIFT)
	session.tier_changed(45.0, Lucidity.Tier.ABANDON)
	session.run_ended(50.0)
	var run: Dictionary = session.runs_detail[0]
	assert_almost_eq(_f(run, "below_lucid_seconds"), 20.0, 0.01)
	assert_almost_eq(_f(run, "below_lucid_share"), 0.4, 0.001)
	var summary: Dictionary = JsonView.d(session.to_dict(50.0)["summary"])
	assert_almost_eq(_f(summary, "below_lucid_seconds"), 20.0, 0.01)
	assert_almost_eq(_f(summary, "below_lucid_share"), 0.4, 0.001)


func test_the_share_stays_between_zero_and_one_and_an_empty_session_has_none() -> void:
	var session: TelemetrySession = _session()
	var empty: Dictionary = JsonView.d(session.to_dict(1.0)["summary"])
	assert_eq(_f(empty, "below_lucid_share"), 0.0)
	session.run_started(0.0)
	session.tier_changed(0.0, Lucidity.Tier.TOTAL_ABANDON)
	session.run_ended(10.0)
	var share: float = _f(session.runs_detail[0], "below_lucid_share")
	assert_between(share, 0.0, 1.0)
	assert_eq(share, 1.0)


func test_the_existing_summary_keys_keep_their_meaning() -> void:
	var session: TelemetrySession = _session()
	_play_run(session, 1.0, 100.0, TelemetrySession.OUTCOME_DEATH)
	var summary: Dictionary = JsonView.d(session.to_dict(120.0)["summary"])
	assert_eq(_i(summary, "runs"), 1)
	assert_almost_eq(_f(JsonView.d(summary["tier_seconds"]), "lucid"), 90.0, 0.01)
	assert_almost_eq(_f(JsonView.d(summary["tier_seconds"]), "floating"), 10.0, 0.01)


func test_a_pause_is_not_part_of_the_duration() -> void:
	var session: TelemetrySession = _session()
	session.run_started(0.0)
	session.advance_play(30.0) # 30 s played, then a long pause nobody feeds, then 20 s
	session.advance_play(20.0)
	session.run_ended(900.0)
	assert_eq(_f(session.runs_detail[0], "duration_seconds"), 50.0)


func test_a_victory_against_the_boss() -> void:
	var session: TelemetrySession = _session()
	session.run_started(0.0)
	session.boss_engaged(5.0, BOSS)
	session.boss_phase(0)
	session.boss_health(50.0, 100.0)
	session.boss_phase(2)
	session.boss_defeated(20.0)
	session.boss_health(0.0, 100.0) # the bar hides
	session.run_ended(22.0, TelemetrySession.OUTCOME_VICTORY)
	assert_eq(session.boss_attempts.size(), 1)
	var attempt: Dictionary = session.boss_attempts[0]
	assert_eq(_s(attempt, "outcome"), "victory")
	assert_eq(_f(attempt, "hp_left"), 0.0)
	assert_eq(_i(attempt, "phase"), 2)
	assert_eq(_s(attempt, "boss"), BOSS)


func test_a_death_at_the_boss_keeps_the_phase_and_the_hit_points_left() -> void:
	var session: TelemetrySession = _session()
	session.run_started(0.0)
	session.boss_engaged(5.0, BOSS)
	session.boss_health(60.0, 100.0)
	session.boss_phase(1)
	session.run_ended(30.0, TelemetrySession.OUTCOME_DEATH)
	session.boss_health(0.0, 100.0) # the room is torn down after the end
	var attempt: Dictionary = session.boss_attempts[0]
	assert_eq(_s(attempt, "outcome"), "death")
	assert_almost_eq(float(_f(attempt, "hp_left")), 0.6, 0.001)
	assert_eq(_i(attempt, "phase"), 1)


func test_a_restart_during_the_fight_is_an_abandoned_attempt() -> void:
	var session: TelemetrySession = _session()
	session.run_started(0.0)
	session.boss_engaged(5.0, BOSS)
	session.boss_health(90.0, 100.0)
	session.run_started(40.0) # the player restarted: no run_ended
	assert_eq(session.boss_attempts.size(), 1)
	assert_eq(_s(session.boss_attempts[0], "outcome"), "abandoned")
	assert_eq(_s(session.runs_detail[0], "outcome"), "abandoned")


func test_a_death_before_the_boss_makes_no_attempt() -> void:
	var session: TelemetrySession = _session()
	_play_run(session, 0.0, 30.0, TelemetrySession.OUTCOME_DEATH)
	assert_eq(session.boss_attempts.size(), 0)
	session.boss_health(10.0, 100.0)
	session.boss_phase(1)
	assert_eq(session.boss_attempts.size(), 0, "outside a run nothing starts")


func test_the_sections_are_in_the_file() -> void:
	var session: TelemetrySession = _session()
	_play_run(session, 0.0, 30.0, TelemetrySession.OUTCOME_DEATH)
	var data: Dictionary = JsonView.d(JSON.parse_string(JSON.stringify(session.to_dict(40.0))))
	assert_true(data.has("runs_detail"))
	assert_true(data.has("boss_attempts"))


func test_the_load_times_go_to_the_run_start_and_the_detail() -> void:
	var session: TelemetrySession = _session()
	session.run_started(1.0)
	session.floor_ready(12, 80)
	session.run_ended(5.0)
	var start: Dictionary = session.events[1]
	assert_eq(_i(start, "startup_ms"), 12)
	assert_eq(_i(start, "load_ms"), 80)
	assert_eq(_i(session.runs_detail[0], "load_ms"), 80)


func _s(data: Dictionary, key: String) -> String:
	var value: String = str(data[key])
	return value


func _f(data: Dictionary, key: String) -> float:
	var value: float = data[key]
	return value


func _i(data: Dictionary, key: String) -> int:
	var value: int = data[key]
	return value
