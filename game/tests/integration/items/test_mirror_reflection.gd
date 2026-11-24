extends GutTest
## The Mirror and its hostile reflection (story 5.10): the rear shot, the draw, the reflection's build, shots and telegraph,
## the room that does not clear while it lives.

const MIRROR: ItemDef = preload("res://data/items/mirror.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const COMBAT_ROOM: String = "res://rooms/pool/onset/onset_combat_001.tscn"
const WAVE_TICKS: int = 400
const DRAWN_ROOMS: int = 400

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func _spawn_reflection() -> Reflection:
	return _harness.room.spawn_reflection() as Reflection


func _draws(seed_value: int, rooms: int) -> Array[bool]:
	var spawner: ReflectionSpawner = ReflectionSpawner.new(_harness.room, _harness.player, RunRng.new(seed_value), 0)
	var found: Array[bool] = []
	for i: int in rooms:
		found.append(spawner.draw())
	return found


func test_a_player_shot_with_the_mirror_makes_two_bullets_and_without_it_one() -> void:
	_harness.start(COMBAT_ROOM)
	var manager: BulletManager = _harness.room.player_bullets()
	var before: int = manager.active_count
	_harness.player._fire()
	assert_eq(manager.active_count - before, 1, "one bullet without the Mirror")
	_harness.player.carrier.acquire(MIRROR)
	before = manager.active_count
	_harness.player._fire()
	assert_eq(manager.active_count - before, 2, "front and rear with the Mirror")


func test_the_draw_hits_about_one_room_in_four_and_is_the_same_for_the_same_seed() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(MIRROR)
	var first: Array[bool] = _draws(1234, DRAWN_ROOMS)
	var hits: int = first.count(true)
	assert_between(hits, 70, 130, "about 100 reflections in 400 rooms")
	assert_eq(_draws(1234, DRAWN_ROOMS), first, "same seed, same rooms")
	assert_ne(_draws(99, DRAWN_ROOMS), first, "another seed, other rooms")


func test_one_combat_draw_per_eligible_room_whatever_the_result() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(MIRROR)
	var spawner: ReflectionSpawner = ReflectionSpawner.new(_harness.room, _harness.player, RunRng.new(7), 0)
	var reference: RandomNumberGenerator = RunRng.new(7).stream(RunRng.COMBAT, 0)
	for i: int in 20:
		assert_eq(spawner.draw(), reference.randi_range(0, 3) == 0, "draw %d is the next number of the stream" % i)


func test_no_draw_in_a_nightmare_a_cleared_room_or_without_the_mirror() -> void:
	_harness.start(COMBAT_ROOM)
	var spawner: ReflectionSpawner = ReflectionSpawner.new(_harness.room, _harness.player, RunRng.new(7), 0)
	assert_eq(_draws(7, 40).count(true), 0, "no Mirror, no reflection")
	_harness.player.carrier.acquire(MIRROR)
	_harness.room.room_type = Room.RoomType.NIGHTMARE
	assert_eq(_draws(7, 200).count(true), 0, "never in a nightmare")
	_harness.room.room_type = Room.RoomType.TREASURE
	assert_eq(_draws(7, 200).count(true), 0, "never in a treasure room")
	_harness.room.room_type = Room.RoomType.COMBAT
	_harness.room.end_room()
	assert_eq(_draws(7, 200).count(true), 0, "never in a cleared room")
	assert_false(spawner.is_eligible())


func test_the_reflection_wears_the_build_with_the_floor_factor_and_a_hostile_look() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(MIRROR)
	_harness.player.carrier.acquire(LEGS)
	var reflection: Reflection = _spawn_reflection()
	assert_not_null(reflection)
	assert_eq(reflection.hp.maximum, 60.0 * _harness.room.hp_factor())
	assert_eq(reflection.carrier.loadout.copies_of(&"mirror"), 1)
	assert_eq(reflection.stats.value_of(StatBlock.Stat.REAR_SHOT), 1.0)
	assert_almost_eq(reflection.stats.value_of(StatBlock.Stat.MOVE_SPEED), 2.0 * 0.8, 0.0001)
	assert_ne(reflection.carrier.loadout.items()[0], _harness.player.carrier.loadout.items()[0], "own copies")
	assert_eq(_harness.player.carrier.loadout.count(), 2, "the player keeps everything")
	assert_eq(_harness.room.alive_enemy_count(), 1, "the reflection is an enemy of the room")
	assert_gte(reflection.global_position.distance_to(_harness.player.global_position), Tuning.COMBAT.min_spawn_distance * Const.TILE_SIZE - 1.0)


func test_the_reflection_telegraphs_then_fires_front_and_rear_through_the_enemy_manager() -> void:
	_harness.start(COMBAT_ROOM)
	_harness.player.carrier.acquire(MIRROR)
	var reflection: Reflection = _spawn_reflection()
	var manager: BulletManager = _harness.room.enemy_bullets()
	var before: int = manager.active_count
	var saw_telegraph: float = 0.0
	for tick: int in 400:
		await _harness.ticks(1)
		if reflection.telegraph.is_active():
			saw_telegraph += 1.0
		if manager.active_count > before:
			break
	assert_gte(saw_telegraph / Engine.physics_ticks_per_second, Tuning.COMBAT.min_telegraph - 0.05, "aimed for at least the minimum")
	assert_eq(manager.active_count - before, 2, "front and rear shot of the Mirror")


func test_the_room_does_not_clear_while_the_reflection_lives() -> void:
	watch_signals(Events)
	_harness.start(COMBAT_ROOM)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.player.carrier.acquire(MIRROR) # after the draw of the fight start: only the one made here
	var reflection: Reflection = _spawn_reflection()
	assert_not_null(reflection)
	for enemy: Enemy in _harness.living_enemies():
		if enemy != reflection:
			enemy.kill()
	await _harness.ticks(WAVE_TICKS)
	assert_eq(_harness.living_enemies().size(), 1, "only the reflection is left, and the next wave waits for it")
	assert_eq(_harness.room.wave_runner().wave_number(), 1)
	assert_false(_harness.room.is_cleared(), "alive reflection: not cleared")
	var cleared: int = get_signal_emit_count(Events, "room_cleared")
	assert_eq(cleared, 0)
	reflection.kill()
	await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, WAVE_TICKS)
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.room.is_cleared(), WAVE_TICKS)
	assert_true(_harness.room.is_cleared())


func test_the_reflection_appears_inside_the_visible_area_of_a_wide_room() -> void:
	_harness.start("res://rooms/pool/onset/onset_combat_007.tscn")
	_harness.player.global_position = _harness.room.to_global(Vector2(80.0, 168.0)) # west entrance
	await _harness.ticks(3) # the camera follows
	var reflection: Reflection = _spawn_reflection()
	assert_not_null(reflection)
	var view: Rect2 = _harness.room.visible_rect_local()
	assert_true(view.has_point(_harness.room.to_local(reflection.global_position)), "inside the view, not at the far east")
