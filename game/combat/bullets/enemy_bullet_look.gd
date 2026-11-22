@abstract
class_name EnemyBulletLook
## The one look of every enemy bullet (FR26, NFR8): a disc of the collision diameter (Tuning.COMBAT.enemy_bullet_radius)
## in Const.COLOR_ENEMY_BULLET, with a 1 px outer ring in Const.COLOR_ENEMY_BULLET_OUTLINE, transparent outside.
## Built once and shared: BulletManager.add_appearance() returns the same index for the same texture, so a manager
## draws every enemy bullet with one MultiMeshInstance2D. Whoever fires enemy bullets uses this texture, debug included.

static var _texture: Texture2D


static func texture() -> Texture2D:
	if _texture == null:
		_texture = _build()
	return _texture


static func _build() -> Texture2D:
	var radius_px: float = Tuning.COMBAT.enemy_bullet_radius * Const.TILE_SIZE
	var valid: bool = is_finite(radius_px) and radius_px > 0.0
	if not valid:
		# Safe state first: a failed assert aborts the function in debug builds.
		radius_px = 1.0
		Log.error("combat", "enemy_bullet_radius %s is invalid, smallest disc used" % Tuning.COMBAT.enemy_bullet_radius)
		_assert_failed("enemy_bullet_radius must be finite and > 0")
	var side: int = maxi(2, ceili(2.0 * radius_px))
	var image: Image = Image.create(side, side, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(side, side) / 2.0
	for y: int in side:
		for x: int in side:
			var distance: float = (Vector2(x + 0.5, y + 0.5) - center).length()
			if distance > radius_px:
				continue # transparent
			image.set_pixel(x, y, Const.COLOR_ENEMY_BULLET_OUTLINE if distance > radius_px - 1.0 else Const.COLOR_ENEMY_BULLET)
	return ImageTexture.create_from_image(image)


static func _assert_failed(message: String) -> void:
	assert(false, message)
