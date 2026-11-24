class_name BulletManager
extends Node2D
## Data-oriented bullet manager (ADR-001): one per camp, no node per bullet.
## Bullets live in fixed-size parallel arrays with a free-slot stack, and are drawn by one
## MultiMeshInstance2D per appearance. Positions are local to this node, which must sit at the
## origin of the scene together with the solid TileMapLayers passed to setup().
## Hurtboxes of the opposite camp are registered by the room that creates them (register_hurtbox()):
## a bullet that overlaps one that can be hit is freed and its damage is delivered through Hurtbox.receive().
## Ticks after the entities (Const.PHYSICS_PRIORITY_BULLETS): hit tests read this tick's state of the hurtboxes.
## Never log from the update loops: counters are shown by the F3 overlay.

## A bullet passed close to the graze hurtbox without touching it (position: global). Emitted after the bullet loop.
signal grazed(position: Vector2)
## The graze hurtbox was evading (dash invulnerability) while a bullet overlapped it. The bullet is not freed.
signal dodged(position: Vector2)

enum Camp { ENEMY, PLAYER }

## Appearance indices are stored in a PackedByteArray.
const MAX_APPEARANCES: int = 256

const FLAG_ACTIVE: int = 1
## The bullet already paid its graze (pattern P2).
const FLAG_COUNTED: int = 2
## The bullet already paid its perfect dash: counted per bullet, never per dash. It also sets FLAG_COUNTED.
const FLAG_DODGED: int = 4

@export var camp: Camp = Camp.ENEMY
## Fixed pool size. Set before add_child().
@export var capacity: int = 512

## Bullets currently alive.
var active_count: int = 0
## Shots refused because the pool was full, since the start.
var refused_count: int = 0

var _clock_group: GameClock.Group = GameClock.Group.ENEMY_BULLETS
var _solid_layers: Array[TileMapLayer] = []

var _positions: PackedVector2Array = PackedVector2Array()
var _velocities: PackedVector2Array = PackedVector2Array() # pixels per second
var _radii: PackedFloat32Array = PackedFloat32Array() # pixels
var _lifetimes: PackedFloat32Array = PackedFloat32Array() # seconds left
var _flags: PackedByteArray = PackedByteArray()
var _appearances: PackedByteArray = PackedByteArray()
var _free_slots: PackedInt32Array = PackedInt32Array()
var _free_top: int = 0
## 1 + the highest slot ever used: upper bound of every loop.
var _high_water: int = 0

var _damages: PackedFloat32Array = PackedFloat32Array()

var _multimeshes: Array[MultiMesh] = []
## Texture of each look, same index as _multimeshes: the same texture is never registered twice.
var _appearance_textures: Array[Texture2D] = []
var _render_counts: PackedInt32Array = PackedInt32Array()

## Registered targets, in registration order: a bullet hits the first one it overlaps.
var _targets: Array[Hurtbox] = []
## Rect of each target in this node's space, refreshed once per tick (reused, never reallocated per tick).
var _target_rects: Array[Rect2] = []
## is_hittable() of each target, read once per tick (reused). A one_hit_per_tick target turns false after its hit.
var _target_hittable: Array[bool] = []
## Hits of the current tick, delivered after the bullet loop (reused lists). Targets are kept by instance id:
## a receive() may free a target that a later hit of the same tick still names.
var _hit_target_ids: PackedInt64Array = PackedInt64Array()
var _hit_amounts: PackedFloat32Array = PackedFloat32Array()
var _hit_directions: PackedVector2Array = PackedVector2Array()

## Graze (story 3.2): the watched target, its index in _targets (-1 = none) and the margin around its rectangle.
var _graze_hurtbox: Hurtbox
var _graze_index: int = -1
var _graze_radius_px: float = 0.0
var _graze_evading: bool = false
var _graze_zone: Rect2 = Rect2() # the target rect grown by the graze radius, this tick
## Graze and dodge positions of the current tick, delivered after the loop (reused lists).
var _grazed_positions: PackedVector2Array = PackedVector2Array()
var _dodged_positions: PackedVector2Array = PackedVector2Array()


