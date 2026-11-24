extends GutTest
## The nightmare room and the Dictée of The Professor (story 6.1): spawn, announce, rows, telegraph, danger, no reinforcement.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const APPEAR_TICKS: int = 120
const ANNOUNCE_TICKS: int = 90
const ROW_MIN_CHALKS: int = 10

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func _boss() -> Boss:
	for enemy: Enemy in _harness.living_enemies():
		if enemy is Boss:
			return enemy as Boss
	return null


func _start_and_wait_for_the_boss() -> Boss:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	return _boss()


## Ticks, from now, at which a row appears (the bullet count jumps).
func _row_ticks(count: int, max_ticks: int) -> Array[int]:
	var manager: BulletManager = _harness.room.enemy_bullets()
	var found: Array[int] = []
	var previous: int = manager.active_count
	for i: int in max_ticks:
		await _harness.ticks(1)
		if manager.active_count - previous >= ROW_MIN_CHALKS:
			found.append(_harness.tick_count)
			if found.size() >= count:
				break
		previous = manager.active_count
	return found


func test_the_room_loads_and_the_boss_appears_at_the_center() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	assert_not_null(boss)
	assert_eq(_harness.living_enemies().size(), 1, "the boss alone")
	var center: Vector2 = Vector2(19.5, 10.5) * Const.TILE_SIZE
	assert_lt(_harness.room.to_local(boss.global_position).distance_to(center), 3.0 * Const.TILE_SIZE, "at the center, or the 3 tiles that keep it off the player standing there")
	assert_eq(boss.hp.maximum, 2500.0)
	assert_true(_harness.room.is_nightmare())


func test_the_dictee_is_announced_before_the_first_chalk() -> void:
	watch_signals(Events)
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var spawned_at: int = _harness.tick_count
	assert_signal_emitted_with_parameters(Events, "boss_announced", [&"professor", &"BOSS_PROFESSOR_PHASE_1"])
	assert_signal_emitted_with_parameters(Events, "boss_engaged", [&"professor", &"BOSS_PROFESSOR_NAME", 2500.0])
	assert_eq(_harness.room.enemy_bullets().active_count, 0)
	var rows: Array[int] = await _row_ticks(1, 300)
	assert_eq(rows.size(), 1)
	var expected: int = ANNOUNCE_TICKS + 30 # announce, then the 0.5 s sign
	assert_between(rows[0] - spawned_at, expected - 3, expected + 3, "first row at announce + telegraph")


func test_rows_come_every_two_seconds() -> void:
	await _start_and_wait_for_the_boss()
	var rows: Array[int] = await _row_ticks(3, 600)
	assert_eq(rows.size(), 3)
	assert_between(rows[1] - rows[0], 119, 121)
	assert_between(rows[2] - rows[1], 119, 121)


func test_a_row_is_chalks_with_a_gap_inside_the_visible_room_and_in_the_reserved_look() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	var rows: Array[int] = await _row_ticks(1, 300)
	assert_eq(rows.size(), 1)
	var manager: BulletManager = _harness.room.enemy_bullets()
	assert_between(manager.active_count, 38, 46, "a row of about 42 chalks")
	assert_eq(manager.refused_count, 0)
	var runner: RowRunner = boss.runners()[0] as RowRunner
	var arena: Rect2 = boss.arena_px()
	var gap_center_px: float = arena.position.x + runner.last_gap * Const.TILE_SIZE
	var half_gap_px: float = 2.5 * Const.TILE_SIZE
	var view: Rect2 = _harness.room.visible_rect_local()
	for position: Vector2 in _active(manager):
		var local: Vector2 = _harness.room.to_local(manager.to_global(position))
		assert_true(view.has_point(local), "inside the visible room: %s" % local)
		assert_gte(absf(local.x - gap_center_px), half_gap_px, "no chalk in the gap")
	for i: int in manager._high_water:
		if manager._flags[i] & BulletManager.FLAG_ACTIVE:
			assert_eq(manager._appearance_textures[manager._appearances[i]], EnemyBulletLook.texture(), "the reserved enemy look")
			assert_eq(manager._damages[i], float(Tuning.COMBAT.hit_damage_half_hearts), "half a heart")


