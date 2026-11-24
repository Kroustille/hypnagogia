extends GutTest
## The three trials of The Professor (story 6.2): thresholds, announces, alternation, the ruler, the bullet capacity.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const PROFESSOR: BossDef = preload("res://data/bosses/professor.tres")
const APPEAR_TICKS: int = 120
const ANNOUNCE_TICKS: int = 90

var _harness: RoomHarness
var _events: Array[String] = []
var _hits: Array[Vector2i] = []


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_events.clear()
	Events.boss_phase_changed.connect(_on_phase_changed)
	Events.boss_announced.connect(_on_announced)


func after_each() -> void:
	Events.boss_phase_changed.disconnect(_on_phase_changed)
	Events.boss_announced.disconnect(_on_announced)
	Input.action_release(&"move_left")
	Input.action_release(&"move_down")
	Input.action_release(&"dash")
	_harness.release()


func _on_phase_changed(_id: StringName, index: int) -> void:
	_events.append("phase:%d" % index)


func _on_announced(_id: StringName, key: StringName) -> void:
	_events.append("announce:%s" % key)


func _boss() -> Boss:
	for enemy: Enemy in _harness.living_enemies():
		if enemy is Boss:
			return enemy as Boss
	return null


## Starts the room and waits until the boss fights (its opening announce is over).
func _fighting_boss() -> Boss:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	await _harness.until(func() -> bool: return boss.is_fighting(), ANNOUNCE_TICKS + 30)
	return boss


func _has_runner(boss: Boss, runner_class: GDScript) -> bool:
	for runner: AttackRunner in boss.runners():
		if is_instance_of(runner, runner_class):
			return true
	return false


func _rulers() -> Array[Ruler]:
	var found: Array[Ruler] = []
	for child: Node in _harness.room.get_children():
		if child is Ruler and not child.is_queued_for_deletion():
			found.append(child as Ruler)
	return found


func test_crossing_the_thresholds_announces_each_phase_once_in_order() -> void:
	var boss: Boss = await _fighting_boss()
	_events.clear()
	boss.debug_set_hp_fraction(0.65)
	assert_eq(_events, ["phase:1", "announce:BOSS_PROFESSOR_PHASE_2"], "phase change, then the title")
	await _harness.ticks(ANNOUNCE_TICKS + 5)
	boss.debug_set_hp_fraction(0.60)
	assert_eq(_events.size(), 2, "no new announce inside the phase")
	boss.debug_set_hp_fraction(0.32)
	assert_eq(_events.slice(2), ["phase:2", "announce:BOSS_PROFESSOR_PHASE_3"])
	assert_eq(boss.current_phase_index(), 2)


func test_a_hit_that_jumps_two_thresholds_announces_only_the_phase_reached() -> void:
	var boss: Boss = await _fighting_boss()
	_events.clear()
	boss.debug_set_hp_fraction(0.2)
	assert_eq(_events, ["phase:2", "announce:BOSS_PROFESSOR_PHASE_3"])
	assert_eq(boss.current_phase_index(), 2)


func test_the_attacks_wait_for_the_title_and_the_chalks_in_flight_go_on() -> void:
	var boss: Boss = await _fighting_boss()
	var manager: BulletManager = _harness.room.enemy_bullets()
	await _harness.until(func() -> bool: return manager.active_count > 0, 200)
	boss.debug_set_hp_fraction(0.6)
	assert_true(boss.runners().is_empty(), "the Dictée stopped, nothing new yet")
	assert_gt(manager.active_count, 0, "the chalks already fired are still there")
	await _harness.ticks(ANNOUNCE_TICKS - 5)
	assert_true(boss.runners().is_empty(), "still writing the title")
	await _harness.until(func() -> bool: return not boss.runners().is_empty(), 20)
	assert_true(_has_runner(boss, SpiralRunner))
	assert_true(_has_runner(boss, AimedRunner))
	assert_false(_has_runner(boss, RowRunner))


func test_the_spiral_signs_then_fires_four_arms_twelve_degrees_apart() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.6)
	await _harness.until(func() -> bool: return _has_runner(boss, SpiralRunner), ANNOUNCE_TICKS + 10)
	var spiral: SpiralRunner = null
	for runner: AttackRunner in boss.runners():
		if runner is SpiralRunner:
			spiral = runner as SpiralRunner
	await _harness.ticks(2)
	assert_not_null(spiral.current_sign(), "the start is announced")
	assert_eq(spiral.current_sign().shape(), AttackSign.Shape.RING)
	assert_eq(spiral.emissions(), 0)
	var manager: BulletManager = _harness.room.enemy_bullets()
	var before: int = manager.active_count
	await _harness.until(func() -> bool: return spiral.emissions() >= 1, 60)
	assert_between(spiral.emissions(), 1, 1)
	assert_between(manager.active_count - before, 4, 4, "four arms")
	assert_almost_eq(spiral.angle(), 12.0, 1e-3, "starts at 0, turns 12 degrees per emission")
	await _harness.ticks(12)
	assert_eq(spiral.emissions(), 2, "one emission every 0.2 s")


