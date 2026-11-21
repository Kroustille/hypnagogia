class_name Hurtbox
extends Area2D
## The zone where an entity takes hits. Holds no HP (Health: story 2.1): receive() only emits a signal
## that the owner listens to. BulletManagers do not use physics (D1): they read world_rect() of the
## hurtboxes registered with them. The collision layer is for future Area2D consumers (contact, epic 2).
## Its CollisionShape2D child must hold a RectangleShape2D; it joins the F2 debug group.

## Local signal: the owner (parent) listens.
signal damage_received(info: DamageInfo)

## Whose hurtbox this is: an ENEMY hurtbox is hit by the PLAYER camp's bullets, and the other way round.
@export var camp: BulletManager.Camp = BulletManager.Camp.ENEMY

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


## Emits damage_received. The only entry point for damage (AR: DamageInfo -> Hurtbox.receive()).
func receive(info: DamageInfo) -> void:
	damage_received.emit(info)


## Axis-aligned rectangle of the shape, in global coordinates. Rotation and scale are ignored.
## An empty rect when the shape is missing (already reported in _ready()).
func world_rect() -> Rect2:
	if _rectangle == null:
		return Rect2()
	var size: Vector2 = _rectangle.size
	return Rect2(_shape_node.global_position - size / 2.0, size)
