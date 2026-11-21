class_name BulletManager
extends Node2D
## Data-oriented bullet manager (ADR-001): one per camp, no node per bullet.
## Bullets live in fixed-size parallel arrays with a free-slot stack, and are drawn by one
## MultiMeshInstance2D per appearance. Positions are local to this node, which must sit at the
## origin of the scene together with the solid TileMapLayers passed to setup().
## Hurtboxes of the opposite camp are registered by the room that creates them (register_hurtbox()):
## a bullet that overlaps one is freed and its damage is delivered through Hurtbox.receive().
## Never log from the update loops: counters are shown by the F3 overlay.

enum Camp { ENEMY, PLAYER }

## Appearance indices are stored in a PackedByteArray.
const MAX_APPEARANCES: int = 256

const FLAG_ACTIVE: int = 1
## Reserved for the graze and perfect dash rules of epic 2 (pattern P2).
const FLAG_COUNTED: int = 2

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
var _render_counts: PackedInt32Array = PackedInt32Array()

## Registered targets, in registration order: a bullet hits the first one it overlaps.
var _targets: Array[Hurtbox] = []
## Rect of each target in this node's space, refreshed once per tick (reused, never reallocated per tick).
var _target_rects: Array[Rect2] = []
## Hits of the current tick, delivered after the bullet loop (reused lists).
var _hit_targets: Array[Hurtbox] = []
var _hit_amounts: PackedFloat32Array = PackedFloat32Array()
var _hit_directions: PackedVector2Array = PackedVector2Array()


## Dependency injection: call before add_child(). The layers (Walls, HighObstacles) stop bullets.
func setup(solid_layers: Array[TileMapLayer]) -> void:
	_solid_layers = solid_layers


func _ready() -> void:
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


## Registers a look (one MultiMeshInstance2D) and returns its index for BulletParams.appearance.
func add_appearance(texture: Texture2D) -> int:
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
	add_child(view)
	_multimeshes.append(multimesh)
	_render_counts.append(0)
	return _multimeshes.size() - 1


## Adds a hurtbox of the opposite camp to the hit tests. It unregisters itself when it leaves the tree.
func register_hurtbox(hurtbox: Hurtbox) -> void:
	var problem: String = ""
	if hurtbox == null:
		problem = "no hurtbox"
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
## Returns false, without error or log, when the pool is full (the refusal is counted).
func fire(params: BulletParams, origin: Vector2, direction: Vector2) -> bool:
	if not _is_shot_valid(params, direction):
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
	elif not is_finite(params.damage) or params.damage < 0.0:
		problem = "damage %s must be finite and not negative" % params.damage
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
	if not _hit_targets.is_empty():
		_deliver_hits()


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
	for t: int in _targets.size():
		var rect: Rect2 = _targets[t].world_rect()
		rect.position = to_local(rect.position) # the manager sits at the origin, unscaled
		_target_rects[t] = rect


## Circle against rectangle, in registration order: one bullet hits at most one target (no pierce before epic 5).
## Records the hit for _deliver_hits(); never calls a target during the loop.
func _test_targets(i: int) -> bool:
	var pos: Vector2 = _positions[i]
	var radius_sq: float = _radii[i] * _radii[i]
	for t: int in _target_rects.size():
		var rect: Rect2 = _target_rects[t]
		if rect.size == Vector2.ZERO:
			continue
		var closest: Vector2 = Vector2(
			clampf(pos.x, rect.position.x, rect.end.x), clampf(pos.y, rect.position.y, rect.end.y)
		)
		if pos.distance_squared_to(closest) <= radius_sq:
			_hit_targets.append(_targets[t])
			_hit_amounts.append(_damages[i])
			_hit_directions.append(_velocities[i].normalized())
			return true
	return false


## After the loop: a receive() that frees its target must not touch the arrays being iterated.
func _deliver_hits() -> void:
	for h: int in _hit_targets.size():
		var target: Hurtbox = _hit_targets[h]
		# PLAYER_SHOT is the only source so far: the enemy camp adds its own with epic 2.
		if is_instance_valid(target):
			target.receive(DamageInfo.from_bullet(_hit_amounts[h], _hit_directions[h], DamageInfo.Source.PLAYER_SHOT))
	_hit_targets.clear()
	_hit_amounts.clear()
	_hit_directions.clear()


func _hits_solid(pos: Vector2) -> bool:
	for layer: TileMapLayer in _solid_layers:
		if layer.get_cell_source_id(layer.local_to_map(pos)) != -1:
			return true
	return false


func _free(i: int) -> void:
	assert(_flags[i] & FLAG_ACTIVE != 0, "Slot freed twice")
	_flags[i] = 0
	_free_slots[_free_top] = i
	_free_top += 1
	active_count -= 1
