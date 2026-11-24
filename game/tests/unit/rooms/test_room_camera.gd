extends GutTest
## RoomCamera.target: the pure camera placement of story 4.6.

const VIEWPORT: Vector2 = Vector2(640.0, 360.0)
const BAND: float = 24.0
const SCREEN_FRAME: Vector2 = Vector2(608.0, 336.0)
const WIDE_FRAME: Vector2 = Vector2(1184.0, 336.0)
const TALL_FRAME: Vector2 = Vector2(608.0, 640.0)


func _target(player: Vector2, frame: Vector2) -> Vector2:
	return RoomCamera.target(player, frame, VIEWPORT, BAND)


func test_a_screen_room_keeps_the_fixed_centered_position_wherever_the_player_is() -> void:
	var fixed: Vector2 = SCREEN_FRAME / 2.0 - Vector2(0.0, BAND / 2.0)
	for player: Vector2 in [Vector2(20.0, 20.0), Vector2(300.0, 170.0), Vector2(590.0, 320.0), Vector2(0.0, 0.0)]:
		assert_eq(_target(player, SCREEN_FRAME), fixed, "player at %s" % player)


func test_a_wide_room_follows_the_player_on_x_and_stays_centered_on_y() -> void:
	var camera: Vector2 = _target(Vector2(600.0, 100.0), WIDE_FRAME)
	assert_eq(camera.x, 600.0)
	assert_eq(camera.y, 156.0, "the short axis does not move")
	assert_eq(_target(Vector2(600.0, 300.0), WIDE_FRAME).y, 156.0)


func test_a_wide_room_stops_at_both_ends() -> void:
	assert_eq(_target(Vector2(10.0, 168.0), WIDE_FRAME).x, 320.0, "left end: the view starts at the wall")
	assert_eq(_target(Vector2(1180.0, 168.0), WIDE_FRAME).x, WIDE_FRAME.x - 320.0, "right end")


func test_a_tall_room_follows_on_y_and_is_bounded_with_the_band_above() -> void:
	assert_eq(_target(Vector2(304.0, 400.0), TALL_FRAME), Vector2(304.0, 400.0))
	assert_eq(_target(Vector2(304.0, 5.0), TALL_FRAME).y, -BAND + 180.0, "top: the band covers 24 px above the wall")
	assert_eq(_target(Vector2(304.0, 635.0), TALL_FRAME).y, 640.0 - 180.0, "bottom: the view ends at the wall")


func test_the_corners_combine_both_axes() -> void:
	var big: Vector2 = Vector2(1184.0, 640.0)
	assert_eq(_target(Vector2.ZERO, big), Vector2(320.0, 156.0))
	assert_eq(_target(big, big), Vector2(big.x - 320.0, big.y - 180.0))


func test_the_view_stays_in_the_frame_for_many_player_positions() -> void:
	for frame: Vector2 in [WIDE_FRAME, TALL_FRAME, SCREEN_FRAME]:
		for i: int in 200:
			var player: Vector2 = Vector2(fposmod(i * 97.0, frame.x), fposmod(i * 53.0, frame.y))
			var camera: Vector2 = _target(player, frame)
			assert_eq(camera, camera.round(), "whole pixels")
			if frame.x >= VIEWPORT.x:
				assert_true(camera.x - 320.0 >= 0.0 and camera.x + 320.0 <= frame.x, "x within the frame %s at %s" % [frame, player])
			if frame.y + BAND >= VIEWPORT.y:
				assert_true(camera.y - 180.0 >= -BAND and camera.y + 180.0 <= frame.y, "y within the frame and the band %s at %s" % [frame, player])
