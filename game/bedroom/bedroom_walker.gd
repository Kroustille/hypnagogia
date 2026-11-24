class_name BedroomWalker
extends CharacterBody2D
## The character of the bedroom (story 6.5): walks at the speed and with the ramps of the player, stopped by the walls
## and the furniture. No shot, dash or power, and no Room: the Player itself needs one. Reads the InputMap in the
## physics tick and obeys GameClock, so the pause and the seed window freeze it like everything else.

## Placeholder silhouette of the player, until the sprites of epic 7.
const SILHOUETTE: Vector2 = Vector2(16, 24)
const SILHOUETTE_COLOR: Color = Color(0.85, 0.8, 0.95)

var _motor: PlayerMotor


func _ready() -> void:
	_motor = PlayerMotor.new(Tuning.PLAYER)


func _physics_process(delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.PLAYER)
	var wish: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	_motor.step(wish, delta) # the real delta, like the Player: the ramps stay consistent with the input
	velocity = _motor.velocity * clock_scale # the clock scale is applied once, on the final velocity
	move_and_slide()


## Velocity of the motor in px/s, before the clock scale (checks).
func motor_velocity() -> Vector2:
	return _motor.velocity


func _draw() -> void:
	draw_rect(Rect2(-SILHOUETTE.x / 2.0, -SILHOUETTE.y + 6.0, SILHOUETTE.x, SILHOUETTE.y), SILHOUETTE_COLOR)