## Dependency injection: call before add_child(). The layers (Walls, HighObstacles) stop bullets.
func setup(solid_layers: Array[TileMapLayer]) -> void:
	_solid_layers = solid_layers


func _ready() -> void:
	process_physics_priority = Const.PHYSICS_PRIORITY_BULLETS
	assert(capacity > 0, "BulletManager capacity must be positive")
	capacity = maxi(capacity, 1)
	assert(position == Vector2.ZERO, "BulletManager must sit at the scene origin")
	for layer: TileMapLayer in _solid_layers:
		assert(layer.position == Vector2.ZERO, "Solid layers must share the BulletManager origin")
		assert(layer.tile_set != null, "Solid layers need a TileSet (local_to_map is wrong without one)")
		assert(
			layer.tile_set.tile_size == Vector2i(Const.TILE_SIZE, Const.TILE_SIZE),
			"Solid layer tile size must equal Const.TILE_SIZE"
		)
	_clock_group = (
		GameClock.Group.ENEMY_BULLETS if camp == Camp.ENEMY else GameClock.Group.PLAYER_BULLETS
	)
	_positions.resize(capacity)
	_velocities.resize(capacity)
	_radii.resize(capacity)
	_lifetimes.resize(capacity)
	_flags.resize(capacity)
	_appearances.resize(capacity)
	_damages.resize(capacity)
	_free_slots.resize(capacity)
	for i: int in capacity:
		_free_slots[i] = capacity - 1 - i # pops give slot 0 first
	_free_top = capacity
	add_to_group(Const.GROUP_BULLET_MANAGERS)


## Watches a registered hurtbox for grazes and dodges: a bullet whose center passes within radius_tiles of its
## rectangle emits grazed once; one that overlaps it while it is evading emits dodged once (see Hurtbox.is_evading()).
func enable_graze(hurtbox: Hurtbox, radius_tiles: float) -> void:
	if hurtbox == null or not _targets.has(hurtbox) or not (radius_tiles > 0.0):
		Log.error("combat", "enable_graze() needs a registered hurtbox and a positive radius")
		assert(false, "Invalid graze setup")
		return
	_graze_hurtbox = hurtbox
	_graze_radius_px = radius_tiles * Const.TILE_SIZE
	hurtbox.show_graze_zone(_graze_radius_px)

## Registers a look (one MultiMeshInstance2D) and returns its index for BulletParams.appearance.
## The same Texture2D registered again returns its first index: one MultiMeshInstance2D per look, whatever the
## number of shooters.
func add_appearance(texture: Texture2D) -> int:
	if texture != null:
		var known: int = _appearance_textures.find(texture)
		if known != -1:
			return known
	if texture == null or _multimeshes.size() >= MAX_APPEARANCES:
		Log.error("combat", "add_appearance() needs a texture and at most %d appearances" % MAX_APPEARANCES)
		assert(false, "Invalid appearance")
		return -1
	var quad: QuadMesh = QuadMesh.new()
	quad.size = texture.get_size()
	var multimesh: MultiMesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D # must be set before instance_count
	multimesh.mesh = quad
	multimesh.instance_count = capacity
	multimesh.visible_instance_count = 0
	var view: MultiMeshInstance2D = MultiMeshInstance2D.new()
	view.multimesh = multimesh
	view.texture = texture
	# Instances are rewritten in _process and packed (instance n is not the same bullet from one frame to the
	# next): interpolating them would draw a bullet halfway to another one's position for a frame (flash artifacts).
	view.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	RenderingServer.multimesh_set_physics_interpolated(multimesh.get_rid(), false)
	add_child(view)
	_multimeshes.append(multimesh)
	_appearance_textures.append(texture)
	_render_counts.append(0)
	return _multimeshes.size() - 1


