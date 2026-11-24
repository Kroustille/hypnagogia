class_name Arena
extends Room
## The training room of milestone A: a one-screen room whose decor is built in code (same node names as the painted
## rooms of epic 4), with training targets and the looping arena waves. The logic of any room is in Room.

const WALL_COLOR: Color = Color(0.35, 0.3, 0.55)
## Placeholder obstacles until epic 4: low ones are lighter (shots pass over them), high ones darker (they stop shots).
const LOW_OBSTACLE_COLOR: Color = Color(0.42, 0.40, 0.52)
const HIGH_OBSTACLE_COLOR: Color = Color(0.20, 0.17, 0.34)
## Top-left cell (frame coordinates) of each 2x2 obstacle block, away from the spawn slots and the player start.
const LOW_OBSTACLE_CELLS: Array[Vector2i] = [Vector2i(8, 12), Vector2i(29, 5), Vector2i(16, 15)]
const HIGH_OBSTACLE_CELLS: Array[Vector2i] = [Vector2i(11, 3), Vector2i(24, 15)]
const OBSTACLE_BLOCK_CELLS: int = 2
const FLOOR_COLOR: Color = Color(0.09, 0.09, 0.16)
const FLOOR_ALT_COLOR: Color = Color(0.10, 0.10, 0.18)

## Waves of the arena (story 2.6): data, never in code.
const WAVE_LIST: WaveList = preload("res://data/waves/arena_waves.tres")

## Verification tools set this to false before creating a Run: the room then stays empty, as before story 2.6.
## Nothing in the game writes it.
static var waves_enabled: bool = true

@onready var _targets: Node2D = %Targets


func _log_name() -> String:
	return "arena"


func _build_decor(frame_cells: Vector2i) -> void:
	_build_tiles(frame_cells)


func _waves_wanted() -> bool:
	return waves_enabled


func _make_wave_list() -> WaveList:
	return WAVE_LIST


func _register_static_hurtboxes(bullets: BulletManager) -> void:
	for child: Node in _targets.get_children():
		var target: TrainingTarget = child as TrainingTarget
		if target != null:
			bullets.register_hurtbox(target.hurtbox)


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
	_high_obstacles.tile_set = _make_obstacle_set(Const.LAYER_HIGH_OBSTACLES, HIGH_OBSTACLE_COLOR, tile_size)
	_low_obstacles.tile_set = _make_obstacle_set(Const.LAYER_LOW_OBSTACLES, LOW_OBSTACLE_COLOR, tile_size)
	_place_blocks(_high_obstacles, HIGH_OBSTACLE_CELLS)
	_place_blocks(_low_obstacles, LOW_OBSTACLE_CELLS)
	for y: int in range(1, frame_cells.y - 1):
		for x: int in range(1, frame_cells.x - 1):
			_floor.set_cell(Vector2i(x, y), floor_id, Vector2i.ZERO)
	for x: int in frame_cells.x:
		_walls.set_cell(Vector2i(x, 0), wall_id, Vector2i.ZERO)
		_walls.set_cell(Vector2i(x, frame_cells.y - 1), wall_id, Vector2i.ZERO)
	for y: int in frame_cells.y:
		_walls.set_cell(Vector2i(0, y), wall_id, Vector2i.ZERO)
		_walls.set_cell(Vector2i(frame_cells.x - 1, y), wall_id, Vector2i.ZERO)


## A TileSet of one full-square tile (source 0) on its own physics layer: a TileSet gives one collision layer to
## all its tiles, so each kind of obstacle needs its own.
func _make_obstacle_set(collision_layer: int, color: Color, tile_size: Vector2i) -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = tile_size
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, collision_layer)
	tile_set.set_physics_layer_collision_mask(0, 0)
	var source: TileSetAtlasSource = _make_source(_solid_image(color), tile_size)
	tile_set.add_source(source)
	var half: float = Const.TILE_SIZE / 2.0
	var data: TileData = source.get_tile_data(Vector2i.ZERO, 0)
	data.add_collision_polygon(0)
	data.set_collision_polygon_points(0, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	]))
	return tile_set


func _place_blocks(layer: TileMapLayer, top_left_cells: Array[Vector2i]) -> void:
	for top_left: Vector2i in top_left_cells:
		for y: int in OBSTACLE_BLOCK_CELLS:
			for x: int in OBSTACLE_BLOCK_CELLS:
				layer.set_cell(top_left + Vector2i(x, y), 0, Vector2i.ZERO)


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
