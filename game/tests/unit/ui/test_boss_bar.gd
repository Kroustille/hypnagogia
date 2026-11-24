extends GutTest
## The boss health bar and the chalk title (story 6.1): they follow the bus and hide without a boss.

var _bar: BossBar
var _title: ChalkTitle


func before_each() -> void:
	_bar = BossBar.new()
	add_child_autofree(_bar)
	_title = ChalkTitle.new()
	add_child_autofree(_title)


func test_the_bar_is_hidden_until_a_boss_comes() -> void:
	assert_false(_bar.visible)
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	assert_true(_bar.visible)
	assert_eq(_bar.share(), 1.0)


func test_the_bar_follows_the_hit_points() -> void:
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	Events.boss_health_changed.emit(1250.0, 2500.0)
	assert_almost_eq(_bar.share(), 0.5, 1e-6)
	Events.boss_health_changed.emit(25.0, 2500.0)
	assert_almost_eq(_bar.share(), 0.01, 1e-6)
	assert_true(_bar.visible)


func test_the_bar_hides_at_zero_hit_points_and_with_the_run() -> void:
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	Events.boss_health_changed.emit(0.0, 2500.0)
	assert_false(_bar.visible, "the boss is gone")
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	Events.run_ended.emit(0)
	assert_false(_bar.visible, "the run is over")
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	Events.run_started.emit()
	assert_false(_bar.visible, "a new run")


func test_the_bar_shows_the_name_from_the_strings() -> void:
	Events.boss_engaged.emit(&"professor", &"BOSS_PROFESSOR_NAME", 2500.0)
	assert_eq((_bar.get_node("Name") as Label).text, tr(&"BOSS_PROFESSOR_NAME"))
	assert_ne((_bar.get_node("Name") as Label).text, "BOSS_PROFESSOR_NAME", "the key is translated")


func test_the_title_is_written_letter_by_letter_then_goes() -> void:
	Events.boss_announced.emit(&"professor", &"BOSS_PROFESSOR_PHASE_1")
	assert_true(_title.visible)
	assert_eq(_title.written(), "")
	_title._process(0.2)
	var partial: String = _title.written()
	assert_gt(partial.length(), 0)
	assert_lt(partial.length(), tr(&"BOSS_PROFESSOR_PHASE_1").length())
	_title._process(0.5)
	assert_eq(_title.written(), tr(&"BOSS_PROFESSOR_PHASE_1"))
	_title._process(ChalkTitle.HOLD_SECONDS + 0.1)
	assert_false(_title.visible)


func test_the_title_is_wiped_when_the_boss_falls() -> void:
	Events.boss_announced.emit(&"professor", &"BOSS_PROFESSOR_EXTRA")
	_title._process(0.3)
	assert_gt(_title.written().length(), 0)
	Events.boss_defeated.emit(&"professor")
	assert_eq(_title.written(), "")
	assert_false(_title.visible)