## True when this hurtbox is registered (register_hurtbox()) and still in the hit tests.
func has_hurtbox(hurtbox: Hurtbox) -> bool:
	return _targets.has(hurtbox)


## Adds a hurtbox of the opposite camp to the hit tests. It unregisters itself when it leaves the tree.
func register_hurtbox(hurtbox: Hurtbox) -> void:
	var problem: String = ""
	if hurtbox == null:
		problem = "no hurtbox"
	elif not hurtbox.is_inside_tree():
		# Freed without ever entering the tree, it would never emit tree_exiting and never unregister.
		problem = "hurtbox %s is not in the scene tree" % hurtbox.name
	elif hurtbox.camp == camp:
		problem = "hurtbox %s is in the same camp as the bullets" % hurtbox.get_path()
	elif _targets.has(hurtbox):
		problem = "hurtbox %s is already registered" % hurtbox.get_path()
	if not problem.is_empty():
		Log.error("combat", "register_hurtbox() refused: %s" % problem)
		assert(false, "Invalid hurtbox registration: %s" % problem)
		return
	_targets.append(hurtbox)
	hurtbox.tree_exiting.connect(unregister_hurtbox.bind(hurtbox), CONNECT_ONE_SHOT)


func unregister_hurtbox(hurtbox: Hurtbox) -> void:
	var index: int = _targets.find(hurtbox)
	if index == -1:
		return
	_targets.remove_at(index)
	var callback: Callable = unregister_hurtbox.bind(hurtbox)
	if hurtbox.tree_exiting.is_connected(callback):
		hurtbox.tree_exiting.disconnect(callback)


## Fires one bullet. origin is in this node's local space, direction must be normalized.
## Returns false, without error or log, when the pool is full (the refusal is counted) or when the origin is inside
## a solid cell (the wall would stop it at once). Returns false with an error for an invalid shot, including a
## damage its target would refuse (ENEMY camp: at least 1 half-heart after rounding; PLAYER camp: > 0).
func fire(params: BulletParams, origin: Vector2, direction: Vector2) -> bool:
	if not _is_shot_valid(params, direction):
		return false
	if _hits_solid(origin):
		return false
	if _free_top == 0:
		refused_count += 1
		return false
	var speed: float = params.speed * Const.TILE_SIZE
	_free_top -= 1
	var i: int = _free_slots[_free_top]
	_positions[i] = origin
	_velocities[i] = direction * speed
	_radii[i] = params.radius * Const.TILE_SIZE
	_lifetimes[i] = params.lifetime
	_flags[i] = FLAG_ACTIVE
	_appearances[i] = params.appearance
	_damages[i] = params.damage
	_high_water = maxi(_high_water, i + 1)
	active_count += 1
	return true


## Invariants of a shot. Checked in release too (AR28): a bad shot is refused and logged, never fired.
## The speed limit keeps a bullet from crossing a whole tile in one tick: walls are tested at one point per tick.
func _is_shot_valid(params: BulletParams, direction: Vector2) -> bool:
	var problem: String = ""
	if not is_node_ready():
		problem = "BulletManager is not in the tree yet"
	elif params == null:
		problem = "no BulletParams"
	elif params.appearance < 0 or params.appearance >= _multimeshes.size():
		problem = "unknown appearance %d" % params.appearance
	elif not (params.speed > 0.0) or params.speed * Const.TILE_SIZE / Engine.physics_ticks_per_second >= Const.TILE_SIZE:
		problem = "speed %s tiles/s is not in (0, one tile per tick)" % params.speed
	elif not is_finite(params.lifetime) or params.lifetime <= 0.0:
		problem = "lifetime %s must be finite and positive" % params.lifetime
	elif not (params.radius >= 0.0):
		problem = "radius %s must not be negative" % params.radius
	elif not is_finite(params.damage):
		problem = "damage %s must be finite" % params.damage
	elif camp == Camp.ENEMY and roundi(params.damage) < 1:
		# Same rule as Health.apply_damage(): the player counts whole half-hearts (story 2.4, reports of 2.1 and 2.3).
		problem = "damage %s would be refused by the player's Health (at least 1 half-heart after rounding)" % params.damage
	elif camp == Camp.PLAYER and params.damage <= 0.0:
		problem = "damage %s would be refused by the enemies' HitPoints (must be > 0)" % params.damage
	elif not is_equal_approx(direction.length_squared(), 1.0):
		problem = "direction %s is not normalized" % direction
	if problem.is_empty():
		return true
	Log.error("combat", "shot refused: %s" % problem)
	assert(false, "Invalid shot: %s" % problem)
	return false


