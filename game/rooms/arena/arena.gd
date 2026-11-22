class_name Arena
extends Node2D
## One-screen room: 36x19 playable tiles inside a closed wall frame, a fixed camera, the player's
## BulletManager, the enemy BulletManager (it hits the player's hurtbox), training targets and the enemies.
## Enemies appear only through spawn_enemy() (group "room" lets debug tools find the active room); none at launch.
## The room counts them alive until they leave the tree.
## Floor and Walls are built in code for now (same node names as the painted rooms of epic 4).
## The player is given by the Run through setup() (it is the parent of the room, not a child).
## World origin = top-left corner of the wall frame, in pixels.

const WALL_COLOR: Color = Color(0.35, 0.3, 0.55)
const FLOOR_COLOR: Color = Color(0.09, 0.09, 0.16)
const FLOOR_ALT_COLOR: Color = Color(0.10, 0.10, 0.18)
## Technical pool size of the player's shots (~11 in flight at 4/s over 36 tiles at 14 tiles/s).
const PLAYER_BULLET_CAPACITY: int = 128

## Technical pool size of the enemy bullets, same as the load test (F5).
const ENEMY_BULLET_CAPACITY: int = 512

## Technical margin between the playable area and a spawn position, in tiles: no body against a wall.
const SPAWN_MARGIN_TILES: int = 1
## Rounding tolerance when comparing a spawn distance to the minimal one, in pixels (exactly 3 tiles is accepted).
const SPAWN_DISTANCE_EPSILON: float = 1e-3
## Clearance kept between two bodies at spawn, in pixels: two enemies never appear touching or stacked.
const SPAWN_BODY_MARGIN: float = 1.0
## Replacement candidates around a refused request: rings of 1 to this many tiles, in the 8 directions below.
const SPAWN_RING_COUNT: int = 4
const SPAWN_RING_DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0), Vector2(0.70710678, 0.70710678), Vector2(0, 1), Vector2(-0.70710678, 0.70710678),
	Vector2(-1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0, -1), Vector2(0.70710678, -0.70710678),
]

@onready var _floor: TileMapLayer = %Floor
@onready var _walls: TileMapLayer = %Walls
var _player: Player

@onready var _camera: Camera2D = %Camera
@onready var _targets: Node2D = %Targets
@onready var _enemies: Node2D = %Enemies
var _player_bullets: BulletManager
var _alive: int = 0


## Dependency injection: call before add_child().
func setup(player: Player) -> void:
	_player = player


func _ready() -> void:
	add_to_group(Const.GROUP_ROOM)
	if _player == null:
		Log.error("room", "arena added without setup()")
		assert(false, "Arena.setup() must be called before add_child()")
	if OS.is_debug_build():
		_check_screen_layout()
	var frame_cells: Vector2i = Const.ROOM_TILES + Vector2i(2, 2)
	var frame_px: Vector2 = Vector2(frame_cells * Const.TILE_SIZE)

	_floor.z_index = Const.Z_INDEX_DECOR
	_walls.z_index = Const.Z_INDEX_DECOR
	_build_tiles(frame_cells)
	_setup_player_bullets() # after the tiles: the BulletManager needs Walls to have a TileSet
	_setup_enemy_bullets() # drawn above the player's shots
	_setup_damage_numbers() # after the bullets: drawn above them

	# Fixed camera: centered on the room, shifted up by half the HUD band so the band stays free at the top.
	_camera.position = frame_px / 2.0 - Vector2(0.0, Const.HUD_BAND_HEIGHT / 2.0)
	_camera.reset_physics_interpolation()

	Log.info("room", "arena ready playable=%s tiles" % Const.ROOM_TILES)