func test_the_fan_is_aimed_where_the_player_is_when_it_fires() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.6)
	await _harness.until(func() -> bool: return _has_runner(boss, AimedRunner), ANNOUNCE_TICKS + 10)
	var aimed: AimedRunner = null
	for runner: AttackRunner in boss.runners():
		if runner is AimedRunner:
			aimed = runner as AimedRunner
	await _harness.ticks(2)
	assert_not_null(aimed.current_sign())
	assert_eq(aimed.current_sign().shape(), AttackSign.Shape.LINE_ARROW)
	assert_eq(aimed.fired_fans(), 0)
	await _harness.until(func() -> bool: return aimed.fired_fans() == 1, 60)
	assert_eq(aimed.fired_fans(), 1)
	assert_null(aimed.current_sign())


func test_the_examen_final_alternates_dictee_and_calcul_mental_every_eight_seconds() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.2)
	await _harness.until(func() -> bool: return not boss.runners().is_empty(), ANNOUNCE_TICKS + 10)
	var started: int = _harness.tick_count
	assert_true(_has_runner(boss, RowRunner), "starts with the Dictée")
	assert_false(_has_runner(boss, SpiralRunner))
	assert_true(_has_runner(boss, RulerRunner), "the ruler runs the whole phase")
	await _harness.until(func() -> bool: return _has_runner(boss, SpiralRunner), 600)
	assert_between(_harness.tick_count - started, 477, 483, "8 s")
	assert_false(_has_runner(boss, RowRunner))
	assert_true(_has_runner(boss, AimedRunner))
	assert_true(_has_runner(boss, RulerRunner))
	await _harness.until(func() -> bool: return _has_runner(boss, RowRunner), 600)
	assert_between(_harness.tick_count - started, 957, 963, "16 s")
	assert_false(_has_runner(boss, SpiralRunner))


func test_no_ruler_before_the_examen_final() -> void:
	var boss: Boss = await _fighting_boss()
	await _harness.ticks(600)
	assert_false(_has_runner(boss, RulerRunner))
	boss.debug_set_hp_fraction(0.5)
	await _harness.ticks(ANNOUNCE_TICKS + 600)
	assert_false(_has_runner(boss, RulerRunner))
	assert_eq(_rulers().size(), 0)


func test_the_ruler_is_announced_at_least_0_4_seconds_before_it_can_hit() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.telegraph_mult = 0.1 # the floor takes over
	boss.debug_set_hp_fraction(0.2)
	await _harness.until(func() -> bool: return _has_runner(boss, RulerRunner), ANNOUNCE_TICKS + 10)
	var runner: RulerRunner = null
	for r: AttackRunner in boss.runners():
		if r is RulerRunner:
			runner = r as RulerRunner
	await _harness.until(func() -> bool: return not runner.current_signs().is_empty(), 600)
	var signed_at: int = _harness.tick_count
	var signs: Array[AttackSign] = runner.current_signs()
	assert_eq(signs[0].shape(), AttackSign.Shape.BAND, "the start rectangle")
	assert_eq(signs[1].shape(), AttackSign.Shape.LINE_ARROW, "and the way")
	var arena: Rect2 = boss.arena_px()
	assert_eq(signs[0].band().size.y, arena.size.y, "the whole height")
	assert_eq(signs[0].band().size.x, (PROFESSOR.phases[2].extras[0] as BossAttack).thickness_tiles * Const.TILE_SIZE, "the thickness of the data")
	await _harness.until(func() -> bool: return runner.current_ruler() != null, 100)
	assert_gte(_harness.tick_count - signed_at, 24, "never under 0.4 s")
	assert_eq(_rulers().size(), 1)


func test_the_ruler_sweeps_the_room_then_is_freed() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.2)
	await _harness.until(func() -> bool: return _has_runner(boss, RulerRunner), ANNOUNCE_TICKS + 10)
	await _harness.until(func() -> bool: return not _rulers().is_empty(), 600)
	var ruler: Ruler = _rulers()[0]
	var x0: float = ruler.position.x
	await _harness.ticks(60)
	assert_almost_eq(absf(ruler.position.x - x0), (PROFESSOR.phases[2].extras[0] as BossAttack).sweep_speed * Const.TILE_SIZE, 2.0, "the sweep speed of the data per second")
	await _harness.until(func() -> bool: return _rulers().is_empty(), 400)
	assert_true(_rulers().is_empty(), "freed at the opposite edge")


