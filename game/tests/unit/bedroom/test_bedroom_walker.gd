extends GutTest
## The character of the bedroom (story 6.5): the speed of the player, stopped by the walls, frozen with the clock.

const SCENE: PackedScene = preload("res://bedroom/bedroom.tscn")
const WALL_INNER_EDGE: float = 16.0 # the walls are one tile thick

var _bedroom: Bedroom
var _walker: BedroomWalker


func before_each() -> void:
	_bedroom = SCENE.instantiate() as Bedroom
	add_child_autofree(_bedroom)
	_walker = _bedroom.walker()
	await wait_physics_frames(1)


func after_each() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"move_up")
	GameClock.paused = false


func test_it_reaches_the_maximum_speed_of_the_player() -> void:
	Input.action_press(&"move_right")
	await wait_physics_frames(60) # far longer than the acceleration ramp
	assert_almost_eq(_walker.motor_velocity().x, Tuning.PLAYER.move_speed * Const.TILE_SIZE, 0.01)
	assert_almost_eq(_walker.get_real_velocity().x, Tuning.PLAYER.move_speed * Const.TILE_SIZE, 0.5)


func test_it_stops_at_the_wall() -> void:
	Input.action_press(&"move_left")
	await wait_physics_frames(400)
	var x: float = _walker.global_position.x
	assert_gt(x, WALL_INNER_EDGE, "inside the room")
	assert_lt(x, WALL_INNER_EDGE + 12.0, "against the wall")
	await wait_physics_frames(10)
	assert_eq(_walker.global_position.x, x, "it does not push through")


func test_it_stops_at_the_furniture() -> void:
	_walker.global_position = Vector2(64, 160) # under the bed
	Input.action_press(&"move_up")
	await wait_physics_frames(120)
	assert_gt(_walker.global_position.y, 112.0, "the bed is in the way")


func test_it_does_not_move_while_the_clock_is_paused() -> void:
	GameClock.paused = true
	Input.action_press(&"move_right")
	var before: Vector2 = _walker.global_position
	await wait_physics_frames(30)
	assert_eq(_walker.global_position, before)
