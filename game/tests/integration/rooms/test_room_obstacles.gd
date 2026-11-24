extends GutTest
## Low obstacles let shots of both camps pass, high obstacles stop them (story 4.2, AC 7).

const ROOM_001: String = "res://rooms/pool/onset/onset_combat_001.tscn"
## Tiles between the shot's origin and the first cell of the obstacle.
const RUN_UP_TILES: int = 4

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM_001)


func after_each() -> void:
	_harness.release()


## A shot aimed right at the first cell (in reading order) of the obstacle layer, from RUN_UP_TILES to its left.
func _shoot_at_obstacle(layer_name: String, manager: BulletManager) -> void:
	var layer: TileMapLayer = _harness.room.get_node(layer_name) as TileMapLayer
	var cells: Array[Vector2i] = layer.get_used_cells()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var cell: Vector2i = cells[0]
	var origin: Vector2 = (Vector2(cell.x - RUN_UP_TILES, cell.y) + Vector2(0.5, 0.5)) * Const.TILE_SIZE
	assert_true(_harness.fire_shot(manager, origin, Vector2.RIGHT), "shot fired toward %s" % layer_name)
	await _harness.ticks(45) # 7.5 tiles at 10 tiles per second: past a 2-tile block, short of the far wall


func test_a_high_obstacle_stops_shots_of_both_camps() -> void:
	for manager: BulletManager in [_harness.room.player_bullets(), _harness.room.enemy_bullets()]:
		await _shoot_at_obstacle("HighObstacles", manager)
		assert_eq(manager.active_count, 0, "stopped by the high obstacle (%s)" % BulletManager.Camp.find_key(manager.camp))


func test_a_low_obstacle_lets_shots_of_both_camps_pass() -> void:
	for manager: BulletManager in [_harness.room.player_bullets(), _harness.room.enemy_bullets()]:
		await _shoot_at_obstacle("LowObstacles", manager)
		assert_eq(manager.active_count, 1, "crossed the low obstacle (%s)" % BulletManager.Camp.find_key(manager.camp))
