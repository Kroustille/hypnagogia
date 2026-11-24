class_name Pickup
extends Area2D
## An item lying on the floor of a room (an Offer of the RoomStock). The player walking onto it takes it; it is greyed
## and inert when the item cannot be taken (a Falling Tooth with one heart left).
## Physics callbacks only remember; the taking happens on the next physics tick (the tree is never changed inside a
## query flush). A player already standing on the pickup when it appears is found by polling the overlaps.

const RADIUS_PX: float = 8.0
## Drawn above the floor decor, under the characters.
const Z_INDEX: int = -1
const REFUSED_MODULATE: Color = Color(0.45, 0.45, 0.45, 0.7)
## Placeholder look until epic 7: a diamond in this color, with the family color of the first tag.
const COLOR: Color = Color(0.95, 0.85, 0.4)
const RIM_COLOR: Color = Color(1.0, 1.0, 1.0)

var offer: RoomStock.Offer
var _player: Player
var _touching: bool = false
var _collected: bool = false


## Dependency injection: call before add_child().
func setup(new_offer: RoomStock.Offer, player: Player) -> void:
	offer = new_offer
	_player = player


func _ready() -> void:
	collision_layer = Const.LAYER_PICKUPS
	collision_mask = Const.LAYER_PLAYER
	monitoring = true
	monitorable = false
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.name = "Shape"
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = RADIUS_PX
	shape_node.shape = shape
	add_child(shape_node)
	position = offer.position
	z_index = Z_INDEX
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh_look()


func _physics_process(_delta: float) -> void:
	if _collected or _player == null or not is_instance_valid(_player):
		return
	if not _touching:
		# A player already there when the pickup appeared never entered: look at the overlaps.
		_touching = get_overlapping_bodies().has(_player)
	_refresh_look()
	if _touching and _player.carrier.can_take(offer.item):
		_collect()


## True when the player could take this item now.
func is_available() -> bool:
	return not _collected and _player != null and _player.carrier.can_take(offer.item)


func _collect() -> void:
	_collected = true
	set_physics_process(false)
	if _player.carrier.acquire(offer.item) == null:
		_collected = false
		set_physics_process(true)
		_touching = false
		return
	offer.taken = true
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body == _player:
		_touching = true


func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_touching = false


func _refresh_look() -> void:
	var wanted: Color = Color.WHITE if is_available() else REFUSED_MODULATE
	if modulate != wanted:
		modulate = wanted


func _draw() -> void:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
	draw_colored_polygon(points, COLOR)
	points.append(points[0])
	draw_polyline(points, RIM_COLOR, 1.0)