func _physics_process(delta: float) -> void:
	var step: float = delta * GameClock.scale(_clock_group) # one read per tick
	if step <= 0.0:
		return
	var target_count: int = _targets.size()
	if target_count > 0:
		_refresh_target_rects()
	for i: int in _high_water:
		if _flags[i] & FLAG_ACTIVE == 0:
			continue
		_positions[i] += _velocities[i] * step
		_lifetimes[i] -= step
		# Targets before walls: a shot that reaches a target standing against a wall still counts.
		if target_count > 0 and _test_targets(i):
			_free(i)
		elif _lifetimes[i] <= 0.0 or _hits_solid(_positions[i]):
			_free(i)
	if not _hit_target_ids.is_empty():
		_deliver_hits()
	if not _grazed_positions.is_empty() or not _dodged_positions.is_empty():
		_deliver_graze()


func _process(_delta: float) -> void:
	if _multimeshes.is_empty():
		return
	_render_counts.fill(0)
	for i: int in _high_water:
		if _flags[i] & FLAG_ACTIVE == 0:
			continue
		var appearance: int = _appearances[i]
		var n: int = _render_counts[appearance]
		_multimeshes[appearance].set_instance_transform_2d(n, Transform2D(0.0, _positions[i]))
		_render_counts[appearance] = n + 1
	for a: int in _multimeshes.size():
		_multimeshes[a].visible_instance_count = _render_counts[a]


func _refresh_target_rects() -> void:
	_target_rects.resize(_targets.size())
	_target_hittable.resize(_targets.size())
	for t: int in _targets.size():
		var rect: Rect2 = _targets[t].world_rect()
		rect.position = to_local(rect.position) # the manager sits at the origin, unscaled
		_target_rects[t] = rect
		_target_hittable[t] = _targets[t].is_hittable()
	_graze_index = _targets.find(_graze_hurtbox) if _graze_hurtbox != null else -1
	if _graze_index != -1:
		_graze_evading = _graze_hurtbox.is_evading()
		_graze_zone = _target_rects[_graze_index].grow(_graze_radius_px)


## Circle against rectangle, in registration order: one bullet hits at most one target (no pierce before epic 5).
## Records the hit for _deliver_hits(); never calls a target during the loop.
func _test_targets(i: int) -> bool:
	var pos: Vector2 = _positions[i]
	var radius_sq: float = _radii[i] * _radii[i]
	for t: int in _target_rects.size():
		var rect: Rect2 = _target_rects[t]
		if rect.size == Vector2.ZERO or not _target_hittable[t]:
			continue
		if t == _graze_index and _flags[i] & FLAG_DODGED != 0:
			continue # a dodged bullet no longer hits the dodging target; it keeps flying
		var closest: Vector2 = Vector2(
			clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y)
		)
		if pos.distance_squared_to(closest) <= radius_sq:
			_hit_target_ids.append(_targets[t].get_instance_id())
			_hit_amounts.append(_damages[i])
			_hit_directions.append(_velocities[i].normalized())
			if _targets[t].one_hit_per_tick:
				_target_hittable[t] = false # the next bullets of this tick pass through
			return true
	if _graze_index != -1:
		_test_graze(i)
	return false


