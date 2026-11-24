extends GutTest
## The charge of the Sheep (story 4.5, AC 6): a high obstacle stuns it like a wall, a low one only ends the charge.
## Room: a high block at frame cell (13, 5) and a low block at frame cell (13, 13), open floor around.

const ROOM: String = "res://tests/fixtures/rooms/sheep_blocks.tscn"
const SHEEP: SheepDef = preload("res://data/enemies/sheep.tres")
## The sheep and the player in line with the blocks.
const HIGH_ROW_Y: float = 88.0
const LOW_ROW_Y: float = 216.0
const BLOCK_LEFT_EDGE_X: float = 208.0
const CHARGE_TICKS: int = 400

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)


func after_each() -> void:
	_harness.release()


func _sheep_in_line_with(row_y: float) -> Sheep:
	_harness.player.global_position = Vector2(400.0, row_y)
	var sheep: Sheep = _harness.room.spawn_enemy(SHEEP, Vector2(88.0, row_y)) as Sheep
	assert_not_null(sheep)
	return sheep


func test_a_high_obstacle_stuns_the_charging_sheep() -> void:
	var sheep: Sheep = _sheep_in_line_with(HIGH_ROW_Y)
	var stunned: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.STUN, CHARGE_TICKS)
	assert_true(stunned, "stunned by the high obstacle")
	assert_lt(sheep.global_position.x, BLOCK_LEFT_EDGE_X, "stopped in front of it")


func test_a_low_obstacle_ends_the_charge_without_a_stun() -> void:
	var sheep: Sheep = _sheep_in_line_with(LOW_ROW_Y)
	var charged: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.CHARGE, CHARGE_TICKS)
	assert_true(charged, "it charges")
	var stunned: bool = false
	var ended: bool = false
	for i: int in 120:
		await _harness.ticks(1)
		if sheep._state == Sheep.State.STUN:
			stunned = true
		if sheep._state == Sheep.State.REST:
			ended = true
			break
	assert_true(ended, "back to rest")
	assert_false(stunned, "never stunned")
	assert_lt(sheep.global_position.x, BLOCK_LEFT_EDGE_X, "stopped in front of the low block")


func test_the_backup_does_not_shove_the_player_it_touches() -> void:
	var sheep: Sheep = _sheep_in_line_with(HIGH_ROW_Y)
	var telegraphing: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.TELEGRAPH, CHARGE_TICKS)
	assert_true(telegraphing)
	# The player steps behind the sheep, against its back: the backup would press on it.
	var behind: Vector2 = sheep.global_position - Vector2(11.0, 0.0)
	_harness.player.global_position = behind
	_harness.player.velocity = Vector2.ZERO
	var worst: float = 0.0
	var backed: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.BACKUP, CHARGE_TICKS)
	assert_true(backed)
	while sheep._state == Sheep.State.BACKUP:
		await _harness.ticks(1)
		worst = maxf(worst, _harness.player.global_position.distance_to(behind))
	assert_lt(worst, 1.0, "the player was not moved")