## Spawns an enemy: the only way (architecture, "Création d'entités"). requested: room coordinates (the room
## sits at the world origin). Closer than Tuning.COMBAT.min_spawn_distance to the player, outside the playable
## area, or on top of a living enemy: replaced by the nearest valid position (deterministic, no RNG before epic 4).
## Returns null when it cannot spawn (Log.error).
func spawn_enemy(def: EnemyDef, requested: Vector2) -> Enemy:
	if not is_node_ready():
		Log.error("room", "spawn_enemy called before the room is ready")
		_assert_failed("spawn_enemy() before the room is ready")
		return null
	if def == null or def.scene == null or _player == null:
		Log.error("room", "spawn_enemy needs a def with a scene and a player")
		_assert_failed("spawn_enemy() without def, scene or player")
		return null
	var position_px: Vector2 = _resolve_spawn_position(def, requested)
	if not is_finite(position_px.x) or not is_finite(position_px.y):
		Log.error("room", "no valid spawn position for %s" % def.id)
		_assert_failed("spawn_enemy() found no valid position")
		return null
	var node: Node = def.scene.instantiate()
	var enemy: Enemy = node as Enemy
	if enemy == null:
		node.free() # never leak a refused instance
		Log.error("room", "scene of %s is not an Enemy" % def.id)
		_assert_failed("EnemyDef.scene must have an Enemy root")
		return null
	enemy.setup(def, _player, _player.hurtbox) # before add_child()
	enemy.position = position_px
	_enemies.add_child(enemy)
	if enemy.hurtbox == null or enemy.process_mode == Node.PROCESS_MODE_DISABLED:
		# Its _ready() failed: never counted, registered nor left visible and hittable.
		Log.error("room", "spawn of %s refused: enemy setup failed" % def.id)
		enemy.queue_free()
		_assert_failed("enemy setup failed")
		return null
	enemy.reset_physics_interpolation() # it does not trail from (0, 0)
	if _player_bullets != null:
		_player_bullets.register_hurtbox(enemy.hurtbox)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited, CONNECT_ONE_SHOT)
	Log.debug("room", "spawned %s at %s alive=%d" % [def.id, position_px, _alive])
	return enemy


## Enemies spawned by this room and still in the tree (dead ones leave at the end of their frame).
func alive_enemy_count() -> int:
	return _alive


## Where the player enters the arena (center of the playable area), in global coordinates.
func player_spawn_position() -> Vector2:
	var frame_px: Vector2 = Vector2((Const.ROOM_TILES + Vector2i(2, 2)) * Const.TILE_SIZE)
	return to_global(frame_px / 2.0)


## The player's BulletManager, at the room origin like Walls. Added last: drawn above the player (Combat layer).
func _setup_player_bullets() -> void:
	var bullets: BulletManager = BulletManager.new()
	_player_bullets = bullets
	bullets.name = "PlayerBullets"
	bullets.camp = BulletManager.Camp.PLAYER
	bullets.capacity = PLAYER_BULLET_CAPACITY
	var solid_layers: Array[TileMapLayer] = [_walls]
	bullets.setup(solid_layers) # before add_child()
	add_child(bullets)
	# The targets do not need the player: register them even when setup() was skipped.
	for child: Node in _targets.get_children():
		var target: TrainingTarget = child as TrainingTarget
		if target != null:
			bullets.register_hurtbox(target.hurtbox)
	if _player != null:
		_player.equip_bullets(bullets)


## The enemy BulletManager, at the room origin. It has no look: whoever fires adds its own appearance.
func _setup_enemy_bullets() -> void:
	var bullets: BulletManager = BulletManager.new()
	bullets.name = "EnemyBullets"
	bullets.camp = BulletManager.Camp.ENEMY
	bullets.capacity = ENEMY_BULLET_CAPACITY
	var solid_layers: Array[TileMapLayer] = [_walls]
	bullets.setup(solid_layers) # before add_child()
	add_child(bullets)
	if _player != null:
		bullets.register_hurtbox(_player.hurtbox)


## Playable area in pixels (cells 1 to 36 by 1 to 19), shrunk by SPAWN_MARGIN_TILES so a body never appears
## against a wall.
func _spawn_bounds() -> Rect2:
	var margin: float = (1 + SPAWN_MARGIN_TILES) * Const.TILE_SIZE
	var playable: Vector2 = Vector2(Const.ROOM_TILES * Const.TILE_SIZE)
	return Rect2(Vector2.ONE * margin, playable - Vector2.ONE * SPAWN_MARGIN_TILES * 2.0 * Const.TILE_SIZE)


