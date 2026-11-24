class_name Professor
extends Boss
## Le Professeur (FR60): the first boss. A puppet: the placeholder rectangle of its body; the phases, the attacks and
## the hit points are in data/bosses/professor.tres, the logic in Boss.

## Placeholder sprite canvas in pixels (2 x 2 tiles, the body of the def). Real sprites come with epic 7.
const SPRITE_SIZE: Vector2i = Vector2i(32, 32)
# Placeholder colors until epic 7: a dark gown, a pale face.
const GOWN_COLOR: Color = Color(0.22, 0.2, 0.34)
const FACE_COLOR: Color = Color(0.85, 0.78, 0.66)
const FACE_RECT: Rect2i = Rect2i(10, 4, 12, 10)


func _ready() -> void:
	super()
	if _def == null:
		return # already reported by Enemy or Boss
	var image: Image = Image.create(SPRITE_SIZE.x, SPRITE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(GOWN_COLOR)
	image.fill_rect(FACE_RECT, FACE_COLOR)
	_sprite.texture = ImageTexture.create_from_image(image)
