class_name BulletManager
extends Node2D
## Data-oriented bullet manager (ADR-001): one per camp, no node per bullet.
## Bullets live in fixed-size parallel arrays with a free-slot stack, and are drawn by one
## MultiMeshInstance2D per appearance. Positions are local to this node, which must sit at the
## origin of the scene together with the solid TileMapLayers passed to setup().
## Never log from the update loops: counters are shown by the F3 overlay.

enum Camp { ENEMY, PLAYER }

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

var _multimeshes: Array[MultiMesh] = []
var _render_counts: PackedInt32Array = PackedInt32Array()


## Dependency injection: call before add_child(). The layers (Walls, HighObstacles) stop bullets.
func setup(solid_layers: Array[TileMapLayer]) -> void:
	_solid_layers = solid_layers


func _ready() -> void:
	assert(position == Vector2.ZERO, "BulletManager must sit at the scene origin")
	for layer: TileMapLayer in _solid_layers:
		assert(layer.position == Vector2.ZERO, "Solid layers must share the BulletManager origin")
	_clock_group = (
		GameClock.Group.ENEMY_BULLETS if camp == Camp.ENEMY else GameClock.Group.PLAYER_BULLETS
	)
	_positions.resize(capacity)
	_velocities.resize(capacity)
	_radii.resize(capacity)
	_lifetimes.resize(capacity)
	_flags.resize(capacity)
	_appearances.resize(capacity)
	_free_slots.resize(capacity)
	for i: int in capacity:
		_free_slots[i] = capacity - 1 - i # pops give slot 0 first
	_free_top = capacity
	add_to_group(Const.GROUP_BULLET_MANAGERS)


## Registers a look (one MultiMeshInstance2D) and returns its index for BulletParams.appearance.
func add_appearance(texture: Texture2D) -> int:
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


## Fires one bullet. origin is in this node's local space, direction must be normalized.
## Returns false, without error or log, when the pool is full (the refusal is counted).
func fire(params: BulletParams, origin: Vector2, direction: Vector2) -> bool:
	if params == null or params.appearance < 0 or params.appearance >= _multimeshes.size():
		Log.error("combat", "fire() called without valid params or appearance")
		assert(false, "Invalid BulletParams")
		return false
	assert(is_equal_approx(direction.length_squared(), 1.0), "Bullet direction must be normalized")
	if _free_top == 0:
		refused_count += 1
		return false
	var speed: float = params.speed * Const.TILE_SIZE
	assert(speed / Engine.physics_ticks_per_second < Const.TILE_SIZE, "Bullet fast enough to cross a tile in one tick")
	_free_top -= 1
	var i: int = _free_slots[_free_top]
	_positions[i] = origin
	_velocities[i] = direction * speed
	_radii[i] = params.radius * Const.TILE_SIZE
	_lifetimes[i] = params.lifetime
	_flags[i] = FLAG_ACTIVE
	_appearances[i] = params.appearance
	_high_water = maxi(_high_water, i + 1)
	active_count += 1
	return true


func _physics_process(delta: float) -> void:
	var step: float = delta * GameClock.scale(_clock_group) # one read per tick
	if step <= 0.0:
		return
	for i: int in _high_water:
		if _flags[i] & FLAG_ACTIVE == 0:
			continue
		_positions[i] += _velocities[i] * step
		_lifetimes[i] -= step
		if _lifetimes[i] <= 0.0 or _hits_solid(_positions[i]):
			_free(i)


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


func _hits_solid(pos: Vector2) -> bool:
	for layer: TileMapLayer in _solid_layers:
		if layer.get_cell_source_id(layer.local_to_map(pos)) != -1:
			return true
	return false


func _free(i: int) -> void:
	_flags[i] = 0
	_free_slots[_free_top] = i
	_free_top += 1
	active_count -= 1
