extends GutTest
## Doors are wall tiles of the Walls layer: closed on entry, open once the room is cleared, sealed for good when
## there is no neighbour (story 4.2, AC 5, 6 and 8).

const ROOM_003: String = "res://rooms/pool/onset/onset_combat_003.tscn"
const START_ROOM: String = "res://tests/fixtures/rooms/start_room.tscn"
const WAVE_TICKS: int = 400
## Above the north door, in the middle of the playable area's top row.
const BELOW_NORTH_DOOR: Vector2 = Vector2(304.0, 56.0)

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()
	Input.action_release(&"power_2")
	Input.action_release(&"aim_up")


func _clear_the_room() -> void:
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS)
	_harness.room.kill_all_enemies()
	await _harness.until(func() -> bool: return _harness.room.is_cleared(), WAVE_TICKS)


func test_every_door_is_closed_on_entry_and_open_once_the_room_is_cleared() -> void:
	_harness.start(ROOM_003)
	assert_eq(_harness.room.doors().size(), 4)
	for door: Door in _harness.room.doors():
		assert_eq(door.state, Door.State.CLOSED, "door %s closed" % Door.Side.find_key(door.side))
		assert_true(_harness.door_is_wall(door), "door %s is wall tiles" % Door.Side.find_key(door.side))
	await _clear_the_room()
	for door: Door in _harness.room.doors():
		assert_eq(door.state, Door.State.OPEN)
		assert_true(_harness.door_is_open(door), "door %s has no wall tile left" % Door.Side.find_key(door.side))


func test_a_door_cell_is_a_physical_wall_on_the_same_tick() -> void:
	_harness.start(ROOM_003)
	var north: Door = _harness.door_on(Door.Side.N)
	var space: PhysicsDirectSpaceState2D = _harness.room.get_world_2d().direct_space_state
	var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	query.collision_mask = Const.LAYER_WALLS
	query.position = north.global_position
	assert_eq(space.intersect_point(query).size(), 1, "the closed door has a body")
	north.open()
	assert_eq(space.intersect_point(query).size(), 0, "the open door has none, at once")


func test_a_closed_door_stops_a_player_shot_and_an_enemy_shot_an_open_one_does_not() -> void:
	_harness.start(ROOM_003)
	var north: Door = _harness.door_on(Door.Side.N)
	for manager: BulletManager in [_harness.room.player_bullets(), _harness.room.enemy_bullets()]:
		assert_true(_harness.fire_shot(manager, BELOW_NORTH_DOOR, Vector2.UP), "shot fired")
		await _harness.ticks(40)
		assert_eq(manager.active_count, 0, "the closed door stopped the shot (%s)" % BulletManager.Camp.find_key(manager.camp))
	north.open()
	for manager: BulletManager in [_harness.room.player_bullets(), _harness.room.enemy_bullets()]:
		assert_true(_harness.fire_shot(manager, BELOW_NORTH_DOOR, Vector2.UP))
		await _harness.ticks(40)
		assert_eq(manager.active_count, 1, "the open door let the shot through (%s)" % BulletManager.Camp.find_key(manager.camp))


## Glides at full tilt (stick up, 6 tiles) from below the north door. Returns where the player ends.
func _glide_up_from_below_the_north_door() -> float:
	_harness.player.global_position = BELOW_NORTH_DOOR
	_harness.player.velocity = Vector2.ZERO
	await _harness.ticks(2)
	Input.action_press(&"aim_up", 1.0)
	await _harness.ticks(2)
	Input.action_press(&"power_2")
	await _harness.ticks(2)
	Input.action_release(&"power_2")
	Input.action_release(&"aim_up")
	await _harness.ticks(2)
	return _harness.player.global_position.y


func test_the_glide_ray_stops_at_a_closed_door_and_goes_through_an_open_one() -> void:
	_harness.start(ROOM_003)
	await _harness.until(func() -> bool: return _harness.living_enemies().size() > 0, WAVE_TICKS) # begin_room() has run
	var closed_y: float = await _glide_up_from_below_the_north_door()
	assert_gt(closed_y, float(Const.TILE_SIZE), "the closed door stopped the glide inside the room (y=%s)" % closed_y)
	_harness.door_on(Door.Side.N).open()
	_harness.player.lucidity.set_value(100)
	await _harness.ticks(70) # the glide cooldown
	var open_y: float = await _glide_up_from_below_the_north_door()
	assert_lt(open_y, 0.0, "the open door let the glide through (y=%s)" % open_y)


func test_a_sealed_door_stays_a_wall_when_the_room_is_cleared() -> void:
	_harness.start(ROOM_003)
	var east: Door = _harness.door_on(Door.Side.E)
	east.seal()
	assert_eq(east.state, Door.State.SEALED)
	await _clear_the_room()
	assert_true(_harness.door_is_wall(east), "sealed: still wall tiles")
	assert_eq(east.state, Door.State.SEALED)
	assert_true(_harness.door_is_open(_harness.door_on(Door.Side.N)), "an unsealed door opened")


func test_the_door_cells_are_at_the_canonical_place_of_their_side() -> void:
	var frame: Vector2i = Const.ROOM_TILES + Vector2i(2, 2)
	assert_eq(Door.cells_for(Door.Side.N, frame), [Vector2i(18, 0), Vector2i(19, 0)] as Array[Vector2i])
	assert_eq(Door.cells_for(Door.Side.S, frame), [Vector2i(18, 20), Vector2i(19, 20)] as Array[Vector2i])
	assert_eq(Door.cells_for(Door.Side.W, frame), [Vector2i(0, 9), Vector2i(0, 10)] as Array[Vector2i])
	assert_eq(Door.cells_for(Door.Side.E, frame), [Vector2i(37, 9), Vector2i(37, 10)] as Array[Vector2i])
	assert_eq(Door.center_for(Door.Side.N, frame), Vector2(304.0, 8.0))
