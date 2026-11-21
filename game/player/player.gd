class_name Player
extends CharacterBody2D
## The player. Node origin = center of the torso: shots (story 1.5) will start from there.
## Movement reads the InputMap in _physics_process and obeys GameClock.

## Placeholder sprite size in pixels (structural, not gameplay). Real sprites come with epic 7.
const SPRITE_SIZE: Vector2i = Vector2i(16, 24)
# Placeholder colors until epic 7.
const SPRITE_FILL_COLOR: Color = Color(0.45, 0.65, 0.95)
const SPRITE_RIM_COLOR: Color = Color(0.75, 0.88, 1.0)

## Emitted when a dash finishes, after its last movement.
signal dash_ended

# Placeholder tint while the dash makes the player invulnerable, until epic 7.
const DASH_TINT: Color = Color(1.0, 1.0, 1.0, 0.5)

var _motor: PlayerMotor
var _dash: Dash
## Last movement direction (unit vector). The character faces the camera until the player first moves.
var _facing: Vector2 = Vector2.DOWN

@onready var _sprite: Sprite2D = %Sprite
@onready var _hitbox: CollisionShape2D = %Hitbox


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = Const.LAYER_PLAYER
	collision_mask = Const.LAYER_WALLS
	_motor = PlayerMotor.new(Tuning.PLAYER)
	_dash = Dash.new(Tuning.DASH)
	_dash.ended.connect(_on_dash_ended)

	_sprite.centered = true
	_sprite.offset = Vector2.ZERO
	_sprite.texture = _make_sprite_texture()

	# A fresh shape per instance: never modify a sub-resource shared by the scene.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2.ONE * Tuning.PLAYER.hitbox_size * Const.TILE_SIZE
	_hitbox.shape = shape
	_hitbox.position = Vector2.ZERO
	_hitbox.add_to_group(Const.GROUP_DEBUG_SHAPES)


func _physics_process(delta: float) -> void:
	var clock_scale: float = GameClock.scale(GameClock.Group.PLAYER)
	var wish: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	if wish != Vector2.ZERO:
		_facing = wish.normalized()
	# The motor runs on the real delta so the ramps and the paused state stay consistent with the input;
	# it keeps stepping during a dash so walking resumes smoothly when the dash ends.
	var motor_velocity: Vector2 = _motor.step(wish, delta)
	_dash.tick(clock_scale, Input.is_action_just_pressed(&"dash"), _facing)
	# velocity is rewritten every tick: move_and_slide() alters it when sliding, never read it back.
	if _dash.is_active():
		# Already scaled by the clock inside Dash: do not multiply by clock_scale again.
		velocity = _dash.velocity(delta)
	else:
		# The clock scale is applied once, on the final velocity (move_and_slide() uses the unscaled delta).
		velocity = motor_velocity * clock_scale
	move_and_slide()
	_dash.finish_tick()  # after the movement: listeners of dash_ended see the final position
	_update_dash_tint()


func is_dash_invulnerable() -> bool:
	return _dash.is_invulnerable()


## Story 2.1 will add the invulnerability granted after a hit; for now only the dash counts.
func is_invulnerable() -> bool:
	return is_dash_invulnerable()


func is_dashing() -> bool:
	return _dash.is_active()


func _update_dash_tint() -> void:
	_sprite.modulate = DASH_TINT if is_dash_invulnerable() else Color.WHITE


func _on_dash_ended() -> void:
	dash_ended.emit()


func _make_sprite_texture() -> Texture2D:
	var image: Image = Image.create(SPRITE_SIZE.x, SPRITE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(SPRITE_FILL_COLOR)
	for x: int in SPRITE_SIZE.x:
		image.set_pixel(x, 0, SPRITE_RIM_COLOR)
		image.set_pixel(x, SPRITE_SIZE.y - 1, SPRITE_RIM_COLOR)
	for y: int in SPRITE_SIZE.y:
		image.set_pixel(0, y, SPRITE_RIM_COLOR)
		image.set_pixel(SPRITE_SIZE.x - 1, y, SPRITE_RIM_COLOR)
	return ImageTexture.create_from_image(image)
