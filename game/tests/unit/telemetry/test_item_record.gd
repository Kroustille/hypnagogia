extends GutTest
## The items taken are written in the session: per run in "run_end", counted over the session in the summary (story 5.1, AC 10).


func test_items_taken_in_a_run_are_listed_in_its_run_end_and_counted_in_the_summary() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_started(1.0)
	session.item_taken("falling_tooth")
	session.item_taken("falling_tooth")
	session.item_taken("lead_legs")
	session.run_ended(5.0)
	var run_end: Dictionary = session.events.back()
	var kind: String = run_end["type"]
	assert_eq(kind, "run_end")
	var listed: Array = run_end["items"]
	assert_eq(listed, ["falling_tooth", "falling_tooth", "lead_legs"])
	var summary: Dictionary = session.to_dict(6.0)["summary"]
	var counted: Dictionary = summary["items"]
	assert_eq(counted, {"falling_tooth": 2, "lead_legs": 1})


func test_a_new_run_starts_with_an_empty_list_and_an_item_outside_a_run_is_ignored() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.item_taken("lead_legs") # no run yet
	session.run_started(1.0)
	session.item_taken("lead_legs")
	session.run_ended(2.0)
	session.run_started(3.0)
	session.run_ended(4.0)
	var listed: Array = session.events.back()["items"]
	assert_eq(listed.size(), 0)
	assert_eq(session.items, {"lead_legs": 1})
