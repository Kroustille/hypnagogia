class_name Furniture
extends Node2D
## A piece of furniture (story 4.4): a solid body that bodies cannot cross and that stops the shots of both camps, until
## its hit points run out. The node is the room-source marker: it sits on the center of its top-left tile and covers
## def.size tiles from there. On entry it builds its body, one HitPoints and two Hurtboxes (one per camp: a hurtbox is
## hit by the bullets of the opposite camp, so each BulletManager needs its own). Its look is a placeholder rectangle.
## A destroyed piece blocks nothing any more; the path grid of story 4.5 reads is_destroyed() / destroyed.

## The hit points ran out: body, hurtboxes and look are gone.
signal destroyed

## Placeholder outline of the rectangle, until epic 7.
const OUTLINE_COLOR: Color = Color(0.1, 0.08, 0.12, 0.8)

## What it is. A piece without a def does nothing (the validator refuses it).
@export var def: FurnitureDef

var hp: HitPoints
## Hit by the player's shots (registered with the player's BulletManager).
var player_shot_hurtbox: Hurtbox
## Hit by the enemies' shots (registered with the enemy BulletManager).
var enemy_shot_hurtbox: Hurtbox

var _body: StaticBody2D
var _body_shape: CollisionShape2D
var _destroyed: bool = false


func _ready() -> void:
	if def == null or def.size.x < 1 or def.size.y < 1:
		Log.error("room", "furniture %s has no usable def" % get_path())
		assert(false, "Furniture needs a FurnitureDef with a size of at least one tile")
		return
	hp = HitPoints.new(def.max_hp)
	_body = StaticBody2D.new()
	_body.name = "Body"
	_body.collision_layer = Const.LAYER_FURNITURE
	_body.collision_mask = 0
	_body_shape = _make_shape_node("Shape")
	_body.add_child(_body_shape)
	_body_shape.add_to_group(Const.GROUP_DEBUG_SHAPES)
	add_child(_body)
	player_shot_hurtbox = _make_hurtbox("PlayerShotHurtbox", BulletManager.Camp.ENEMY)
	enemy_shot_hurtbox = _make_hurtbox("EnemyShotHurtbox", BulletManager.Camp.PLAYER)


func _draw() -> void:
	if def == null or _destroyed:
		return
	var rect: Rect2 = Rect2(_footprint_offset(), footprint_px())
	draw_rect(rect, def.color)
	draw_rect(rect, OUTLINE_COLOR, false, 1.0)


## Registers both hurtboxes. Called by the room once its BulletManagers exist.
func register_hurtboxes(player_bullets: BulletManager, enemy_bullets: BulletManager) -> void:
	if player_shot_hurtbox == null:
		return # not usable (reported in _ready())
	if player_bullets != null:
		player_bullets.register_hurtbox(player_shot_hurtbox)
	if enemy_bullets != null:
		enemy_bullets.register_hurtbox(enemy_shot_hurtbox)


func is_destroyed() -> bool:
	return _destroyed


## Footprint in pixels (zero without a def).
func footprint_px() -> Vector2:
	return Vector2(def.size * Const.TILE_SIZE) if def != null else Vector2.ZERO


## The tiles it covers, in global coordinates (works before the body exists: the validator reads it on a scene
## outside the tree through the parent chain, hence the global transform of the marker only when inside the tree).
func footprint_rect() -> Rect2:
	var origin: Vector2 = global_position if is_inside_tree() else position
	return Rect2(origin + _footprint_offset(), footprint_px())


## Top-left corner of the footprint relative to the marker (the marker is the center of the first tile).
func _footprint_offset() -> Vector2:
	return Vector2(-Const.TILE_SIZE, -Const.TILE_SIZE) / 2.0


## Center of the footprint relative to the marker.
func _center_offset() -> Vector2:
	return _footprint_offset() + footprint_px() / 2.0


func _make_shape_node(shape_name: String) -> CollisionShape2D:
	var shape: RectangleShape2D = RectangleShape2D.new() # a fresh shape per piece
	shape.size = footprint_px()
	var node: CollisionShape2D = CollisionShape2D.new()
	node.name = shape_name
	node.shape = shape
	node.position = _center_offset()
	return node


func _make_hurtbox(box_name: String, camp: BulletManager.Camp) -> Hurtbox:
	var box: Hurtbox = Hurtbox.new()
	box.name = box_name
	box.camp = camp
	box.stops_piercing = true
	box.add_child(_make_shape_node("Shape")) # before add_child(): its _ready() looks for it
	add_child(box)
	box.set_hit_filter(_can_be_hit)
	box.damage_received.connect(_on_damage_received.bind(box))
	return box


func _can_be_hit() -> bool:
	return not _destroyed and not hp.is_dead()


## Both hurtboxes land here: one HitPoints for the piece. The bullet's damage is the loss (1 half-heart = 1 HP).
func _on_damage_received(info: DamageInfo, box: Hurtbox) -> void:
	var removed: float = hp.apply_damage(info.amount)
	if removed <= 0.0:
		box.refuse_hit()
		return
	Log.debug("room", "%s hit amount=%s hp=%s" % [def.id, removed, hp.current])
	if hp.is_dead():
		_destroy()


## Once. The hit filter answers false at once (HP drop no further; shots of this very tick already tested by a
## BulletManager are still consumed, as for an enemy: from the next tick on they pass through); the physics objects are
## switched off in a deferred call, as a physics callback may be running. The BulletManagers unregister the hurtboxes
## when the node leaves the tree (never from inside their hit delivery).
func _destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	_body.set_deferred("collision_layer", 0)
	_body_shape.set_deferred("disabled", true)
	for box: Hurtbox in [player_shot_hurtbox, enemy_shot_hurtbox]:
		box.set_deferred("monitorable", false)
		(box.get_child(0) as CollisionShape2D).set_deferred("disabled", true)
	queue_redraw() # nothing is drawn any more
	Log.debug("room", "%s destroyed" % def.id)
	destroyed.emit()
