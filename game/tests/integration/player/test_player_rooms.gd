extends GutTest
## The player outlives the rooms (story 4.8, AC 5): leaving a room gives back what the room gave, entering another one
## equips it again, and equipping twice changes nothing.

const ROOM: String = "res://tests/fixtures/rooms/start_room.tscn"

var _harness: RoomHarness
var _player: Player


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player


func after_each() -> void:
	_harness.release()


func test_equipping_the_same_manager_again_changes_nothing() -> void:
	var params: BulletParams = _player._shot_params
	assert_not_null(params, "the room equipped the player")
	_player.equip_bullets(_harness.room.player_bullets())
	assert_same(_player._shot_params, params, "same manager: same shot, no new appearance")
	assert_same(_player._bullets, _harness.room.player_bullets())


func test_equipping_another_manager_replaces_the_shot() -> void:
	var params: BulletParams = _player._shot_params
	var other: BulletManager = _harness.room.enemy_bullets()
	_player.equip_bullets(other)
	assert_same(_player._bullets, other)
	assert_ne(_player._shot_params, params, "a manager of another room needs its own appearance")


func test_leaving_the_room_drops_the_bullets_and_the_pit_source() -> void:
	var room: Room = _harness.room
	_player.leave_room(room)
	assert_null(_player._bullets, "no PlayerBullets left")
	assert_null(_player._shot_params)
	assert_null(_player._room, "no pit source left")


func test_leaving_a_room_that_is_not_the_current_one_keeps_the_current_equipment() -> void:
	var stranger: Room = Room.new()
	_player.leave_room(stranger)
	assert_not_null(_player._bullets, "the bullets of the current room stay")
	assert_not_null(_player._room)
	stranger.free()


func test_the_room_unsubscribes_from_the_player_when_it_leaves_the_tree() -> void:
	var room: Room = _harness.room
	var before: int = _player.awakening_used.get_connections().size()
	var glided_before: int = _player.glided.get_connections().size()
	var danger_before: int = _player.lucidity.room_danger_raised.get_connections().size()
	assert_gt(before, 0, "the room listens to the player while it is in the tree")
	room.get_parent().remove_child(room)
	assert_eq(_player.awakening_used.get_connections().size(), before - 1)
	assert_eq(_player.glided.get_connections().size(), glided_before - 1)
	assert_eq(_player.lucidity.room_danger_raised.get_connections().size(), danger_before - 1)
	room.free()


func test_stopping_the_motion_cancels_a_dash_in_flight() -> void:
	Input.action_press(&"move_right")
	await _harness.ticks(1)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_right")
	assert_true(_player.is_dashing(), "the dash is in flight")
	_player.stop_motion()
	assert_false(_player.is_dashing())
	assert_eq(_player.velocity, Vector2.ZERO)
