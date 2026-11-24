extends GutTest
## The player falls into pits (story 4.3): walking, dash over or into, Glide into, flight, invulnerability, death.
## Room: a start room with a pit band on frame cells 21 and 22 (x from 336 to 368 px), no enemy.

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const ROW_Y: float = 168.0
## Centers of frame cells 15, 19 and 20 (safe floor left of the band), 23 (safe, right of it).
const CELL_15_X: float = 248.0
const CELL_19_X: float = 312.0
const CELL_20_X: float = 328.0
const CELL_23_X: float = 376.0
const PIT_LEFT_EDGE_X: float = 336.0

var _harness: RoomHarness
var _player: Player


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_player.health.set_forced_invulnerability(false)


func after_each() -> void:
	Input.action_release(&"move_right")
	Input.action_release(&"dash")
	Input.action_release(&"aim_right")
	Input.action_release(&"power_2")
	_harness.release()


## Puts the player on a safe cell center and lets the guard see it.
func _stand_at(x: float) -> void:
	_player.global_position = Vector2(x, ROW_Y)
	_player.velocity = Vector2.ZERO
	await _harness.ticks(2)


func _dash_right() -> void:
	Input.action_press(&"move_right")
	await _harness.ticks(1)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_right")


func test_walking_into_a_pit_costs_half_a_heart_and_returns_to_the_last_safe_cell() -> void:
	await _stand_at(CELL_20_X)
	var before: int = _player.health.half_hearts
	Input.action_press(&"move_right")
	var fell: bool = await _harness.until(func() -> bool: return _player.health.half_hearts < before, 60)
	Input.action_release(&"move_right")
	assert_true(fell, "the center entered the pit")
	assert_eq(_player.health.half_hearts, before - 1, "one half-heart")
	assert_lt(_player.global_position.x, PIT_LEFT_EDGE_X, "back on the floor")
	assert_eq(_player.velocity, Vector2.ZERO)
	assert_true(_player.health.is_hit_invulnerable(), "the hit invulnerability is armed")


func test_the_return_is_the_center_of_the_last_safe_cell() -> void:
	await _stand_at(CELL_20_X)
	Input.action_press(&"move_right")
	await _harness.until(func() -> bool: return _player.health.half_hearts < 6, 60)
	Input.action_release(&"move_right")
	assert_eq(_player.global_position.x, CELL_20_X, "center of cell 20, not the exact edge")


func test_a_dash_over_the_band_does_not_fall() -> void:
	await _stand_at(CELL_20_X)
	await _dash_right()
	await _harness.until(func() -> bool: return not _player.is_dashing(), 60)
	await _harness.ticks(2)
	assert_eq(_player.health.half_hearts, 6, "no damage")
	assert_gt(_player.global_position.x, 368.0, "landed beyond the band")


func test_a_dash_ending_in_the_band_falls_on_its_last_tick() -> void:
	await _stand_at(CELL_19_X)
	await _dash_right()
	await _harness.until(func() -> bool: return _player.is_dashing(), 10)
	await _harness.until(func() -> bool: return not _player.is_dashing(), 60)
	assert_eq(_player.global_position.x, CELL_19_X, "returned at the very tick the dash ended")
	assert_eq(_player.health.half_hearts, 5, "the dash invulnerability (0.15 s) ended before the dash (0.18 s)")


func test_a_glide_landing_in_the_band_falls_and_arms_no_arrival_invulnerability() -> void:
	await _stand_at(CELL_15_X)
	var lucidity_before: int = _player.lucidity.value
	Input.action_press(&"aim_right", 1.0)
	await _harness.ticks(2)
	Input.action_press(&"power_2")
	await _harness.ticks(2)
	Input.action_release(&"power_2")
	Input.action_release(&"aim_right")
	await _harness.ticks(2)
	assert_lt(_player.lucidity.value, lucidity_before, "the Glide was paid")
	assert_lt(_player.glide_cooldown_progress(), 1.0, "its recharge runs")
	assert_eq(_player.health.half_hearts, 5, "the fall hit was not refused")
	assert_false(_player.is_arrival_invulnerable())
	assert_eq(_player.global_position.x, CELL_15_X, "back at the cell the glide left")