func test_a_row_hits_a_player_pressed_against_the_north_wall() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	await _row_ticks(1, 300)
	var runner: RowRunner = boss.runners()[0] as RowRunner
	var arena: Rect2 = boss.arena_px()
	var gap_center_px: float = arena.position.x + runner.last_gap * Const.TILE_SIZE
	var body: float = 0.375 * Const.TILE_SIZE
	var side: float = -1.0 if gap_center_px > arena.get_center().x else 1.0
	var player_x: float = gap_center_px + side * (2.5 * Const.TILE_SIZE + 4.0 * Const.TILE_SIZE) # well outside the gap
	var hurtbox: Rect2 = Rect2(Vector2(player_x - body, arena.position.y), Vector2(body * 2.0, body * 2.0)) # flush against the wall
	var radius_px: float = Tuning.COMBAT.enemy_bullet_radius * Const.TILE_SIZE
	var manager: BulletManager = _harness.room.enemy_bullets()
	var hits: int = 0
	for position: Vector2 in _active(manager):
		var local: Vector2 = _harness.room.to_local(manager.to_global(position))
		var nearest: Vector2 = Vector2(clampf(local.x, hurtbox.position.x, hurtbox.end.x), clampf(local.y, hurtbox.position.y, hurtbox.end.y))
		if nearest.distance_to(local) < radius_px:
			hits += 1
	assert_gt(hits, 0, "a chalk overlaps a hurtbox flush against the north wall")


func test_the_chalks_fall_at_five_tiles_per_second() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	await _row_ticks(1, 300)
	var manager: BulletManager = _harness.room.enemy_bullets()
	var first: PackedVector2Array = _active(manager)
	await _harness.ticks(60)
	var second: PackedVector2Array = _active(manager)
	assert_gt(first.size(), 0)
	var moved: float = second[0].y - first[0].y
	assert_almost_eq(moved, 5.0 * Const.TILE_SIZE, 2.0)
	assert_not_null(boss)


func test_the_sign_lasts_at_least_the_minimum_telegraph_even_with_a_short_telegraph_mult() -> void:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	_harness.room.danger.telegraph_mult = 0.4 # 0.5 s x 0.4 = 0.2 s: the floor takes over
	var boss: Boss = _boss()
	var runner: RowRunner = null
	await _harness.until(func() -> bool: return boss.is_fighting() and not boss.runners().is_empty(), 200)
	runner = boss.runners()[0] as RowRunner
	await _harness.until(func() -> bool: return runner.current_sign() != null, 60)
	var ticks_shown: int = 0
	while runner.current_sign() != null and ticks_shown < 200:
		ticks_shown += 1
		await _harness.ticks(1)
	assert_gte(ticks_shown, int(Tuning.COMBAT.min_telegraph * 60.0) - 1)
	assert_lte(ticks_shown, int(Tuning.COMBAT.min_telegraph * 60.0) + 2)


func test_a_slow_telegraph_mult_lengthens_the_sign() -> void:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	_harness.room.danger.telegraph_mult = 1.5 # 0.75 s
	var boss: Boss = _boss()
	await _harness.until(func() -> bool: return boss.is_fighting() and not boss.runners().is_empty(), 200)
	var runner: RowRunner = boss.runners()[0] as RowRunner
	await _harness.until(func() -> bool: return runner.current_sign() != null, 60)
	var ticks_shown: int = 0
	while runner.current_sign() != null and ticks_shown < 200:
		ticks_shown += 1
		await _harness.ticks(1)
	assert_between(ticks_shown, 44, 47)


func test_the_danger_speeds_the_chalks_and_the_pace_quickens_the_cadence() -> void:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	_harness.room.danger.enemy_bullet_speed_mult = 1.4
	_harness.room.set_pace_mult(1.25)
	var rows: Array[int] = await _row_ticks(2, 600)
	assert_eq(rows.size(), 2)
	assert_between(rows[1] - rows[0], 95, 97, "2 s / 1.25 = 1.6 s")
	var manager: BulletManager = _harness.room.enemy_bullets()
	var first: PackedVector2Array = _active(manager)
	await _harness.ticks(30)
	var second: PackedVector2Array = _active(manager)
	assert_almost_eq(second[0].y - first[0].y, 5.0 * 1.4 * Const.TILE_SIZE * 0.5, 2.0)