## Graze and dodge of one bullet that touched no target (the player's hurtbox is the only one watched).
## Evading and overlapping: dodged once per bullet. Hittable, not yet counted, within the radius and moving away from
## the rectangle: grazed once.
## A target that is neither hittable nor evading (post-hit invulnerability, already hit this tick): nothing.
func _test_graze(i: int) -> void:
	var pos: Vector2 = _positions[i]
	if not _graze_zone.has_point(pos): # cheap rejection of most bullets
		return
	var rect: Rect2 = _target_rects[_graze_index]
	var closest: Vector2 = Vector2(
		clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y)
	)
	var distance_sq: float = pos.distance_squared_to(closest)
	if _graze_evading:
		if _flags[i] & FLAG_DODGED == 0 and distance_sq <= _radii[i] * _radii[i]:
			_flags[i] |= FLAG_DODGED | FLAG_COUNTED
			_dodged_positions.append(to_global(pos))
	elif not _target_hittable[_graze_index]:
		if distance_sq <= _radii[i] * _radii[i]:
			_flags[i] |= FLAG_COUNTED # it went through the target: never a graze
	elif _flags[i] & FLAG_COUNTED == 0:
		# Counted once the bullet is moving away: one that was heading for the hurtbox either hits it or is dodged,
		# and a hit must not also pay a graze.
		if distance_sq < _graze_radius_px * _graze_radius_px and _velocities[i].dot(pos - closest) > 0.0:
			_flags[i] |= FLAG_COUNTED
			_grazed_positions.append(to_global(pos))


## After the loop: a receive() that frees its target must not touch the arrays being iterated.
## A target freed, queued for deletion (itself or its owner) or unregistered by an earlier receive() of this
## tick gets nothing more.
func _deliver_hits() -> void:
	var source: DamageInfo.Source = (
		DamageInfo.Source.PLAYER_SHOT if camp == Camp.PLAYER else DamageInfo.Source.ENEMY_BULLET
	)
	for h: int in _hit_target_ids.size():
		var target: Hurtbox = instance_from_id(_hit_target_ids[h]) as Hurtbox # null once freed
		if target == null or not _targets.has(target) or _is_being_deleted(target):
			continue
		# The result of receive() is ignored: the bullet is already freed (a target made untouchable between the
		# test and the delivery of the same tick costs one bullet, no visible effect).
		target.receive(DamageInfo.from_bullet(_hit_amounts[h], _hit_directions[h], source))
	_hit_target_ids.clear()
	_hit_amounts.clear()
	_hit_directions.clear()


## After the loop: a listener may change the lucidity tier, play sounds or free the target.
func _deliver_graze() -> void:
	var grazes: PackedVector2Array = _grazed_positions.duplicate()
	var dodges: PackedVector2Array = _dodged_positions.duplicate()
	_grazed_positions.clear()
	_dodged_positions.clear()
	for position_global: Vector2 in dodges:
		dodged.emit(position_global)
	for position_global: Vector2 in grazes:
		grazed.emit(position_global)


## queue_free() marks only the node it is called on: an entity that dies frees its root, not its Hurtbox.
## Walked per hit only, never per bullet.
func _is_being_deleted(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current.is_queued_for_deletion():
			return true
		current = current.get_parent()
	return false


func _hits_solid(pos: Vector2) -> bool:
	for layer: TileMapLayer in _solid_layers:
		if layer.get_cell_source_id(layer.local_to_map(pos)) != -1:
			return true
	return false


## Frees every active bullet at once (Awakening): no hit, no graze, no dodge. Returns how many were freed.
## Never call it from a signal of this manager (it would run inside its own loop).
func clear_all() -> int:
	var cleared: int = 0
	for i: int in _high_water:
		if _flags[i] & FLAG_ACTIVE != 0:
			_free(i)
			cleared += 1
	return cleared


func _free(i: int) -> void:
	assert(_flags[i] & FLAG_ACTIVE != 0, "Slot freed twice")
	_flags[i] = 0
	_free_slots[_free_top] = i
	_free_top += 1
	active_count -= 1
