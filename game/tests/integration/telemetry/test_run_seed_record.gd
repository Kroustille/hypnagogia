extends GutTest
## The seed of every run is in the telemetry record (story 4.11, AC 5): on the "run_start" event of the run.


func _run_starts(events: Array) -> Array[Dictionary]:
	var starts: Array[Dictionary] = []
	for event: Dictionary in events:
		if event["type"] == "run_start":
			starts.append(event)
	return starts


func test_the_session_records_the_seed_of_each_run() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_started(1.0)
	session.run_seeded("00000C1S", true)
	session.run_started(5.0)
	session.run_seeded("ZZZZZZZZ", false)
	var starts: Array[Dictionary] = _run_starts(session.events)
	assert_eq(starts.size(), 2)
	assert_eq(str(starts[0]["seed"]), "00000C1S")
	var flag0: bool = starts[0]["seeded"] == true
	assert_true(flag0)
	assert_eq(str(starts[1]["seed"]), "ZZZZZZZZ")
	var flag1: bool = starts[1]["seeded"] == false
	assert_true(flag1)


func test_the_event_order_is_unchanged() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_started(1.0)
	session.run_seeded("00000C1S", false)
	var types: Array[String] = []
	for event: Dictionary in session.events:
		types.append(str(event["type"]))
	assert_eq(types, ["session_start", "run_start"] as Array[String])


func test_a_seed_outside_a_run_is_ignored() -> void:
	var session: TelemetrySession = TelemetrySession.new("t")
	session.start(0.0)
	session.run_seeded("00000C1S", false)
	assert_eq(session.events.size(), 1)


func test_the_bus_signal_reaches_the_session_file() -> void:
	Events.run_started.emit()
	Events.run_seeded.emit("00000C1S", true)
	var file: FileAccess = FileAccess.open(Telemetry.session_path(), FileAccess.READ)
	var text: String = file.get_as_text()
	file.close()
	var parsed: Dictionary = JSON.parse_string(text)
	var events: Array = parsed["events"]
	var last: Dictionary = _run_starts(events).back()
	assert_eq(str(last["seed"]), "00000C1S")
	var flag: bool = last["seeded"] == true
	assert_true(flag)
