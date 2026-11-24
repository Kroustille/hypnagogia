extends GutTest
## The outcome of a run in the telemetry (story 6.4): a victory is no death.


func _session() -> TelemetrySession:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_started(1.0)
	return session


func _types(session: TelemetrySession) -> Array:
	return session.events.map(func(event: Dictionary) -> String: return event["type"])


func test_a_victory_writes_a_victory_and_no_death_nor_question() -> void:
	var session: TelemetrySession = _session()
	session.run_ended(5.0, TelemetrySession.OUTCOME_VICTORY)
	session.victory(5.0)
	assert_eq(session.victories, 1)
	assert_eq(session.deaths, 0)
	assert_eq(_types(session), ["session_start", "run_start", "run_end", "victory"])
	var run_end: Dictionary = session.events[2]
	var victory_outcome: String = run_end["outcome"]
	assert_eq(victory_outcome, "victory")
	assert_false(session.answer(6.0, true), "nothing to answer")
	session.end(7.0)
	assert_eq(session.no_answer, 0)
	var summary: Dictionary = session.to_dict(7.0)["summary"]
	var victories: int = summary["victories"]
	assert_eq(victories, 1)


func test_a_death_is_as_before_with_its_outcome() -> void:
	var session: TelemetrySession = _session()
	session.run_ended(5.0)
	session.death(5.0, "bullet")
	assert_eq(session.deaths, 1)
	assert_eq(session.victories, 0)
	assert_eq(_types(session), ["session_start", "run_start", "run_end", "death"])
	var death_outcome: String = session.events[2]["outcome"]
	assert_eq(death_outcome, "death")
	assert_true(session.answer(6.0, false))


func test_a_run_cut_by_a_restart_is_abandoned() -> void:
	var session: TelemetrySession = _session()
	session.run_started(4.0)
	var cut_outcome: String = session.events[2]["outcome"]
	assert_eq(cut_outcome, "abandoned")
