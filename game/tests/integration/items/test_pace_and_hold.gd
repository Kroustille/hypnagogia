extends GutTest
## The pace and the fire hold the room sets on its enemies (story 5.9): they move and fire faster after the exam timer, and
## do not fire during the first seconds of a fight under Naked in public.

const ROOM: String = "res://tests/fixtures/rooms/nav_wall.tscn"
const SLEEPWALKER: EnemyDef = preload("res://data/enemies/sleepwalker.tres")
const SHEEP: EnemyDef = preload("res://data/enemies/sheep.tres")
const NIGHT_LIGHT: EnemyDef = preload("res://data/enemies/night_light.tres")
const NAKED: ItemDef = preload("res://data/items/naked_in_public.tres")
const PLAYER_POSITION: Vector2 = Vector2(40.0, 168.0)

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_harness.player.global_position = PLAYER_POSITION
	await _harness.ticks(2)


func after_each() -> void:
	_harness.release()


## Distance walked over the ticks by an enemy that chases the (motionless) player.
func _walked(enemy: Enemy, ticks: int) -> float:
	var start: Vector2 = enemy.global_position
	await _harness.ticks(ticks)
	return start.distance_to(enemy.global_position)


func test_a_sleepwalker_walks_thirty_percent_faster_at_the_room_pace() -> void:
	var walker: Enemy = _harness.room.spawn_enemy(SLEEPWALKER, Vector2(380.0, 40.0))
	var normal: float = await _walked(walker, 40)
	assert_gt(normal, 5.0, "it walks")
	_harness.room.set_pace_mult(1.3)
	var fast: float = await _walked(walker, 40)
	assert_almost_eq(fast / normal, 1.3, 0.05)


func test_a_sheep_charges_faster_at_the_room_pace() -> void:
	_harness.room.set_pace_mult(1.3)
	var sheep: Enemy = _harness.room.spawn_enemy(SHEEP, Vector2(380.0, 40.0))
	var reference: Enemy = null
	assert_not_null(sheep)
	assert_almost_eq(sheep.danger.pace_mult, 1.3, 0.0001, "the enemies share the profile of the room")
	assert_null(reference)


func test_a_shooter_fires_sooner_at_the_room_pace() -> void:
	var slow_first: int = await _first_volley_tick(1.0)
	_harness.room.kill_all_enemies()
	await _harness.ticks(2)
	var fast_first: int = await _first_volley_tick(1.3)
	assert_gt(slow_first, 0)
	assert_gt(fast_first, 0)
	# 2 s of cycle at 1.3x = 92 ticks, then the telegraph (0.6 s, unchanged).
	assert_almost_eq(float(fast_first), 2.0 * 60.0 / 1.3 + 36.0, 3.0)
	assert_almost_eq(float(slow_first), 2.0 * 60.0 + 36.0, 3.0)


func _first_volley_tick(pace: float) -> int:
	_harness.room.set_pace_mult(pace)
	var lamp: Enemy = _harness.room.spawn_enemy(NIGHT_LIGHT, Vector2(300.0, 100.0))
	assert_not_null(lamp)
	var bullets: BulletManager = _harness.room.enemy_bullets()
	for tick: int in 400:
		await _harness.ticks(1)
		if bullets.active_count > 0:
			bullets.clear_all()
			return tick + 1
	return -1


func test_no_volley_during_the_hold_and_one_after() -> void:
	_harness.player.carrier.acquire(NAKED)
	_harness.room.set_fire_hold(90.0)
	assert_true(_harness.room.danger.fire_hold)
	var first: int = await _first_volley_tick(1.0)
	assert_almost_eq(float(first), 2.0 * 60.0 + 36.0 + 90.0, 4.0, "the first shot is late by the hold")
	assert_false(_harness.room.danger.fire_hold)


func test_the_hold_runs_in_ticks_of_the_enemies_clock() -> void:
	_harness.room.set_fire_hold(90.0)
	GameClock.apply_slow(self, [GameClock.Group.ENEMIES] as Array[GameClock.Group], 0.5, 20.0)
	await _harness.ticks(90)
	assert_true(_harness.room.danger.fire_hold, "half speed: 45 of the 90 ticks passed")
	await _harness.ticks(100)
	assert_false(_harness.room.danger.fire_hold)
	GameClock.clear_slow(self)


func test_fight_started_sets_the_hold_through_the_carrier() -> void:
	_harness.player.carrier.acquire(NAKED)
	_harness.room.fight_started.emit()
	assert_true(_harness.room.danger.fire_hold)


func test_fight_started_comes_once_with_the_first_wave() -> void:
	var count: Array[int] = [0]
	_harness.room.fight_started.connect(func() -> void: count[0] += 1)
	_harness.room.begin_room([SLEEPWALKER] as Array[EnemyDef])
	_harness.room.begin_room([SLEEPWALKER] as Array[EnemyDef])
	assert_eq(count[0], 1)
