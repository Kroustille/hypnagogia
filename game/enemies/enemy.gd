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

## Placeholder tint of a dazzled enemy, until epic 7.
const DAZZLED_TINT: Color = Color(1.0, 1.0, 0.55)
## Rounding margin when comparing the dazzle countdown.
const DAZZLE_EPSILON: float = 1e-6
## A waypoint closer than this (px) is reached.
const WAYPOINT_REACHED_PX: float = 2.0
## Margin added to the body half-width when testing the straight line (px).
const PATH_CLEARANCE_PX: float = 1.0
## The first recalculations of the enemies are spread over this many slots of the refresh interval.
const PATH_STAGGER_SLOTS: int = 8

var hp: HitPoints
## Registered by the room with the player's BulletManager.
var hurtbox: Hurtbox
var telegraph: Telegraph
## The room's danger profile (story 3.6), read when the enemy fires or starts a telegraph. Never null.
var danger: DangerProfile
## Multiplier on the hit points of the def, set before add_child() (story 5.10: the floor factor of the Reflection).
var hp_factor: float = 1.0

var _def: EnemyDef
var _target: Node2D
var _target_hurtbox: Hurtbox
## The room's enemy BulletManager: shooters fire through it; null for an enemy that never fires.
var _bullets: BulletManager
var _contact: Hitbox
var _feedback: HitFeedback
var _dead: bool = false
## Ticks of dazzle left (story 4.4): the enemy neither moves nor attacks while it is above 0.
var _dazzle_ticks_left: float = 0.0
## The room's navigation grid (story 4.5), null for an enemy without one (it then goes straight).
var _nav: RoomNav
## Cell centers (global) of the current path and the next one to reach. Empty: straight line.
var _path: PackedVector2Array = PackedVector2Array()
var _path_index: int = 0
var _path_start: Vector2 = Vector2.INF
var _last_chase_frame: int = -2
## Ticks until the next planning of the path (clock-scaled), -1 before the first one.
var _plan_ticks_left: float = -1.0
var _stagger: int = 0
## Reused by the test moves of _presses_target().
var _probe: KinematicCollision2D = KinematicCollision2D.new()

@onready var _sprite: Sprite2D = %Sprite
@onready var _body: CollisionShape2D = %Body


## Dependency injection: call before add_child(). target: what the enemy chases; target_hurtbox: what its contact hits;
## bullets: the room's enemy BulletManager (optional: only shooters need it). danger: the room's profile, shared and
## mutated by the room (optional: a fresh neutral profile of its own otherwise). nav: the room's grid (optional: without it
## the enemy only goes straight).
func setup(def: EnemyDef, target: Node2D, target_hurtbox: Hurtbox, bullets: BulletManager = null, room_danger: DangerProfile = null, nav: RoomNav = null) -> void:
	_nav = nav
	if nav != null:
		_stagger = nav.next_stagger()
	danger = room_danger if room_danger != null else DangerProfile.new()
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
	collision_mask = Const.LAYER_WALLS | Const.LAYER_PLAYER | Const.LAYER_ENEMIES | Const.LAYER_HIGH_OBSTACLES | Const.LAYER_LOW_OBSTACLES | Const.LAYER_FURNITURE

	_body.shape = _make_rectangle(_def.body_size)
	_body.position = Vector2.ZERO
	_body.add_to_group(Const.GROUP_DEBUG_SHAPES)

	hp = HitPoints.new(_def.max_hp * hp_factor)

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


## Starts the telegraph with the room's danger applied (a telegraph already running keeps its duration).
## Returns its duration in seconds.
func _start_telegraph_of(base_seconds: float, sound: AudioStream) -> float:
	return telegraph.start(base_seconds, sound, danger.telegraph_mult)


func is_dead() -> bool:
	return _dead


## True while the lamp keeps the enemy from moving and attacking.
func is_dazzled() -> bool:
	return _dazzle_ticks_left > DAZZLE_EPSILON


## Dazzles the enemy for seconds (story 4.4): its telegraph is cancelled, its attack stops, it neither moves nor starts
## anything until the countdown ends, then it takes up its starting state (_on_dazzled()). A new dazzle restarts the
## countdown. Its contact stays live (contact is not an attack). Nothing for a dead enemy or an invalid duration.
func dazzle(seconds: float) -> void:
	if _dead or process_mode == Node.PROCESS_MODE_DISABLED or not is_finite(seconds) or seconds <= 0.0:
		return
	_dazzle_ticks_left = seconds * Engine.physics_ticks_per_second
	velocity = Vector2.ZERO
	if telegraph != null:
		telegraph.cancel()
	_sprite.self_modulate = DAZZLED_TINT
	_on_dazzled()
	Log.debug("combat", "%s dazzled for %.2fs" % [_def.id, seconds])


## Hook: back to the starting state (the only write of _state stays in _enter()). Called once per dazzle, after the
## telegraph is cancelled.
func _on_dazzled() -> void:
	pass


## Head of every _physics_process of the subclasses, after the clock scale is read: counts the dazzle down.
## Returns true while the enemy is dazzled (the caller returns at once: no move, no attack, no timer).
func _tick_dazzle(clock_scale: float) -> bool:
	if _dazzle_ticks_left <= DAZZLE_EPSILON:
		return false
	_dazzle_ticks_left -= clock_scale
	if _dazzle_ticks_left <= DAZZLE_EPSILON:
		_dazzle_ticks_left = 0.0
		_sprite.self_modulate = Color.WHITE
	return true


## Kills the enemy as a lethal hit would (debug tools, waves): disabled now, freed at the end of the frame. Once.
func kill() -> void:
	_die()


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

