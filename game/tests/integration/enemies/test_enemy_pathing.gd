extends GutTest
## Enemies that go around the obstacles (story 4.5, AC 1, 4, 5): a Sleepwalker and a Lullaby behind a wall reach the
## player's side, the path calculations stay bounded, a vanished target stops the chase.
## Room: a wall at frame column 25 (x from 400 to 416 px) with openings at y 80-112 and y 224-256; the player on its
## left at (200, 168).

const ROOM: String = "res://tests/fixtures/rooms/nav_wall.tscn"
const FURNITURE_ROOM: String = "res://tests/fixtures/rooms/furniture_room.tscn"
const SLEEPWALKER: EnemyDef = preload("res://data/enemies/sleepwalker.tres")
const LULLABY: EnemyDef = preload("res://data/enemies/lullaby.tres")
const PLAYER_POSITION: Vector2 = Vector2(200.0, 168.0)
const WALL_LEFT_EDGE_X: float = 400.0
## Generous bound: the way around is about 300 px at 40 px per second (7.5 s = 450 ticks).
const WALK_TICKS: int = 900

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func _start(room_path: String) -> void:
	_harness.start(room_path)
	_harness.player.global_position = PLAYER_POSITION
	await _harness.ticks(2)


func test_the_room_grid_holds_walls_pits_and_doors() -> void:
	await _start(ROOM)
	var nav: RoomNav = _harness.room.nav()
	assert_not_null(nav)
	assert_eq(nav.size_cells(), Vector2i(38, 21), "the whole frame, walls included")
	assert_true(nav.is_blocked(Vector2i(0, 0)), "the frame")
	assert_true(nav.is_blocked(Vector2i(25, 10)), "the central wall")
	assert_false(nav.is_blocked(Vector2i(25, 5)), "its opening")
	for door: Door in _harness.room.doors():
		for cell: Vector2i in door.cells():
			assert_true(nav.is_blocked(cell), "door cells are blocked")


func test_a_piece_of_furniture_blocks_its_cells_until_destroyed() -> void:
	await _start(FURNITURE_ROOM)
	var nav: RoomNav = _harness.room.nav()
	var bed: Furniture = _harness.room.furnitures()[0]
	var cell: Vector2i = nav.cell_of(_harness.room.to_local(bed.footprint_rect().get_center()))
	assert_true(nav.is_blocked(cell), "the bed blocks")
	bed._destroy()
	assert_false(nav.is_blocked(cell), "once destroyed it blocks nothing")


func test_a_sleepwalker_behind_the_wall_reaches_the_players_side() -> void:
	await _start(ROOM)
	var walker: Enemy = _harness.room.spawn_enemy(SLEEPWALKER, Vector2(450.0, 168.0))
	assert_not_null(walker)
	var crossed: bool = await _harness.until(func() -> bool: return walker.global_position.x < WALL_LEFT_EDGE_X - 8.0, WALK_TICKS)
	assert_true(crossed, "it went around the wall through an opening")


func test_a_lullaby_behind_the_wall_goes_around_it() -> void:
	await _start(ROOM)
	var lullaby: Enemy = _harness.room.spawn_enemy(LULLABY, Vector2(450.0, 168.0))
	assert_not_null(lullaby)
	var crossed: bool = await _harness.until(func() -> bool: return lullaby.global_position.x < WALL_LEFT_EDGE_X - 8.0, WALK_TICKS)
	assert_true(crossed, "it went around the wall through an opening")


func test_the_path_calculations_stay_bounded() -> void:
	await _start(ROOM)
	var enemy_count: int = 8
	for i: int in enemy_count:
		assert_not_null(_harness.room.spawn_enemy(SLEEPWALKER, Vector2(440.0 + 24.0 * (i % 4), 40.0 + 24.0 * (i / 4) * 4.0 + 18.0 * (i % 2))))
	var nav: RoomNav = _harness.room.nav()
	var start: int = nav.path_requests
	var worst_tick: int = 0
	var previous: int = start
	for i: int in 120:
		await _harness.ticks(1)
		worst_tick = maxi(worst_tick, nav.path_requests - previous)
		previous = nav.path_requests
	assert_lte(worst_tick, nav.max_paths_per_tick, "never more than the budget in a tick")
	var interval_ticks: float = Tuning.COMBAT.path_refresh_interval * Engine.physics_ticks_per_second
	var per_enemy: int = ceili(120.0 / interval_ticks) + 1
	assert_lte(nav.path_requests - start, enemy_count * per_enemy, "a recalculation per interval at most, not one per tick")
	assert_gt(nav.path_requests - start, 0, "and they do calculate")


func test_the_first_calculations_are_spread_over_the_interval() -> void:
	await _start(ROOM)
	var nav: RoomNav = _harness.room.nav()
	for i: int in 6:
		assert_not_null(_harness.room.spawn_enemy(SLEEPWALKER, Vector2(440.0, 40.0 + 24.0 * i)))
	var ticks_with_calculation: int = 0
	var previous: int = nav.path_requests
	for i: int in 60:
		await _harness.ticks(1)
		if nav.path_requests != previous:
			ticks_with_calculation += 1
		previous = nav.path_requests
	assert_gt(ticks_with_calculation, 1, "not every enemy calculates on the same tick")


func test_a_vanished_target_stops_the_chase() -> void:
	await _start(ROOM)
	var walker: Enemy = _harness.room.spawn_enemy(SLEEPWALKER, Vector2(450.0, 168.0))
	var decoy: Node2D = Node2D.new()
	decoy.position = PLAYER_POSITION
	add_child(decoy)
	walker._target = decoy
	await _harness.ticks(30)
	decoy.free()
	await _harness.ticks(2)
	var stopped_at: Vector2 = walker.global_position
	await _harness.ticks(60)
	assert_eq(walker.global_position, stopped_at, "no target, no movement")