## requested if valid (inside the bounds, at least min_spawn_distance from the player, clear of living bodies), else
## the valid candidate nearest to it. Candidates, in this order (a tie keeps the earlier one): the request clamped to
## the bounds, that point pushed out to the minimal distance, rings of 1 to 4 tiles around it (8 directions), the
## player-centered point pushed out toward the request, the corners of the bounds.
## A request that is not finite is refused (Log.error + assert) and treated as "to the right of the player": the
## candidates keep their order, no distance is computed.
## Returns Vector2(INF, INF) when no candidate is valid.
func _resolve_spawn_position(def: EnemyDef, requested: Vector2) -> Vector2:
	var bounds: Rect2 = _spawn_bounds()
	var player_pos: Vector2 = to_local(_player.global_position)
	var min_px: float = Tuning.COMBAT.min_spawn_distance * Const.TILE_SIZE
	var body_px: Vector2 = def.body_size * Const.TILE_SIZE
	var request_finite: bool = is_finite(requested.x) and is_finite(requested.y)
	var anchor: Vector2 = requested
	if not request_finite:
		Log.error("room", "spawn request %s is not finite, treated as refused" % requested)
		_assert_failed("spawn_enemy() needs a finite position")
		anchor = player_pos + Vector2.RIGHT * min_px
	if request_finite and _is_valid_spawn(requested, bounds, player_pos, min_px, body_px):
		return requested
	var clamped: Vector2 = anchor.clamp(bounds.position, bounds.end)
	var candidates: Array[Vector2] = [clamped, _pushed_from_player(clamped, player_pos, min_px)]
	for ring: int in range(1, SPAWN_RING_COUNT + 1):
		for direction: Vector2 in SPAWN_RING_DIRECTIONS:
			candidates.append(clamped + direction * ring * Const.TILE_SIZE)
	candidates.append(_pushed_from_player(anchor, player_pos, min_px))
	candidates.append(bounds.position)
	candidates.append(Vector2(bounds.end.x, bounds.position.y))
	candidates.append(Vector2(bounds.position.x, bounds.end.y))
	candidates.append(bounds.end)
	var best: Vector2 = Vector2(INF, INF)
	var best_distance: float = INF
	for candidate: Vector2 in candidates:
		if not _is_valid_spawn(candidate, bounds, player_pos, min_px, body_px):
			continue
		if not request_finite:
			best = candidate # list order
			break
		var distance: float = candidate.distance_to(requested)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if is_finite(best.x):
		Log.debug("room", "spawn at %s refused (too close, outside or occupied), moved to %s" % [requested, best])
	return best


## The point moved radially away from the player until it is min_px from it (unchanged when already far enough).
func _pushed_from_player(point: Vector2, player_pos: Vector2, min_px: float) -> Vector2:
	var away: Vector2 = point - player_pos
	if away.length() >= min_px:
		return point
	var direction: Vector2 = away.normalized() if away.length_squared() > 1e-6 else Vector2.RIGHT
	return player_pos + direction * min_px


func _is_valid_spawn(point: Vector2, bounds: Rect2, player_pos: Vector2, min_px: float, body_px: Vector2) -> bool:
	var inside: bool = point.x >= bounds.position.x and point.x <= bounds.end.x \
		and point.y >= bounds.position.y and point.y <= bounds.end.y # inclusive: the corners are valid
	if not inside or point.distance_to(player_pos) < min_px - SPAWN_DISTANCE_EPSILON:
		return false
	return not _overlaps_living_enemy(Rect2(point - body_px / 2.0, body_px).grow(SPAWN_BODY_MARGIN))