## The straight line: toward a point, stopping on it, never pressing on the target's body (_presses_target()).
## velocity is rewritten every tick. Without a target, callers pass _target_position() (the enemy's own position).
func _move_toward(point: Vector2, speed_px: float, clock_scale: float) -> void:
	var to: Vector2 = point - global_position
	_move_in_direction(to.normalized() if to.length_squared() >= 1e-6 else Vector2.ZERO, speed_px, clock_scale, true)


## Moves along a direction (unit vector, or zero to stand still) at speed_px per second, scaled by the clock
## and by the room pace (story 5.9): never stops on a point (a charge goes on until something stops it). move_and_slide() reports what it hit.
## spare_target: stands still instead of stepping into the target's body.
func _move_in_direction(direction: Vector2, speed_px: float, clock_scale: float, spare_target: bool = false) -> void:
	if spare_target and _presses_target(direction, speed_px, clock_scale):
		velocity = Vector2.ZERO
		return
	velocity = direction * speed_px * clock_scale * danger.pace_mult
	move_and_slide()


## True when a step in this direction would end against the target's body already touched: pressing on a motionless
## player would make its own penetration recovery shove it (story 4.3: never toward a pit).
func _presses_target(direction: Vector2, speed_px: float, clock_scale: float) -> bool:
	if direction == Vector2.ZERO or not is_instance_valid(_target):
		return false
	var step: Vector2 = direction * speed_px * clock_scale * danger.pace_mult / Engine.physics_ticks_per_second
	return test_move(global_transform, step, _probe) and _probe.get_collider() == _target


## Chases a point (the target's position) around the obstacles (story 4.5, AR23): the straight line when it is clear,
## else the waypoints of the room's grid. The path is planned at most every Tuning.COMBAT.path_refresh_interval and
## only when the room's grid grants a slot (RoomNav.take_path_slot()): between two plans the enemy keeps its path.
## Without a valid target it stands still. Without a grid it goes straight.
func _chase(point: Vector2, speed_px: float, clock_scale: float) -> void:
	if not is_instance_valid(_target):
		velocity = Vector2.ZERO
		return
	if _nav == null:
		_move_toward(point, speed_px, clock_scale)
		return
	# A chase interrupted (dazzle, telegraph, rush...) leaves a stale path: replan as soon as it resumes.
	var frame: int = Engine.get_physics_frames()
	if frame != _last_chase_frame + 1:
		_plan_ticks_left = 0.0
		_path = PackedVector2Array()
		_path_index = 0
	_last_chase_frame = frame
	_plan_ticks_left -= clock_scale
	if _plan_ticks_left <= 0.0 and _nav.take_path_slot():
		_plan_path(point)
	var waypoint: Vector2 = _current_waypoint()
	_move_toward(waypoint if _path_index < _path.size() else point, speed_px, clock_scale)


## Straight line when clear, else the path of the grid (global coordinates, without the cell the enemy stands in).
func _plan_path(point: Vector2) -> void:
	var interval_ticks: float = Tuning.COMBAT.path_refresh_interval * Engine.physics_ticks_per_second
	var first_plan: bool = _path_start == Vector2.INF
	# The first plan is at once; the next ones are shifted by the spawn number so that enemies never plan together.
	_plan_ticks_left = interval_ticks * (1.0 + float(_stagger % PATH_STAGGER_SLOTS) / PATH_STAGGER_SLOTS) if first_plan else interval_ticks
	_path = PackedVector2Array()
	_path_index = 0
	_path_start = global_position
	var half_width: float = _path_half_width()
	var from_room: Vector2 = global_position - _nav.origin
	var to_room: Vector2 = point - _nav.origin
	if _nav.is_line_clear(from_room, to_room, half_width):
		return
	var cells: PackedVector2Array = _nav.path(from_room, to_room)
	if cells.size() > 1:
		for i: int in range(1, cells.size()):
			_path.append(cells[i] + _nav.origin)
	Log.debug("combat", "%s planned a path of %d waypoints" % [name, _path.size()])


func _path_half_width() -> float:
	return maxf(_body_size_px().x, _body_size_px().y) / 2.0 + PATH_CLEARANCE_PX


## True when the body fits along the straight segment to the point (always true without a grid).
func _has_clear_line(point: Vector2) -> bool:
	return _nav == null or _nav.is_line_clear(global_position - _nav.origin, point - _nav.origin, _path_half_width())


## The waypoint to head to, skipping the ones reached (closer than 2 px) or passed (pushed beyond along the segment).
## The caller tests _path_index against the path size afterwards (the path is used up).
func _current_waypoint() -> Vector2:
	while _path_index < _path.size():
		var waypoint: Vector2 = _path[_path_index]
		var previous: Vector2 = _path[_path_index - 1] if _path_index > 0 else _path_start
		var to: Vector2 = waypoint - global_position
		if to.length_squared() < WAYPOINT_REACHED_PX * WAYPOINT_REACHED_PX or to.dot(waypoint - previous) <= 0.0:
			_path_index += 1
			continue
		return waypoint
	return global_position


func _body_size_px() -> Vector2:
	var rectangle: RectangleShape2D = _body.shape as RectangleShape2D
	return rectangle.size if rectangle != null else Vector2.ONE


func _target_position() -> Vector2:
	return _target.global_position if is_instance_valid(_target) else global_position


## Pushes the body back along direction (unit vector) by up to distance_px, stopped by the first wall or body.
## Instant, interrupts no attack in progress. Returns the distance really covered.
func knock_back(direction: Vector2, distance_px: float) -> float:
	if _dead or distance_px <= 0.0 or direction.length_squared() < 1e-6:
		return 0.0
	var start: Vector2 = global_position
	move_and_collide(direction.normalized() * distance_px)
	return start.distance_to(global_position)


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
