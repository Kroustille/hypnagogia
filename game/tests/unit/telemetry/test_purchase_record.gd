extends GutTest
## A purchase is written in the session as a "purchase" event with the article and its price (story 5.5).


func test_a_purchase_in_a_run_is_recorded_and_one_outside_is_ignored() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	var start_events: int = session.events.size()
	session.purchase(0.5, "heart", 4) # no run yet
	assert_eq(session.events.size(), start_events)
	session.run_started(1.0)
	var before: int = session.events.size()
	session.purchase(2.0, "falling_tooth", 15)
	var event: Dictionary = session.events.back()
	assert_eq(session.events.size(), before + 1)
	var kind: String = event["type"]
	var id: String = event["id"]
	var price: int = event["price"]
	assert_eq(kind, "purchase")
	assert_eq(id, "falling_tooth")
	assert_eq(price, 15)
