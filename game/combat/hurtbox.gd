class_name Hurtbox
extends Area2D
## The zone where an entity takes hits. Holds no HP (its owner entrusts them to Health): receive() only emits
## a signal that the owner listens to, and does nothing when the hurtbox cannot be hit (is_hittable()).
## BulletManagers do not use physics (D1): they read world_rect() of the hurtboxes registered with them.
## The collision layer is for future Area2D consumers (contact, epic 2).
## Its CollisionShape2D child must hold a RectangleShape2D; it joins the F2 debug group.

## Local signal: the owner (parent) listens.
signal damage_received(info: DamageInfo)

## Whose hurtbox this is: an ENEMY hurtbox is hit by the PLAYER camp's bullets, and the other way round.
@export var camp: BulletManager.Camp = BulletManager.Camp.ENEMY

## When true, once one bullet hits this hurtbox in a tick, the other bullets of that tick pass through.
## Set on the player's hurtbox: its first hit opens the invulnerability (story 2.1).
@export var one_hit_per_tick: bool = false

var _filter_error_reported: bool = false
var _hit_filter: Callable # set by the owner; returns bool: "can this hurtbox be hit now?"
var _shape_node: CollisionShape2D
var _rectangle: RectangleShape2D


func _ready() -> void:
	collision_layer = Const.LAYER_ENEMY_HURTBOX if camp == BulletManager.Camp.ENEMY else Const.LAYER_PLAYER_HURTBOX
	collision_mask = 0
	monitoring = false
	monitorable = true
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node != null:
			_shape_node = shape_node
			break
	if _shape_node != null:
		_rectangle = _shape_node.shape as RectangleShape2D
	if _rectangle == null:
		Log.error("combat", "hurtbox %s needs a CollisionShape2D child with a RectangleShape2D" % get_path())
		assert(false, "Hurtbox without a rectangle shape")
		return
	_shape_node.add_to_group(Const.GROUP_DEBUG_SHAPES)


## The owner's filter (invulnerability, death...). Must return a bool.
func set_hit_filter(filter: Callable) -> void:
	_hit_filter = filter


## monitorable, shape enabled, in the tree, and the owner's filter (if any) says yes.
func is_hittable() -> bool:
	if _shape_node == null or not monitorable or _shape_node.disabled or not is_inside_tree():
		return false
	if _hit_filter.is_valid():
		var answer: Variant = _hit_filter.call()
		if answer is bool:
			return answer
		if not _filter_error_reported: # is_hittable() runs every tick: report once only (AR27)
			_filter_error_reported = true
			Log.error("combat", "hit filter of %s must return a bool" % get_path())
			assert(false, "Hurtbox hit filter must return a bool")
	return true


## Emits damage_received. The only entry point for damage (AR: DamageInfo -> Hurtbox.receive()).
## Returns false and emits nothing when the hurtbox cannot be hit.
## An enemy hurtbox also notifies Events.enemy_damaged (damage numbers, telemetry)
## after damage_received (the owner applies the hit synchronously in its handler).
func receive(info: DamageInfo) -> bool:
	if not is_hittable():
		return false
	damage_received.emit(info)
	if camp == BulletManager.Camp.ENEMY and _rectangle != null:
		var rect: Rect2 = world_rect()
		Events.enemy_damaged.emit(Vector2(rect.get_center().x, rect.position.y), info.amount)
	return true


## Axis-aligned rectangle of the shape, in global coordinates. Rotation and scale are ignored.
## An empty rect when the shape is missing (already reported in _ready()).
func world_rect() -> Rect2:
	if _rectangle == null:
		return Rect2()
	var size: Vector2 = _rectangle.size
	return Rect2(_shape_node.global_position - size / 2.0, size)
