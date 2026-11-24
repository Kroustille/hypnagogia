extends GutTest
## Winning the night (story 6.4): the delay after the boss, the player protected, a single run_ended, defeat first.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const APPEAR_TICKS: int = 120
const ANNOUNCE_TICKS: int = 90

var _harness: RoomHarness
var _outcomes: Array[int] = []


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_outcomes.clear()
	Events.run_ended.connect(_on_run_ended)


func after_each() -> void:
	Events.run_ended.disconnect(_on_run_ended)
	GameClock.paused = false
	_harness.release()


func _on_run_ended(outcome: int) -> void:
	_outcomes.append(outcome)


func _boss() -> Boss:
	for enemy: Enemy in _harness.living_enemies():
		if enemy is Boss:
			return enemy as Boss
	return null


func _fighting_boss() -> Boss:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	await _harness.until(func() -> bool: return boss.is_fighting(), ANNOUNCE_TICKS + 30)
	return boss


func _delay_ticks() -> int:
	return roundi(Tuning.ROOM.boss_victory_delay * Engine.physics_ticks_per_second)


func test_the_victory_comes_after_the_delay_and_only_once() -> void:
	var boss: Boss = await _fighting_boss()
	boss.kill()
	await _harness.ticks(_delay_ticks() - 5)
	assert_eq(_outcomes.size(), 0, "not before the delay")
	await _harness.ticks(10)
	assert_eq(_outcomes, [Run.Outcome.VICTORY] as Array[int])
	await _harness.ticks(120)
	assert_eq(_outcomes.size(), 1)


func test_the_player_is_protected_and_the_doors_are_ignored_during_the_wait() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.player.health.set_forced_invulnerability(false)
	assert_false(_harness.player.health.is_invulnerable())
	boss.kill()
	assert_true(_harness.player.health.is_invulnerable())
	var cell: Vector2i = _harness.run.current_cell()
	_harness.run.travel(0)
	assert_false(_harness.run.is_traveling(), "no trip during the wait")
	assert_eq(_harness.run.current_cell(), cell)
	assert_eq(_harness.player.health.apply_damage(DamageInfo.from_bullet(2.0, Vector2.UP, DamageInfo.Source.ENEMY_BULLET)), 0)


func test_the_pause_freezes_the_delay() -> void:
	var boss: Boss = await _fighting_boss()
	boss.kill()
	GameClock.paused = true
	await _harness.ticks(_delay_ticks() + 30)
	assert_eq(_outcomes.size(), 0)
	GameClock.paused = false
	await _harness.ticks(_delay_ticks() + 5)
	assert_eq(_outcomes, [Run.Outcome.VICTORY] as Array[int])


func test_a_death_before_the_boss_dies_is_a_defeat_for_good() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.run._on_player_died()
	boss.kill()
	await _harness.ticks(_delay_ticks() + 30)
	assert_eq(_outcomes, [Run.Outcome.DEATH] as Array[int])


func test_a_boss_of_a_shallower_floor_does_not_end_the_run() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.run.state.floor_index = 1
	boss.kill()
	await _harness.ticks(_delay_ticks() + 30)
	assert_eq(_outcomes.size(), 0)
