class_name BulletLoadTest
extends Node2D
## Debug-only load test (F5): keeps ~400 enemy bullets alive inside a walled field (story 1.2).
## The temporary Walls layer is built in code and replaced by the arena in story 1.3.
## Bullet directions come from a golden-angle counter: no global RNG (AR14).

const TARGET_COUNT: int = 400
const FIRE_PER_TICK: int = 8
const GOLDEN_ANGLE: float = 2.39996
const POOL_CAPACITY: int = 512
const FIELD_CELLS: Vector2i = Vector2i(40, 22)
const EMITTERS: Array[Vector2] = [
	Vector2(240.0, 180.0), Vector2(400.0, 180.0), Vector2(320.0, 100.0), Vector2(320.0, 260.0),
]
const BACKGROUND_COLOR: Color = Color(0.05, 0.05, 0.1)
const WALL_COLOR: Color = Color(0.35, 0.3, 0.55)
const BULLET_COLOR: Color = Color(1.0, 0.35, 0.6)
const BULLET_SIZE: int = 8

var _manager: BulletManager
var _params: BulletParams = BulletParams.new()
var _shot_counter: int = 0


func _ready() -> void:
	# Run after the manager's own tick, so the count read after a frame is the refilled one.
	process_physics_priority = 1
	var walls: TileMapLayer = _build_walls()
	add_child(walls)
	var solid_layers: Array[TileMapLayer] = [walls]

	_manager = BulletManager.new()
	_manager.camp = BulletManager.Camp.ENEMY
	_manager.capacity = POOL_CAPACITY
	_manager.setup(solid_layers)
	add_child(_manager)
	_params.appearance = _manager.add_appearance(_make_bullet_texture())
	Log.info("combat", "bullet load test started target=%d" % TARGET_COUNT)


func _physics_process(_delta: float) -> void:
	var to_fire: int = mini(FIRE_PER_TICK, TARGET_COUNT - _manager.active_count)
	for i: int in to_fire:
		var emitter: Vector2 = EMITTERS[_shot_counter % EMITTERS.size()]
		var direction: Vector2 = Vector2.from_angle(_shot_counter * GOLDEN_ANGLE)
		_shot_counter += 1
		_manager.fire(_params, emitter, direction)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(Const.VIEWPORT)), BACKGROUND_COLOR)


func _build_walls() -> TileMapLayer:
	var image: Image = Image.create(Const.TILE_SIZE, Const.TILE_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(WALL_COLOR)
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(image)
	source.texture_region_size = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)
	source.create_tile(Vector2i.ZERO)
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(Const.TILE_SIZE, Const.TILE_SIZE)
	var source_id: int = tile_set.add_source(source)

	var layer: TileMapLayer = TileMapLayer.new()
	layer.name = "Walls"
	layer.tile_set = tile_set
	for x: int in FIELD_CELLS.x:
		layer.set_cell(Vector2i(x, 0), source_id, Vector2i.ZERO)
		layer.set_cell(Vector2i(x, FIELD_CELLS.y - 1), source_id, Vector2i.ZERO)
	for y: int in FIELD_CELLS.y:
		layer.set_cell(Vector2i(0, y), source_id, Vector2i.ZERO)
		layer.set_cell(Vector2i(FIELD_CELLS.x - 1, y), source_id, Vector2i.ZERO)
	for y: int in range(6, 16): # two inner bars, so walls are hit from inside too
		layer.set_cell(Vector2i(10, y), source_id, Vector2i.ZERO)
		layer.set_cell(Vector2i(29, y), source_id, Vector2i.ZERO)
	return layer


func _make_bullet_texture() -> Texture2D:
	var image: Image = Image.create(BULLET_SIZE, BULLET_SIZE, false, Image.FORMAT_RGBA8)
	var center: Vector2 = Vector2(BULLET_SIZE, BULLET_SIZE) / 2.0
	var radius: float = BULLET_SIZE / 2.0
	for y: int in BULLET_SIZE:
		for x: int in BULLET_SIZE:
			if (Vector2(x + 0.5, y + 0.5) - center).length() <= radius:
				image.set_pixel(x, y, BULLET_COLOR)
	return ImageTexture.create_from_image(image)
