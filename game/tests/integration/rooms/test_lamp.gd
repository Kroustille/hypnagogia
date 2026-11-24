extends GutTest
## The lamp (story 4.4, AC 5 to 7): a shot of the player sets it off once, dazzling the living enemies within 3 tiles
## for 1 s; enemy shots pass through it. Played in the furniture start room (lamp at tile (18, 4)).

const ROOM: String = "res://tests/fixtures/rooms/furniture_room.tscn"
const NIGHT_LIGHT: String = "res://data/enemies/night_light.tres"
const SLEEPWALKER: String = "res://data/enemies/sleepwalker.tres"
const SHEEP: String = "res://data/enemies/sheep.tres"
const LULLABY: String = "res://data/enemies/lullaby.tres"

var _harness: RoomHarness
var _lamp: Trigger


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_lamp = _harness.room.triggers()[0]
	await _harness.ticks(2)


func after_each() -> void:
	_harness.release()


func _def(path: String) -> EnemyDef:
	return load(path) as EnemyDef


## Spawns an enemy at an offset in pixels from the lamp.
func _spawn(path: String, offset: Vector2) -> Enemy:
	var enemy: Enemy = _harness.room.spawn_enemy(_def(path), _harness.room.to_local(_lamp.global_position + offset))
	assert_not_null(enemy, "spawned %s" % path)
	return enemy


## A shot that reaches the lamp within a tick or two, from just to its left.
func _shoot_lamp(manager: BulletManager) -> void:
	assert_true(_harness.fire_shot(manager, _harness.room.to_local(_lamp.global_position) + Vector2(-12, 0), Vector2.RIGHT), "shot at the lamp")


func test_the_lamp_has_the_tuned_radius_and_duration() -> void:
	assert_eq(Tuning.ROOM.lamp_radius_tiles, 3.0)
	assert_eq(Tuning.ROOM.lamp_dazzle_duration, 1.0)


func test_only_enemies_within_three_tiles_center_to_center_are_dazzled() -> void:
	var tile: float = Const.TILE_SIZE
	var inside: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.9 * tile, 0))
	var edge: Enemy = _spawn(NIGHT_LIGHT, Vector2(0, 3.0 * tile))
	var outside: Enemy = _spawn(NIGHT_LIGHT, Vector2(-3.1 * tile, 0))
	watch_signals(_lamp)
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.ticks(4)
	assert_true(_lamp.is_spent())
	assert_true(inside.is_dazzled(), "2.9 tiles")
	assert_true(edge.is_dazzled(), "exactly 3 tiles")
	assert_false(outside.is_dazzled(), "3.1 tiles")
	assert_signal_emit_count(_lamp, "triggered", 1)
	assert_eq(_harness.room.player_bullets().active_count, 0, "the shot is consumed")


func test_the_dazzle_lasts_one_second_of_ticks() -> void:
	var enemy: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.0 * Const.TILE_SIZE, 0))
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	var ticks: int = 0
	while enemy.is_dazzled() and ticks < 200:
		await _harness.ticks(1)
		ticks += 1
	assert_eq(ticks, 60, "1 s at 60 ticks per second")


func test_the_lamp_goes_off_for_good_after_one_shot() -> void:
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.ticks(4)
	assert_true(_lamp.is_spent())
	var late: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.0 * Const.TILE_SIZE, 0))
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.ticks(4)
	assert_false(late.is_dazzled(), "a second shot sets nothing off")
	assert_false(_lamp.hurtbox.is_hittable(), "the shot passes through a spent lamp")
	assert_eq(_harness.room.player_bullets().active_count, 1, "and keeps flying")


func test_an_enemy_shot_goes_through_the_lamp() -> void:
	var enemy: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.0 * Const.TILE_SIZE, 0))
	_shoot_lamp(_harness.room.enemy_bullets())
	await _harness.ticks(4)
	assert_false(_lamp.is_spent())
	assert_false(enemy.is_dazzled())
	assert_eq(_harness.room.enemy_bullets().active_count, 1, "the enemy shot is still flying")


func test_a_running_telegraph_is_cancelled_and_the_attack_does_not_come() -> void:
	var enemy: Enemy = _spawn(SLEEPWALKER, Vector2(-5.0 * Const.TILE_SIZE, 0))
	# It telegraphs its rush once the player is within 2 tiles: the player stands next to it, out of the lamp's reach.
	_harness.player.global_position = enemy.global_position + Vector2(0, 1.5 * Const.TILE_SIZE)
	var announced: bool = await _harness.until(func() -> bool: return enemy.telegraph.is_active(), 30)
	assert_true(announced, "it announced its rush")
	_harness.player.global_position = enemy.global_position + Vector2(0, 8.0 * Const.TILE_SIZE) # out of the way
	_lamp.global_position = enemy.global_position + Vector2(Const.TILE_SIZE, 0) # the lamp stands next to it
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	assert_true(enemy.is_dazzled())
	assert_false(enemy.telegraph.is_active(), "the announcement is cancelled")
	var frozen_at: Vector2 = enemy.global_position
	await _harness.ticks(59)
	assert_true(enemy.is_dazzled() or enemy.global_position == frozen_at, "still stuck near the end")
	assert_eq(enemy.global_position, frozen_at, "no rush, no step during the dazzle")
	await _harness.ticks(3)
	assert_false(enemy.is_dazzled())
	assert_false(enemy.telegraph.is_active(), "no attack came out of the cancelled announcement")


