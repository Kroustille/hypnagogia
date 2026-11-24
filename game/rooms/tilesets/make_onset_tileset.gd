extends SceneTree
## Writes res://rooms/tilesets/onset.tres (provisional tileset of the Onset phase). One-off tool:
##   godot --headless --path game --script res://rooms/tilesets/make_onset_tileset.gd
## Sources, in order: 0 floor, 1 wall, 2 high obstacle, 3 low obstacle, 4 pit. Physics layers 0, 1, 2 are WALLS,
## HIGH_OBSTACLES, LOW_OBSTACLES: each solid tile only has a polygon on its own layer. The pit has no collision.

const OUTPUT_PATH: String = "res://rooms/tilesets/onset.tres"
const WALL_COLOR: Color = Color(0.35, 0.3, 0.55)
const HIGH_COLOR: Color = Color(0.20, 0.17, 0.34)
const LOW_COLOR: Color = Color(0.42, 0.40, 0.52)
const FLOOR_COLOR: Color = Color(0.09, 0.09, 0.16)
const FLOOR_ALT_COLOR: Color = Color(0.10, 0.10, 0.18)
const PIT_COLOR: Color = Color(0.0, 0.0, 0.02)


func _init() -> void:
	var tile_size: Vector2i = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = tile_size
	# The physics layers must exist before the sources join the TileSet.
	var layers: Array[int] = [Const.LAYER_WALLS, Const.LAYER_HIGH_OBSTACLES, Const.LAYER_LOW_OBSTACLES]
	for index: int in layers.size():
		tile_set.add_physics_layer()
		tile_set.set_physics_layer_collision_layer(index, layers[index])
		tile_set.set_physics_layer_collision_mask(index, 0)
	var floor_source: TileSetAtlasSource = _make_source(_checker_image(), tile_size)
	var wall_source: TileSetAtlasSource = _make_source(_solid_image(WALL_COLOR), tile_size)
	var high_source: TileSetAtlasSource = _make_source(_solid_image(HIGH_COLOR), tile_size)
	var low_source: TileSetAtlasSource = _make_source(_solid_image(LOW_COLOR), tile_size)
	var pit_source: TileSetAtlasSource = _make_source(_solid_image(PIT_COLOR), tile_size)
	tile_set.add_source(floor_source)
	tile_set.add_source(wall_source)
	tile_set.add_source(high_source)
	tile_set.add_source(low_source)
	tile_set.add_source(pit_source)
	_add_square(wall_source, 0)
	_add_square(high_source, 1)
	_add_square(low_source, 2)
	var error: Error = ResourceSaver.save(tile_set, OUTPUT_PATH)
	if error != OK:
		printerr("onset tileset not saved: ", error_string(error))
	quit(0 if error == OK else 1)


func _make_source(image: Image, tile_size: Vector2i) -> TileSetAtlasSource:
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = tile_size
	source.create_tile(Vector2i.ZERO)
	return source


func _add_square(source: TileSetAtlasSource, physics_layer: int) -> void:
	var half: float = Const.TILE_SIZE / 2.0
	var data: TileData = source.get_tile_data(Vector2i.ZERO, 0)
	data.add_collision_polygon(physics_layer)
	data.set_collision_polygon_points(physics_layer, 0, PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half),
	]))


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