func test_a_glide_over_safe_floor_still_arms_arrival_invulnerability() -> void:
	await _stand_at(CELL_23_X)
	Input.action_press(&"aim_right", 1.0)
	await _harness.ticks(2)
	Input.action_press(&"power_2")
	await _harness.ticks(2)
	Input.action_release(&"power_2")
	Input.action_release(&"aim_right")
	assert_eq(_player.health.half_hearts, 6)
	assert_true(_player.is_arrival_invulnerable())


func test_flying_over_pits_never_falls() -> void:
	_player.stats.set_modifier(self, StatBlock.Stat.CAN_FLY_OVER_PITS, StatBlock.Kind.ADD_FLAT, 1.0)
	assert_true(_player.can_fly_over_pits())
	await _stand_at(CELL_20_X)
	Input.action_press(&"move_right")
	await _harness.until(func() -> bool: return _player.global_position.x > 380.0, 90)
	Input.action_release(&"move_right")
	assert_gt(_player.global_position.x, 380.0, "crossed the band")
	assert_eq(_player.health.half_hearts, 6)
	assert_false(_harness.room.is_pit_at(_player._pit_guard.last_safe), "a pit is never remembered as a safe place")


func test_a_fall_drops_the_momentum() -> void:
	await _stand_at(CELL_20_X)
	var before: int = _player.health.half_hearts
	Input.action_press(&"move_right")
	var fell: bool = await _harness.until(func() -> bool: return _player.health.half_hearts < before, 60)
	assert_true(fell)
	assert_eq(_player._motor.velocity, Vector2.ZERO, "the speed is gone at the tick of the fall")
	await _harness.ticks(1)
	Input.action_release(&"move_right")
	assert_lt(_player._motor.velocity.x, 80.0, "the next tick restarts from rest, not from full speed")


func test_the_spawn_cell_is_a_safe_place_from_the_start() -> void:
	var room: Room = _harness.room
	_player.global_position = Vector2(344.0, ROW_Y) # in the band
	_player.enter_room(room)
	assert_true(_player._pit_guard.has_safe())
	assert_eq(_player._pit_guard.last_safe, room.cell_center_at(room.player_spawn_position()))
	await _harness.ticks(2)
	assert_lt(_player.global_position.x, PIT_LEFT_EDGE_X, "a first tick in a pit falls back to the spawn cell")


func test_leaving_another_room_keeps_the_pits_of_the_current_one() -> void:
	var other: Room = Room.new()
	_player.leave_room(other)
	other.free()
	assert_not_null(_player._room, "a room that is not the current one cannot cut the pits")
	_player.leave_room(_harness.room)
	assert_null(_player._room)


func test_pit_damage_comes_from_the_stat() -> void:
	_player.stats.set_modifier(self, StatBlock.Stat.PIT_DAMAGE, StatBlock.Kind.ADD_FLAT, 1.0)
	await _stand_at(CELL_20_X)
	Input.action_press(&"move_right")
	await _harness.until(func() -> bool: return _player.health.half_hearts < 6, 60)
	Input.action_release(&"move_right")
	assert_eq(_player.health.half_hearts, 4, "base 1 plus 1")


func test_an_invulnerable_player_is_returned_without_damage() -> void:
	_player.health.set_forced_invulnerability(true)
	await _stand_at(CELL_20_X)
	Input.action_press(&"move_right")
	await _harness.ticks(40)
	Input.action_release(&"move_right")
	assert_eq(_player.health.half_hearts, 6)
	assert_lt(_player.global_position.x, PIT_LEFT_EDGE_X, "never camps in the pit")


func test_a_lethal_fall_reports_the_pit_before_the_end_of_the_run() -> void:
	var log: Array[String] = []
	var on_hit: Callable = func(_damage: int, source: int) -> void: log.append("hit %d" % source)
	var on_end: Callable = func(_outcome: int) -> void: log.append("end")
	Events.player_hit.connect(on_hit)
	Events.run_ended.connect(on_end)
	_player.health.half_hearts = 1
	await _stand_at(CELL_20_X)
	Input.action_press(&"move_right")
	await _harness.until(func() -> bool: return _player.health.is_dead(), 60)
	Input.action_release(&"move_right")
	Events.player_hit.disconnect(on_hit)
	Events.run_ended.disconnect(on_end)
	assert_eq(log, ["hit %d" % DamageInfo.Source.PIT, "end"] as Array[String])
