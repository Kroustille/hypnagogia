class_name Player
extends CharacterBody2D
## The player. Node origin = center of the torso: shots (story 1.5) will start from there.
## Movement reads the InputMap in _physics_process and obeys GameClock.

## Placeholder sprite size in pixels (structural, not gameplay). Real sprites come with epic 7.
const SPRITE_SIZE: Vector2i = Vector2i(16, 24)
# Placeholder colors until epic 7.
const SPRITE_FILL_COLOR: Color = Color(0.45, 0.65, 0.95)
const SPRITE_RIM_COLOR: Color = Color(0.75, 0.88, 1.0)

var _motor: PlayerMotor

@onready var _sprite: Sprite2D = %Sprite
@onready var _hitbox: CollisionShape2D = %Hitbox


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = Const.LAYER_PLAYER
	collision_mask = Const.LAYER_WALLS
	_motor = PlayerMotor.new(Tuning.PLAYER)

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
	var motor_velocity: Vector2 = _motor.step(wish, delta * clock_scale)
	# move_and_slide() integrates with the unscaled physics delta: scaling the velocity is the same as scaling delta.
	# velocity is rewritten every tick from the motor: move_and_slide() alters it when sliding, never read it back.
	velocity = motor_velocity * clock_scale
	move_and_slide()


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