func test_a_dazzled_shooter_does_not_fire_and_its_telegraph_is_cancelled() -> void:
	var enemy: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.0 * Const.TILE_SIZE, 0))
	var interval: float = (_def(NIGHT_LIGHT) as ShooterDef).fire_interval
	# Let the cycle run until its telegraph begins.
	var announced: bool = await _harness.until(func() -> bool: return enemy.telegraph.is_active(), int(interval * 60.0) + 60)
	assert_true(announced, "the lamp announced a volley")
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	assert_false(enemy.telegraph.is_active(), "cancelled")
	await _harness.ticks(60)
	assert_eq(_harness.room.enemy_bullets().active_count, 0, "no volley left the lamp-struck enemy")


func test_every_kind_is_frozen_while_dazzled() -> void:
	var tile: float = Const.TILE_SIZE
	var walker: Enemy = _spawn(SLEEPWALKER, Vector2(2.0 * tile, 0))
	var sheep: Enemy = _spawn(SHEEP, Vector2(-2.0 * tile, 0))
	var lullaby: Enemy = _spawn(LULLABY, Vector2(0, 2.0 * tile))
	var enemies: Array[Enemy] = [walker, sheep, lullaby]
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	var positions: Array[Vector2] = []
	for enemy: Enemy in enemies:
		assert_true(enemy.is_dazzled())
		positions.append(enemy.global_position)
	await _harness.ticks(30)
	for i: int in enemies.size():
		assert_eq(enemies[i].global_position, positions[i], "%s did not move" % enemies[i].name)


func test_the_contact_of_a_dazzled_enemy_still_hurts() -> void:
	_harness.player.health.set_forced_invulnerability(false)
	var enemy: Enemy = _spawn(SLEEPWALKER, Vector2(-5.0 * Const.TILE_SIZE, 0))
	_lamp.global_position = enemy.global_position + Vector2(Const.TILE_SIZE, 0)
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	assert_true(enemy.is_dazzled())
	var hearts_before: int = _harness.player.health.half_hearts
	_harness.player.global_position = enemy.global_position
	await _harness.ticks(3)
	assert_true(enemy.is_dazzled(), "still dazzled")
	assert_lt(_harness.player.health.half_hearts, hearts_before, "the contact hit the player")


func test_an_enemy_that_has_not_appeared_is_not_dazzled_and_a_reinforcement_still_comes() -> void:
	var room: Room = _harness.room
	var lamp_pos: Vector2 = _lamp.global_position
	assert_eq(room.enemies_within(lamp_pos, 1000.0).size(), 0, "nobody in the room yet")
	var near: Enemy = _spawn(NIGHT_LIGHT, Vector2(2.0 * Const.TILE_SIZE, 0))
	# An announced reinforcement is not an enemy yet: it is not in the room, so no lamp can reach it.
	room.begin_room([_def(NIGHT_LIGHT)])
	room.danger.reinforcement = true
	room._maybe_schedule_reinforcement()
	assert_eq(room.pending_reinforcement_count(), 1, "one reinforcement announced")
	_shoot_lamp(room.player_bullets())
	await _harness.until(func() -> bool: return _lamp.is_spent(), 10)
	assert_true(near.is_dazzled())
	assert_eq(room.pending_reinforcement_count(), 1, "the lamp did not cancel it")
	var appeared: bool = await _harness.until(func() -> bool: return room.pending_reinforcement_count() == 0, 400)
	assert_true(appeared, "it was due and appeared")
	var newcomer: Enemy = null
	for enemy: Enemy in _harness.living_enemies():
		if enemy != near:
			newcomer = enemy
	assert_not_null(newcomer, "a second enemy is in the room")
	if newcomer != null:
		assert_false(newcomer.is_dazzled(), "it appeared after the flash")


func test_a_spent_lamp_does_not_swallow_a_second_shot_of_the_same_tick() -> void:
	_shoot_lamp(_harness.room.player_bullets())
	_shoot_lamp(_harness.room.player_bullets())
	await _harness.ticks(4)
	assert_true(_lamp.is_spent())
	assert_eq(_harness.room.player_bullets().active_count, 1, "one shot set it off, the other flew through")
