extends GutTest
## The shards held at the end of a run are written in its "run_end" (story 5.4).


func test_run_end_carries_the_shards_held_and_the_next_run_starts_from_zero() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_started(1.0)
	session.shards_changed(0)
	session.shards_changed(5)
	session.shards_changed(8)
	session.run_ended(5.0)
	var first: Dictionary = session.events.back()
	var held: int = first["shards"]
	assert_eq(held, 8)
	session.run_started(6.0)
	session.run_ended(7.0)
	var second: Dictionary = session.events.back()
	var after: int = second["shards"]
	assert_eq(after, 0)
