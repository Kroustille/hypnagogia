class_name Ruler
extends Node2D
## The heavy attack of the Professor's Examen final (FR12): a vertical bar over the whole height of the playable area that
## sweeps the room from one side to the other. Its contact zone is an axis-aligned Hitbox (heavy, source RULER): the answer
## is a dash, its i-frames cancel the hit like any other. Born by a RulerRunner at the end of its sign; it moves by itself, so
## a ruler already launched runs its course while the boss writes the next title. It is freed at the opposite edge, when its
## runner stops (phase left, death, end of the run) or when its boss leaves the tree.
## Positions in room pixels: it is a child of the room, like the signs.

const BAR_COLOR: Color = Color(0.95, 0.9, 0.7, 0.55)
const EDGE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.9)

var _boss: Boss
var _hitbox: Hitbox
var _size_px: Vector2 = Vector2.ZERO
var _step_px: float = 0.0
var _end_x: float = 0.0
var _direction: float = 1.0
var _is_launched: bool = false


## Builds the bar at the starting edge of arena and adds it to the room. left_to_right: the way of the sweep. The bar
## enters from the wall: its leading edge is on the edge of the playable area at launch.
func launch(boss: Boss, arena: Rect2, left_to_right: bool, thickness_tiles: float, speed_tiles: float) -> void:
	_boss = boss
	_direction = 1.0 if left_to_right else -1.0
	_size_px = Vector2(thickness_tiles * Const.TILE_SIZE, arena.size.y)
	_step_px = speed_tiles * Const.TILE_SIZE / float(Engine.physics_ticks_per_second)
	var half: float = _size_px.x / 2.0
	var start_x: float = arena.position.x - half if left_to_right else arena.end.x + half
	_end_x = arena.end.x + half if left_to_right else arena.position.x - half
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = _size_px
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.name = "Shape"
	shape_node.shape = shape
	_hitbox = Hitbox.new()
	_hitbox.name = "RulerHitbox"
	_hitbox.camp = BulletManager.Camp.ENEMY
	_hitbox.add_child(shape_node)
	_hitbox.setup(
		boss.target_hurtbox(),
		Tuning.COMBAT.heavy_hit_half_hearts,
		DamageInfo.Source.RULER,
		GameClock.Group.ENEMIES,
		true
	)
	add_child(_hitbox)
	name = "Ruler"
	z_index = Const.Z_INDEX_COMBAT
	boss.add_sign(self) # in the tree before it is moved: the hitbox reads global positions
	position = Vector2(start_x, arena.position.y + arena.size.y / 2.0)
	_is_launched = true
	queue_redraw()


## Center of the bar, in room pixels.
func center() -> Vector2:
	return position


func hitbox() -> Hitbox:
	return _hitbox


func is_launched() -> bool:
	return _is_launched


func _physics_process(_delta: float) -> void:
	if not _is_launched:
		return
	if not is_instance_valid(_boss) or not _boss.is_inside_tree():
		queue_free()
		return
	var held: bool = _boss.danger.fire_hold # the room holds the fire: the bar stops and cannot hit
	_hitbox.set_physics_process(not held)
	var clock_scale: float = GameClock.scale(GameClock.Group.ENEMIES)
	if held or clock_scale <= 0.0:
		return
	position.x += _direction * _step_px * clock_scale
	if (position.x - _end_x) * _direction >= 0.0:
		queue_free()


func _draw() -> void:
	var rect: Rect2 = Rect2(-_size_px / 2.0, _size_px)
	draw_rect(rect, BAR_COLOR)
	draw_rect(rect, EDGE_COLOR, false, 1.0)


## Stops it now (its runner stopped, the boss is dead): no more contact, gone at the end of the frame.
func dismiss() -> void:
	_is_launched = false
	if _hitbox != null:
		_hitbox.set_physics_process(false)
	queue_free()
