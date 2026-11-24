extends GutTest
## The pop quiz of The Professor in Total abandon (story 6.3): latched ring of 12 chalks every 6 s on top of the phase.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const PROFESSOR: BossDef = preload("res://data/bosses/professor.tres")
const APPEAR_TICKS: int = 120
const ANNOUNCE_TICKS: int = 90
const EXTRA_KEY: StringName = &"BOSS_PROFESSOR_EXTRA"

var _harness: RoomHarness
var _announces: Array[StringName] = []


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_announces.clear()
	Events.boss_announced.connect(_on_announced)


func after_each() -> void:
	Events.boss_announced.disconnect(_on_announced)
	_harness.release()


func _on_announced(_id: StringName, key: StringName) -> void:
	_announces.append(key)


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


func _ring_runner(boss: Boss) -> RingRunner:
	return boss.extra_runner() as RingRunner


func _count(key: StringName) -> int:
	return _announces.count(key)


func test_nothing_starts_above_total_abandon() -> void:
	var boss: Boss = await _fighting_boss()
	await _harness.ticks(1200)
	assert_false(_harness.room.danger.boss_extra_pattern)
	assert_null(boss.extra_runner())
	assert_eq(_count(EXTRA_KEY), 0)


func test_a_room_entered_at_zero_starts_the_ring_after_the_first_announce_and_its_sign() -> void:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(10)
	assert_false(boss.is_fighting())
	assert_null(boss.extra_runner(), "held back while the phase 1 title is written")
	await _harness.until(func() -> bool: return boss.is_fighting(), ANNOUNCE_TICKS + 30)
	await _harness.ticks(2)
	var ring: RingRunner = _ring_runner(boss)
	assert_not_null(ring)
	assert_eq(_count(EXTRA_KEY), 1)
	assert_not_null(ring.current_sign())
	assert_eq(ring.current_sign().shape(), AttackSign.Shape.RING)
	assert_eq(ring.fired_rings(), 0)
	var signed_at: int = _harness.tick_count
	await _harness.until(func() -> bool: return ring.fired_rings() == 1, 120)
	assert_gte(_harness.tick_count - signed_at, 35, "a sign of at least 0.6 s")
	assert_null(ring.current_sign())


func test_a_descent_to_zero_mid_phase_announces_without_pausing_the_other_attacks() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.6)
	await _harness.until(func() -> bool: return boss.is_fighting() and not boss.runners().is_empty(), ANNOUNCE_TICKS + 30)
	var spiral: SpiralRunner = null
	for runner: AttackRunner in boss.runners():
		if runner is SpiralRunner:
			spiral = runner as SpiralRunner
	await _harness.until(func() -> bool: return spiral.is_emitting(), 60)
	_harness.room.danger.boss_extra_pattern = true
	var emissions: int = spiral.emissions()
	var announced_at: int = _harness.tick_count
	await _harness.ticks(1)
	assert_eq(_count(EXTRA_KEY), 1, "announced at once")
	assert_true(boss.is_fighting(), "no pause: the boss stays FIGHTING")
	assert_false(boss.runners().is_empty(), "the phase runners were not stopped")
	await _harness.ticks(24)
	assert_gt(spiral.emissions(), emissions, "the spiral keeps firing")
	var ring: RingRunner = _ring_runner(boss)
	await _harness.until(func() -> bool: return ring.fired_rings() == 1, 120)
	var first: int = _harness.tick_count
	await _harness.until(func() -> bool: return ring.fired_rings() == 2, 600)
	assert_between(_harness.tick_count - first, 359, 361, "every 6 s")
	assert_gte(first - announced_at, 35, "the ring is signed first, at least 0.6 s")


func test_the_ring_stays_when_the_gauge_climbs_and_through_phase_changes_without_doubling() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(2)
	var ring: RingRunner = _ring_runner(boss)
	_harness.room.danger.boss_extra_pattern = false # the gauge climbed back
	await _harness.until(func() -> bool: return ring.fired_rings() == 1, 120)
	boss.debug_set_hp_fraction(0.6)
	await _harness.ticks(ANNOUNCE_TICKS + 5)
	assert_eq(_ring_runner(boss), ring, "the same runner: not restarted")
	boss.debug_set_hp_fraction(0.2)
	await _harness.ticks(ANNOUNCE_TICKS + 5)
	assert_eq(_ring_runner(boss), ring)
	assert_eq(_count(EXTRA_KEY), 1, "announced once")
	var count: int = ring.fired_rings()
	var before: int = _harness.tick_count
	await _harness.until(func() -> bool: return ring.fired_rings() > count, 400)
	await _harness.until(func() -> bool: return ring.fired_rings() > count + 1, 400)
	var rings_in_span: int = ring.fired_rings() - count
	assert_eq(rings_in_span, 2, "one cadence only")
	assert_gt(_harness.tick_count - before, 300)
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(2)
	assert_eq(_count(EXTRA_KEY), 1, "never twice")


func test_each_circle_holds_twelve_chalks_and_draws_nothing() -> void:
	var boss: Boss = await _fighting_boss()
	boss._stop_runners() # only the ring is left: the rows of the Dictée would draw
	var stream: RandomNumberGenerator = boss._run_rng.stream(RunRng.BOSS, boss._floor_index)
	var state_before: int = stream.state
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(2)
	var ring: RingRunner = _ring_runner(boss)
	var manager: BulletManager = _harness.room.enemy_bullets()
	var before: int = manager.active_count
	await _harness.until(func() -> bool: return ring.fired_rings() == 1, 120)
	assert_eq(manager.active_count - before, 12, "twelve chalks")
	assert_eq(stream.state, state_before, "no draw of the boss stream")
	await _harness.until(func() -> bool: return ring.fired_rings() == 2, 400)
	assert_eq(stream.state, state_before)
	assert_eq(manager.refused_count, 0)

func test_the_sign_never_goes_under_0_4_seconds() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.telegraph_mult = 0.1
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(2)
	var ring: RingRunner = _ring_runner(boss)
	var signed_at: int = _harness.tick_count
	await _harness.until(func() -> bool: return ring.fired_rings() == 1, 120)
	assert_gte(_harness.tick_count - signed_at, 22)


func test_a_dead_or_halted_boss_fires_no_more_rings() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.boss_extra_pattern = true
	await _harness.ticks(2)
	var ring: RingRunner = _ring_runner(boss)
	boss._halt()
	assert_null(boss.extra_runner())
	await _harness.ticks(400)
	assert_eq(ring.fired_rings(), 0)
	assert_null(ring.current_sign())


func test_sixty_seconds_of_examen_final_and_pop_quiz_in_abandon_never_fill_the_bullet_pool() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.enemy_bullet_speed_mult = 1.1
	_harness.room.danger.telegraph_mult = 0.85
	_harness.room.danger.boss_extra_pattern = true
	boss.debug_set_hp_fraction(0.2)
	var manager: BulletManager = _harness.room.enemy_bullets()
	var peak: int = 0
	for i: int in 3600:
		await _harness.ticks(1)
		peak = maxi(peak, manager.active_count)
	assert_eq(manager.refused_count, 0, "peak %d of 512" % peak)
	assert_gte(_ring_runner(boss).fired_rings(), 8)
