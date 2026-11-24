extends GutTest
## Rooms of two screens (story 4.6): sizes, camera that follows, shake, spawns, validator.

const WIDE: String = "res://rooms/pool/onset/onset_combat_007.tscn"
const TALL: String = "res://rooms/pool/onset/onset_combat_008.tscn"
const VALID: String = "res://tests/fixtures/rooms/valid.tscn"

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)


func after_each() -> void:
	_harness.release()


func _camera() -> Camera2D:
	return _harness.room.get_node("%Camera") as Camera2D


func test_the_sizes_come_from_the_one_screen_size() -> void:
	assert_eq(Room.playable_tiles_of(Room.SizeKind.SCREEN), Const.ROOM_TILES)
	assert_eq(Room.playable_tiles_of(Room.SizeKind.WIDE), Vector2i(72, 19))
	assert_eq(Room.playable_tiles_of(Room.SizeKind.TALL), Vector2i(36, 38))
	_harness.start(WIDE)
	assert_eq(_harness.room.frame_cells(), Vector2i(74, 21))
	assert_eq(_harness.room.frame_px(), Vector2(1184.0, 336.0))


func test_the_camera_follows_the_player_in_a_wide_room_and_snaps_on_entry() -> void:
	_harness.start(WIDE)
	var room: Room = _harness.room
	assert_eq(_camera().position, Vector2(592.0, 156.0), "centered on the player placed at the middle")
	_harness.player.global_position = Vector2(300.0, 100.0)
	await _harness.ticks(2)
	assert_eq(_camera().position, Vector2(320.0, 156.0), "stops at the left wall")
	_harness.player.global_position = Vector2(700.0, 100.0)
	await _harness.ticks(2)
	assert_eq(_camera().position.x, 700.0, "follows")
	assert_eq(room.frame_px().y, 336.0)


func test_the_camera_follows_vertically_in_a_tall_room() -> void:
	_harness.start(TALL)
	_harness.player.global_position = Vector2(304.0, 100.0)
	await _harness.ticks(2)
	assert_eq(_camera().position, Vector2(304.0, 156.0), "x centered, y at its top bound")
	_harness.player.global_position = Vector2(304.0, 400.0)
	await _harness.ticks(2)
	assert_eq(_camera().position, Vector2(304.0, 400.0))


func test_the_shake_returns_to_the_followed_position() -> void:
	_harness.start(WIDE)
	_harness.player.global_position = Vector2(700.0, 100.0)
	await _harness.ticks(2)
	_harness.room.shake(3, 0.1)
	await _harness.ticks(2)
	assert_ne(_harness.room.shake_offset(), Vector2.ZERO, "shaking")
	await _harness.until(func() -> bool: return _harness.room.shake_offset() == Vector2.ZERO, 30)
	assert_eq(_camera().offset, Vector2.ZERO)
	assert_eq(_camera().position, Vector2(700.0, 156.0), "back on the followed position, not on a fixed one")


func test_the_distortion_covers_the_whole_frame_of_a_big_room() -> void:
	_harness.start(TALL)
	var postfx: ColorRect = _harness.room.get_node("LucidityFx/PostFx") as ColorRect
	assert_eq(postfx.size, _harness.room.frame_px())
	assert_eq(postfx.get_global_rect().position, _harness.room.global_position, "anchored to the room")


func test_the_waves_appear_inside_a_wide_room_and_a_reinforcement_too() -> void:
	_harness.start(WIDE)
	var room: Room = _harness.room
	var appeared: bool = await _harness.until(func() -> bool: return _harness.living_enemies().size() == 3, 400)
	assert_true(appeared)
	var inside: Rect2 = Rect2(Vector2(16.0, 16.0), Vector2(72.0 * 16.0, 19.0 * 16.0))
	for enemy: Enemy in _harness.living_enemies():
		assert_true(inside.has_point(room.to_local(enemy.global_position)), "%s in the playable area" % enemy.name)
	var far_x: float = 0.0
	for enemy: Enemy in _harness.living_enemies():
		far_x = maxf(far_x, room.to_local(enemy.global_position).x)
	assert_gt(far_x, 640.0, "an enemy appears beyond the first screen")
	room.danger.reinforcement = true
	room._maybe_schedule_reinforcement()
	assert_eq(room.pending_reinforcement_count(), 1)
	var came: bool = await _harness.until(func() -> bool: return room.pending_reinforcement_count() == 0, 400)
	assert_true(came)
	assert_eq(_harness.living_enemies().size(), 4)


func test_the_validator_accepts_the_big_rooms_and_refuses_the_wrong_sizes() -> void:
	assert_eq(RoomValidator.validate(load(WIDE) as PackedScene), PackedStringArray())
	assert_eq(RoomValidator.validate(load(TALL) as PackedScene), PackedStringArray())
	var screen_as_wide: Room = (load(VALID) as PackedScene).instantiate() as Room
	screen_as_wide.size_kind = Room.SizeKind.WIDE
	var problems: PackedStringArray = RoomValidator.validate_room(screen_as_wide, "x")
	screen_as_wide.free()
	assert_gt(problems.size(), 0)
	assert_string_contains(problems[0], "expected 72x19")
	var wide_as_screen: Room = (load(WIDE) as PackedScene).instantiate() as Room
	wide_as_screen.size_kind = Room.SizeKind.SCREEN
	problems = RoomValidator.validate_room(wide_as_screen, "y")
	wide_as_screen.free()
	assert_string_contains(problems[0], "expected 36x19")


func test_the_screen_to_world_transform_follows_the_camera_for_the_mouse_aim() -> void:
	_harness.start(WIDE)
	_harness.player.global_position = Vector2(800.0, 100.0)
	await _harness.ticks(3)
	await get_tree().process_frame
	await get_tree().process_frame
	var center: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * (Vector2(Const.VIEWPORT) / 2.0)
	assert_almost_eq(center.x, 800.0, 1.5, "the middle of the screen is the camera, so get_global_mouse_position() follows it")
