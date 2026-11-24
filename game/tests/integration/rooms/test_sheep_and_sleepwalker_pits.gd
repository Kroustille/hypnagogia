extends GutTest
## Safety nets next to the pits (story 4.3): a sheep charge ends by itself, a sleepwalker never shoves a still player.

const ROOM: String = "res://tests/fixtures/rooms/start_room.tscn"
const SHEEP_DEF: SheepDef = preload("res://data/enemies/sheep.tres")
const SLEEPWALKER_DEF: EnemyDef = preload("res://data/enemies/sleepwalker.tres")
## Diagonal of a one-screen room, in tiles (36 x 19 playable).
const ROOM_DIAGONAL_TILES: float = 41.0

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)


func after_each() -> void:
	_harness.release()


func test_the_real_sheep_limit_exceeds_a_room_diagonal() -> void:
	assert_gt(SHEEP_DEF.max_charge_distance, ROOM_DIAGONAL_TILES)


func test_a_sheep_charge_that_touches_nothing_ends_at_rest_without_a_stun() -> void:
	var def: SheepDef = SHEEP_DEF.duplicate() as SheepDef
	def.max_charge_distance = 2.0
	_harness.player.global_position = Vector2(560.0, 40.0)
	var sheep: Sheep = _harness.room.spawn_enemy(def, Vector2(300.0, 40.0)) as Sheep
	assert_not_null(sheep)
	var charged: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.CHARGE, 200)
	assert_true(charged, "the sheep charges toward the player")
	var start_x: float = sheep.global_position.x
	var ended: bool = await _harness.until(func() -> bool: return sheep._state != Sheep.State.CHARGE, 60)
	assert_true(ended, "the charge stops by itself")
	assert_eq(sheep._state, Sheep.State.REST, "at rest, not stunned")
	assert_almost_eq(sheep.global_position.x - start_x, 2.0 * Const.TILE_SIZE, 4.0, "after about 2 tiles")


func test_a_sleepwalker_does_not_shove_a_still_player() -> void:
	_harness.player.global_position = Vector2(300.0, 160.0)
	var walker: Enemy = _harness.room.spawn_enemy(SLEEPWALKER_DEF, Vector2(348.0, 160.0))
	assert_not_null(walker)
	_harness.player.global_position = Vector2(300.0, 160.0)
	var worst: float = 0.0
	for i: int in 240: # long enough for a walk, the raised arms and the rush
		await _harness.ticks(1)
		worst = maxf(worst, _harness.player.global_position.distance_to(Vector2(300.0, 160.0)))
	assert_lt(worst, 1.0, "the player never moved by 1 px")
