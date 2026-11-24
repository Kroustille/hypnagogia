extends GutTest
## The attempts against the boss, fed by the real events (story 6.9, AC 5 and 6).

const BOSS: StringName = &"professor"


func _attempts() -> Array[Dictionary]:
	return Telemetry.session().boss_attempts


func _start_run() -> int:
	Events.run_started.emit()
	return _attempts().size()


func test_a_victory_closes_the_attempt_at_the_death_of_the_boss() -> void:
	var before: int = _start_run()
	Events.boss_engaged.emit(BOSS, &"BOSS_PROFESSOR_NAME", 100.0)
	Events.boss_health_changed.emit(100.0, 100.0)
	Events.boss_phase_changed.emit(BOSS, 0)
	Events.boss_health_changed.emit(30.0, 100.0)
	Events.boss_phase_changed.emit(BOSS, 2)
	Events.boss_defeated.emit(BOSS)
	Events.boss_health_changed.emit(0.0, 100.0)
	Events.run_ended.emit(Run.Outcome.VICTORY)
	assert_eq(_attempts().size(), before + 1)
	var attempt: Dictionary = _attempts().back()
	assert_eq(str(attempt["outcome"]), "victory")
	assert_eq(int(str(attempt["phase"])), 2)


func test_a_death_at_the_boss_is_a_death_attempt() -> void:
	var before: int = _start_run()
	Events.boss_engaged.emit(BOSS, &"BOSS_PROFESSOR_NAME", 100.0)
	Events.boss_health_changed.emit(70.0, 100.0)
	Events.run_ended.emit(Run.Outcome.DEATH)
	assert_eq(_attempts().size(), before + 1)
	var attempt: Dictionary = _attempts().back()
	assert_eq(str(attempt["outcome"]), "death")
	assert_almost_eq(float(str(attempt["hp_left"])), 0.7, 0.001)


func test_a_restart_without_the_end_of_the_run_is_abandoned() -> void:
	var before: int = _start_run()
	Events.boss_engaged.emit(BOSS, &"BOSS_PROFESSOR_NAME", 100.0)
	Events.run_started.emit() # the debug panel or a restart: the run never ended
	assert_eq(_attempts().size(), before + 1)
	var attempt: Dictionary = _attempts().back()
	assert_eq(str(attempt["outcome"]), "abandoned")
	Events.run_ended.emit(Run.Outcome.DEATH)


func test_a_death_before_the_boss_has_no_attempt() -> void:
	var before: int = _start_run()
	Events.run_ended.emit(Run.Outcome.DEATH)
	assert_eq(_attempts().size(), before)