func test_a_fire_hold_freezes_the_boss_completely() -> void:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	await _harness.until(func() -> bool: return boss.is_fighting(), 200)
	_harness.room.set_fire_hold(600.0)
	await _harness.ticks(300)
	assert_eq(_harness.room.enemy_bullets().active_count, 0, "nothing fires under the hold")
	var runner: RowRunner = boss.runners()[0] as RowRunner
	assert_eq(runner.fired_rows(), 0)


func test_no_reinforcement_and_no_reflection_even_at_the_lowest_lucidity() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	_harness.player.lucidity.set_value(0)
	await _harness.ticks(30)
	_harness.room.danger.reinforcement = true
	_harness.room._maybe_schedule_reinforcement()
	assert_eq(_harness.room.pending_reinforcement_count(), 0)
	assert_false(_harness.room.reflection_spawner().is_eligible())
	await _harness.ticks(300)
	assert_eq(_harness.living_enemies().size(), 1, "still the boss alone")
	assert_not_null(boss)


func test_the_health_bar_events_follow_the_hits() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	watch_signals(Events)
	boss.debug_set_hp_fraction(0.5)
	assert_signal_emitted_with_parameters(Events, "boss_health_changed", [1250.0, 2500.0])


func test_a_player_hit_updates_the_bar_and_a_kill_empties_it() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	watch_signals(Events)
	boss._on_hurtbox_damage_received(DamageInfo.from_bullet(250.0, Vector2.DOWN, DamageInfo.Source.PLAYER_SHOT))
	assert_signal_emitted_with_parameters(Events, "boss_health_changed", [2250.0, 2500.0])
	assert_eq(boss.hp.current, 2250.0)
	boss.kill()
	assert_true(boss.is_dead())
	assert_signal_emitted_with_parameters(Events, "boss_health_changed", [0.0, 2500.0])
	await _harness.until(func() -> bool: return _harness.room.is_cleared(), 120)
	assert_true(_harness.room.is_cleared(), "the room opens when the boss leaves")


func test_the_boss_refuses_dazzle_and_knock_back() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	var before: Vector2 = boss.global_position
	boss.dazzle(5.0)
	assert_false(boss.is_dazzled())
	assert_eq(boss.knock_back(Vector2.RIGHT, 50.0), 0.0)
	assert_eq(boss.global_position, before)


func test_the_player_death_stops_every_chalk() -> void:
	var boss: Boss = await _start_and_wait_for_the_boss()
	var rows: Array[int] = await _row_ticks(1, 300)
	assert_eq(rows.size(), 1)
	var fired: int = (boss.runners()[0] as RowRunner).fired_rows()
	Events.run_ended.emit(0)
	await _harness.ticks(400)
	assert_eq(boss.runners().size(), 0)
	assert_eq(fired, 1)
	var manager: BulletManager = _harness.room.enemy_bullets()
	assert_eq(manager.active_count, 0, "the first row is gone, nothing came after it")


func test_the_same_seed_gives_the_same_gaps_in_two_rooms() -> void:
	var first: Array[float] = await _gaps_of_a_room(1234, 4)
	var second: Array[float] = await _gaps_of_a_room(1234, 4)
	assert_eq(first.size(), 4)
	assert_eq(second, first)


func _gaps_of_a_room(seed_value: int, rows_wanted: int) -> Array[float]:
	_harness.release()
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(BOSS_ROOM, seed_value)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	var found: Array[float] = []
	var runner: RowRunner
	while found.size() < rows_wanted:
		await _harness.ticks(1)
		if runner == null and not boss.runners().is_empty():
			runner = boss.runners()[0] as RowRunner
		if runner != null and runner.fired_rows() > found.size():
			found.append(runner.last_gap)
	return found


## Positions (the manager's space) of the live bullets.
func _active(manager: BulletManager) -> PackedVector2Array:
	var found: PackedVector2Array = PackedVector2Array()
	for i: int in manager._high_water:
		if manager._flags[i] & BulletManager.FLAG_ACTIVE:
			found.append(manager._positions[i])
	return found
