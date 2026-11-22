class_name Enemy
extends CharacterBody2D
## Base of the enemies (AR7, D2): body, HitPoints, Hurtbox (player shots), contact Hitbox, HitFeedback and
## Telegraph, created in code from the EnemyDef. Spawned only by a room (room.spawn_enemy()): setup() before
## add_child(). Never pooled nor moved to another parent: its Hurtbox unregisters from the BulletManager when it
## leaves the tree. Node origin = center of the body.
## Shooters (ShooterEnemy) fire through the room's enemy BulletManager, given by setup().
## Subclasses hold the state machine: an enum, one _process_<state>() per state, transitions in _enter() only.
## Scene contract: a %Sprite (Sprite2D) at (0, 0) without material of its own (HitFeedback sets one, SpriteKick
## puts it back at (0, 0)): anchor it with offset, animate it with texture; a %Body (CollisionShape2D).

var hp: HitPoints
## Registered by the room with the player's BulletManager.
var hurtbox: Hurtbox
var telegraph: Telegraph

var _def: EnemyDef
var _target: Node2D
var _target_hurtbox: Hurtbox
## The room's enemy BulletManager: shooters fire through it; null for an enemy that never fires.
var _bullets: BulletManager
var _contact: Hitbox
var _feedback: HitFeedback
var _dead: bool = false

@onready var _sprite: Sprite2D = %Sprite
@onready var _body: CollisionShape2D = %Body


## Dependency injection: call before add_child(). target: what the enemy chases; target_hurtbox: what its contact hits;
## bullets: the room's enemy BulletManager (optional: only shooters need it).
func setup(def: EnemyDef, target: Node2D, target_hurtbox: Hurtbox, bullets: BulletManager = null) -> void:
	_def = def
	_bullets = bullets
	_target = target
	_target_hurtbox = target_hurtbox


func _ready() -> void:
	if _def == null or _target == null or _target_hurtbox == null:
		process_mode = Node.PROCESS_MODE_DISABLED # before the assert: it aborts the function in debug builds
		_def = null # subclasses test _def after super()
		Log.error("combat", "enemy %s added without a complete setup()" % get_path())
		assert(false, "Enemy.setup() must be called before add_child()")
		return
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = Const.LAYER_ENEMIES
	collision_mask = Const.LAYER_WALLS | Const.LAYER_PLAYER | Const.LAYER_ENEMIES

	_body.shape = _make_rectangle(_def.body_size)
	_body.position = Vector2.ZERO
	_body.add_to_group(Const.GROUP_DEBUG_SHAPES)

	hp = HitPoints.new(_def.max_hp)

	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.camp = BulletManager.Camp.ENEMY
	hurtbox.add_child(_make_shape_node("Shape", _def.hurtbox_size)) # before add_child(): its _ready() looks for it
	add_child(hurtbox)
	hurtbox.set_hit_filter(_can_be_hit)
	hurtbox.damage_received.connect(_on_hurtbox_damage_received)

	_contact = Hitbox.new()
	_contact.name = "ContactHitbox"
	_contact.camp = BulletManager.Camp.ENEMY
	_contact.add_child(_make_shape_node("Shape", _def.contact_size))
	_contact.setup(
		_target_hurtbox,
		Tuning.COMBAT.hit_damage_half_hearts,
		DamageInfo.Source.CONTACT,
		GameClock.Group.ENEMIES
	)
	add_child(_contact)

	_feedback = HitFeedback.new()
	_feedback.name = "HitFeedback"
	_feedback.setup(_sprite, GameClock.Group.ENEMIES)
	add_child(_feedback)

	telegraph = Telegraph.new()
	telegraph.name = "Telegraph"
	telegraph.setup(GameClock.Group.ENEMIES)
	add_child(telegraph)


func is_dead() -> bool:
	return _dead


## Rectangle of the physical body in global coordinates (what other bodies collide with).
func body_world_rect() -> Rect2:
	var rectangle: RectangleShape2D = _body.shape as RectangleShape2D
	if rectangle == null:
		return Rect2(global_position, Vector2.ZERO)
	return Rect2(_body.global_position - rectangle.size / 2.0, rectangle.size)


func _can_be_hit() -> bool:
	return not hp.is_dead()


## PV first, feedback after. A hit the HitPoints refuse is refused to the Hurtbox too (no damage number).
func _on_hurtbox_damage_received(info: DamageInfo) -> void:
	var removed: float = hp.apply_damage(info.amount)
	if removed <= 0.0:
		hurtbox.refuse_hit()
		return
	_feedback.play(info.direction) # flash and knockback of story 1.5
	Log.debug("combat", "%s hit amount=%s hp=%s" % [_def.id, removed, hp.current])
	if hp.is_dead():
		_die()


## Once. Disabling the process mode stops the enemy and its children (Hitbox, Telegraph, HitFeedback) and removes
## its body from the physics; it is freed at the end of the frame.
func _die() -> void:
	if _dead:
		return
	_dead = true
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false # no death animation before epic 7
	Log.debug("combat", "%s died" % _def.id)
	queue_free()


## The straight line of AR23 (AStarGrid2D replaces it in story 4.5). velocity is rewritten every tick.
func _move_toward(point: Vector2, speed_px: float, clock_scale: float) -> void:
	var to: Vector2 = point - global_position
	if not is_instance_valid(_target) or to.length_squared() < 1e-6:
		velocity = Vector2.ZERO
	else:
		velocity = to.normalized() * speed_px * clock_scale
	move_and_slide()


func _target_position() -> Vector2:
	return _target.global_position if is_instance_valid(_target) else global_position


## Center to center. Infinite when the target is gone: the enemy neither triggers nor moves.
func _distance_to_target() -> float:
	if not is_instance_valid(_target):
		return INF
	return global_position.distance_to(_target.global_position)


## Pixel size of a rectangle given in tiles. Not finite or <= 0: bounded to 1 px (AR28).
func _pixel_size(tiles: Vector2) -> Vector2:
	var size: Vector2 = tiles * Const.TILE_SIZE
	var valid: bool = is_finite(size.x) and is_finite(size.y) and size.x > 0.0 and size.y > 0.0
	if valid:
		return size
	Log.error("combat", "enemy %s has an invalid size %s, bounded to 1 px" % [_def.id, tiles])
	_assert_failed("EnemyDef sizes must be finite and > 0")
	return Vector2.ONE


func _make_rectangle(tiles: Vector2) -> RectangleShape2D:
	var shape: RectangleShape2D = RectangleShape2D.new() # a fresh shape per instance
	shape.size = _pixel_size(tiles)
	return shape


func _make_shape_node(shape_name: String, tiles: Vector2) -> CollisionShape2D:
	var node: CollisionShape2D = CollisionShape2D.new()
	node.name = shape_name
	node.shape = _make_rectangle(tiles)
	return node


## A failed assert aborts the function it is in (debug builds): kept apart so the caller carries on with the bounded value.
func _assert_failed(message: String) -> void:
	assert(false, message)