func test_a_phase_change_stops_the_pending_ruler_and_the_death_of_the_boss_too() -> void:
	var boss: Boss = await _fighting_boss()
	boss.debug_set_hp_fraction(0.2)
	await _harness.until(func() -> bool: return not _rulers().is_empty(), ANNOUNCE_TICKS + 600)
	boss._halt()
	await _harness.ticks(2)
	assert_true(_rulers().is_empty(), "stopped with the boss")


func _release_ruler(boss: Boss, left_to_right: bool) -> Ruler:
	boss._halt() # no chalk in the way of this check
	var ruler: Ruler = Ruler.new()
	var data: BossAttack = PROFESSOR.phases[2].extras[0]
	ruler.launch(boss, boss.arena_px(), left_to_right, data.thickness_tiles, data.sweep_speed)
	return ruler


func _on_player_hit(damage: int, source: int) -> void:
	_hits.append(Vector2i(damage, source))


func test_the_ruler_costs_one_heart_when_the_player_stands_in_its_way() -> void:
	var boss: Boss = await _fighting_boss()
	_hits.clear()
	Events.player_hit.connect(_on_player_hit)
	_harness.player.health.set_forced_invulnerability(false)
	var arena: Rect2 = boss.arena_px()
	_harness.player.global_position = _harness.room.to_global(Vector2(arena.position.x + 12.0 * Const.TILE_SIZE, arena.position.y + 3.0 * Const.TILE_SIZE))
	_harness.player.velocity = Vector2.ZERO
	_release_ruler(boss, true)
	await _harness.ticks(200)
	Events.player_hit.disconnect(_on_player_hit)
	assert_eq(_hits.size(), 1, "once per pass")
	assert_eq(_hits[0], Vector2i(2, DamageInfo.Source.RULER), "one heart, source RULER")


func test_a_dash_through_the_ruler_cancels_the_hit() -> void:
	var boss: Boss = await _fighting_boss()
	_hits.clear()
	Events.player_hit.connect(_on_player_hit)
	_harness.player.health.set_forced_invulnerability(false)
	var arena: Rect2 = boss.arena_px()
	var player_x: float = arena.position.x + 14.0 * Const.TILE_SIZE
	_harness.player.global_position = _harness.room.to_global(Vector2(player_x, arena.position.y + 3.0 * Const.TILE_SIZE))
	_harness.player.velocity = Vector2.ZERO
	var ruler: Ruler = _release_ruler(boss, true)
	# The bar comes from the left: dash toward it when it is two tiles away.
	await _harness.until(func() -> bool: return player_x - ruler.position.x <= 2.0 * Const.TILE_SIZE, 300)
	Input.action_press(&"move_left")
	await _harness.ticks(1)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_left")
	Input.action_release(&"move_down")
	await _harness.until(func() -> bool: return _rulers().is_empty(), 400)
	Events.player_hit.disconnect(_on_player_hit)
	assert_eq(_hits.size(), 0, "the i-frames of the dash cancel the heavy hit")


func test_a_dash_in_place_through_the_ruler_cancels_the_hit() -> void:
	var boss: Boss = await _fighting_boss()
	_hits.clear()
	Events.player_hit.connect(_on_player_hit)
	_harness.player.health.set_forced_invulnerability(false)
	var arena: Rect2 = boss.arena_px()
	var player_x: float = arena.position.x + 8.0 * Const.TILE_SIZE
	_harness.player.global_position = _harness.room.to_global(Vector2(player_x, arena.position.y + 4.0 * Const.TILE_SIZE))
	_harness.player.velocity = Vector2.ZERO
	var data: BossAttack = PROFESSOR.phases[2].extras[0]
	_release_ruler(boss, true)
	var contact: int = ceili((8.0 * Const.TILE_SIZE - 3.0) / (data.sweep_speed * Const.TILE_SIZE / 60.0)) # 3 px: half the body
	await _harness.ticks(contact - 3)
	Input.action_press(&"move_down") # a dash across the bar: the player stays in its path
	Input.action_press(&"dash")
	await _harness.ticks(1)
	Input.action_release(&"dash")
	await _harness.ticks(11)
	Input.action_release(&"move_down")
	await _harness.ticks(40)
	Events.player_hit.disconnect(_on_player_hit)
	assert_eq(_hits.size(), 0, "the i-frames of an in-place dash outlast the pass of the bar")


func test_sixty_seconds_of_examen_final_in_abandon_never_fill_the_bullet_pool() -> void:
	var boss: Boss = await _fighting_boss()
	_harness.room.danger.enemy_bullet_speed_mult = 1.1
	_harness.room.danger.telegraph_mult = 0.85
	boss.debug_set_hp_fraction(0.2)
	var manager: BulletManager = _harness.room.enemy_bullets()
	var peak: int = 0
	for i: int in 3600:
		await _harness.ticks(1)
		peak = maxi(peak, manager.active_count)
	assert_eq(manager.refused_count, 0, "peak %d of 512" % peak)
	assert_gt(peak, 0)
