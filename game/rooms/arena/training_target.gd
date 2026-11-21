class_name TrainingTarget
extends Node2D
## Training target of the arena: reacts to the player's shots (flash and visual knockback), nothing else.
## Indestructible and without HP (Health: story 2.1). No physics body: the player and the dash go through it.
## The room registers its hurtbox with the player's BulletManager. The 12x20 px hurtbox rectangle lives in the
## scene, local to each instance (the Hurtbox reads it in its own _ready(), before this node's).

## Placeholder sprite size in pixels, same as the player (structural). Real sprites come with epic 7.
const SPRITE_SIZE: Vector2i = Vector2i(16, 24)
# Placeholder colors until epic 7: orange, distinct from the player (blue) and the shots (cyan).
const SPRITE_FILL_COLOR: Color = Color(0.85, 0.5, 0.2)
const SPRITE_RIM_COLOR: Color = Color(1.0, 0.75, 0.45)

var _feedback: HitFeedback

@onready var hurtbox: Hurtbox = %Hurtbox
@onready var _sprite: Sprite2D = %Sprite


func _ready() -> void:
	_sprite.centered = true
	_sprite.texture = _make_sprite_texture()
	_feedback = HitFeedback.new()
	_feedback.setup(_sprite, GameClock.Group.ENEMIES)
	add_child(_feedback)
	hurtbox.damage_received.connect(_on_hurtbox_damage_received)


func _on_hurtbox_damage_received(info: DamageInfo) -> void:
	_feedback.play(info.direction)
	Log.debug("combat", "training target hit amount=%s" % info.amount)


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