## True when the rectangle (room coordinates) touches the body of an enemy that is alive and not being freed.
func _overlaps_living_enemy(rect: Rect2) -> bool:
	for child: Node in _enemies.get_children():
		var other: Enemy = child as Enemy
		if other == null or other.is_dead() or other.is_queued_for_deletion():
			continue
		var other_rect: Rect2 = other.body_world_rect()
		other_rect.position = to_local(other_rect.position)
		if rect.intersects(other_rect):
			return true
	return false


func _on_enemy_tree_exited() -> void:
	_alive = maxi(_alive - 1, 0)


## A failed assert aborts the function it is in (debug builds): kept apart so the caller carries on (AR28).
func _assert_failed(message: String) -> void:
	assert(false, message)


## Damage numbers layer, at the room origin. Added after PlayerBullets: drawn above the shots.
func _setup_damage_numbers() -> void:
	var numbers: DamageNumbers = DamageNumbers.new()
	numbers.name = "DamageNumbers"
	add_child(numbers)


## The room (walls included) plus the HUD band must fit the viewport exactly in height, with a margin in width.
func _check_screen_layout() -> void:
	var height_ok: bool = Const.VIEWPORT.y - Const.HUD_BAND_HEIGHT == (Const.ROOM_TILES.y + 2) * Const.TILE_SIZE
	var width_margin: int = Const.VIEWPORT.x - (Const.ROOM_TILES.x + 2) * Const.TILE_SIZE
	if not height_ok or width_margin < 0:
		Log.error("room", "arena does not fit the viewport (height_ok=%s width_margin=%d)" % [height_ok, width_margin])
		assert(false, "Arena layout out of sync with Const")


func _build_tiles(frame_cells: Vector2i) -> void:
	var tile_size: Vector2i = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = tile_size
	# The physics layer must exist before the sources join the TileSet: a TileData created earlier would not know it.
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, Const.LAYER_WALLS)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var wall_source: TileSetAtlasSource = _make_source(_solid_image(WALL_COLOR), tile_size)
	var floor_source: TileSetAtlasSource = _make_source(_checker_image(), tile_size)
	var wall_id: int = tile_set.add_source(wall_source)
	var floor_id: int = tile_set.add_source(floor_source)

	# Collision square of a wall tile, relative to the tile center.
	var half: float = Const.TILE_SIZE / 2.0
	var wall_data: TileData = wall_source.get_tile_data(Vector2i.ZERO, 0)
	wall_data.add_collision_polygon(0)
	wall_data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	]))

	_floor.tile_set = tile_set
	_walls.tile_set = tile_set
	for y: int in range(1, frame_cells.y - 1):
		for x: int in range(1, frame_cells.x - 1):
			_floor.set_cell(Vector2i(x, y), floor_id, Vector2i.ZERO)
	for x: int in frame_cells.x:
		_walls.set_cell(Vector2i(x, 0), wall_id, Vector2i.ZERO)
		_walls.set_cell(Vector2i(x, frame_cells.y - 1), wall_id, Vector2i.ZERO)
	for y: int in frame_cells.y:
		_walls.set_cell(Vector2i(0, y), wall_id, Vector2i.ZERO)
		_walls.set_cell(Vector2i(frame_cells.x - 1, y), wall_id, Vector2i.ZERO)


## Order matters: texture, then region size, then create_tile.
func _make_source(image: Image, tile_size: Vector2i) -> TileSetAtlasSource:
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = tile_size
	source.create_tile(Vector2i.ZERO)
	return source


func _solid_image(color: Color) -> Image:
	var image: Image = Image.create(Const.TILE_SIZE, Const.TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(color)
	return image


## Barely visible checkerboard (2x2 blocks of 8 px) to judge movement on the floor.
@warning_ignore("integer_division")
func _checker_image() -> Image:
	var image: Image = _solid_image(FLOOR_COLOR)
	var block: int = Const.TILE_SIZE / 2
	for y: int in Const.TILE_SIZE:
		for x: int in Const.TILE_SIZE:
			if (x / block + y / block) % 2 == 1:
				image.set_pixel(x, y, FLOOR_ALT_COLOR)
	return image
