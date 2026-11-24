class_name Pickup
extends Area2D
## An item or a consumable lying on the floor of a room (an Offer of the RoomStock). The player walking onto it takes it; it
## is greyed and inert when it cannot be taken (a Falling Tooth with one heart left). A consumable the player dropped is
## not armed until the player has left its zone (story 5.3): it is not taken back at once.
## Physics callbacks only remember; the taking happens on the next physics tick (the tree is never changed inside a
## query flush). A player already standing on the pickup when it appears is found by polling the overlaps.

const RADIUS_PX: float = 8.0
## Drawn above the floor decor, under the characters.
const Z_INDEX: int = -1
const REFUSED_MODULATE: Color = Color(0.45, 0.45, 0.45, 0.7)
## Placeholder look until epic 7: a diamond in this color, with the family color of the first tag.
const COLOR: Color = Color(0.95, 0.85, 0.4)
const RIM_COLOR: Color = Color(1.0, 1.0, 1.0)
## Consumables are drawn as a round bottle-like disc in this color.
const CONSUMABLE_COLOR: Color = Color(0.5, 0.85, 0.95)
## Physics ticks a disarmed pickup waits before looking at the overlaps (the first ones report nothing yet).
const ARMING_SETTLE_TICKS: int = 3
## A disarmed pickup the player never touched arms only when the player is farther than this (a deposit moved to a free
## cell does not overlap the player yet, who may land on it).
const ARM_DISTANCE_PX: float = RADIUS_PX + Const.TILE_SIZE

## The player took a consumable and was already carrying one: the old one goes back on the floor (the room lays it).
signal consumable_replaced(def: ConsumableDef, global_position: Vector2)

var offer: RoomStock.Offer
var _player: Player
var _touching: bool = false
var _collected: bool = false
var _armed: bool = true
var _alive_ticks: int = 0


## Dependency injection: call before add_child().
func setup(new_offer: RoomStock.Offer, player: Player) -> void:
	offer = new_offer
	_player = player
	_armed = new_offer.armed


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
	_alive_ticks += 1
	if not _armed:
		_update_arming()
		_refresh_look()
		return
	if not _touching:
		# A player already there when the pickup appeared never entered: look at the overlaps.
		_touching = get_overlapping_bodies().has(_player)
	_refresh_look()
	if _touching and _can_take():
		_collect()


## True when the player could take this item now.
func is_available() -> bool:
	return not _collected and _armed and _player != null and _can_take()


func _collect() -> void:
	_collected = true
	set_physics_process(false)
	if offer.kind == RoomStock.Kind.CONSUMABLE:
		var previous: ConsumableDef = _player.carrier.acquire_consumable(offer.consumable)
		offer.taken = true
		if previous != null:
			consumable_replaced.emit(previous, _player.global_position)
		queue_free()
		return
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
		# A pause or a door fade switches the physics off, which also reports the exit: that is not the player stepping off.
		if not _armed and can_process() and _player.can_process():
			_arm()


## Whether the player could take what lies here now (armed apart).
func _can_take() -> bool:
	if offer.kind == RoomStock.Kind.CONSUMABLE:
		return _player.carrier.can_take_consumable(offer.consumable)
	return _player.carrier.can_take(offer.item)


## A disarmed pickup arms when the player steps off it; one the player never touched (a room visited again) arms after
## the first ticks have reported the overlaps.
func _update_arming() -> void:
	if not _player.can_process():
		_alive_ticks = 0 # a fade or a pause: the player is out of the physics space, nothing is known
		return
	if _alive_ticks >= ARMING_SETTLE_TICKS and not get_overlapping_bodies().has(_player) \
			and global_position.distance_to(_player.global_position) > ARM_DISTANCE_PX:
		_arm()


func _arm() -> void:
	_armed = true
	offer.armed = true


func _refresh_look() -> void:
	var wanted: Color = Color.WHITE if is_available() else REFUSED_MODULATE
	if modulate != wanted:
		modulate = wanted


func _draw() -> void:
	var points: PackedVector2Array = PackedVector2Array([
		Vector2(0, -6), Vector2(5, 0), Vector2(0, 6), Vector2(-5, 0)])
	if offer.kind == RoomStock.Kind.CONSUMABLE:
		draw_circle(Vector2.ZERO, 5.0, CONSUMABLE_COLOR)
		draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 12, RIM_COLOR, 1.0)
		return
	draw_colored_polygon(points, COLOR)
	points.append(points[0])
	draw_polyline(points, RIM_COLOR, 1.0)
