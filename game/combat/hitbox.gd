class_name Hitbox
extends Area2D
## Contact damage zone of an entity (FR12: enemies also hurt on contact). Contact is not an attack: no telegraph.
## No physics overlap: every tick, after the entities (Const.PHYSICS_PRIORITY_HITBOXES), it tests its rectangle
## against its target's Hurtbox (world_rect(), is_hittable()) and delivers a DamageInfo through Hurtbox.receive().
## The hit filter of the target (invulnerability after a hit, dash, F1) turns the contact into a continuous one:
## a new hit lands as soon as the target can be hit again while the zones still overlap.
## Its CollisionShape2D child must hold a RectangleShape2D; it joins the F2 debug group.

## Whose zone this is: an ENEMY hitbox hits PLAYER-camp hurtboxes, and the other way round.
@export var camp: BulletManager.Camp = BulletManager.Camp.ENEMY

var _target: Hurtbox
var _damage: float = 0.0
var _source: DamageInfo.Source = DamageInfo.Source.CONTACT
var _clock_group: GameClock.Group = GameClock.Group.ENEMIES
var _heavy: bool = false
var _is_setup: bool = false
var _shape_node: CollisionShape2D
var _rectangle: RectangleShape2D


## Dependency injection: call before add_child(). heavy: the delivered DamageInfo is a heavy attack (FR12).
func setup(target: Hurtbox, damage: float, source: DamageInfo.Source, clock_group: GameClock.Group, heavy: bool = false) -> void:
	_heavy = heavy
	_target = target
	_damage = damage
	_source = source
	_clock_group = clock_group
	_is_setup = true


func _ready() -> void:
	process_physics_priority = Const.PHYSICS_PRIORITY_HITBOXES
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	for child: Node in get_children():
		var shape_node: CollisionShape2D = child as CollisionShape2D
		if shape_node != null:
			_shape_node = shape_node
			break
	if _shape_node != null:
		_rectangle = _shape_node.shape as RectangleShape2D
	if _rectangle == null:
		set_physics_process(false) # before the assert: it aborts the function in debug builds
		Log.error("combat", "hitbox %s needs a CollisionShape2D child with a RectangleShape2D" % get_path())
		assert(false, "Hitbox without a rectangle shape")
		return
	_shape_node.add_to_group(Const.GROUP_DEBUG_SHAPES)
	if not _is_setup or _target == null or _target.camp == camp:
		set_physics_process(false)
		Log.error("combat", "hitbox %s needs setup() with a target of the opposite camp" % get_path())
		assert(false, "Hitbox.setup() must be called before add_child() with an opposite-camp target")


## Axis-aligned rectangle of the shape, in global coordinates. Rotation and scale are ignored.
func world_rect() -> Rect2:
	if _rectangle == null:
		return Rect2()
	var size: Vector2 = _rectangle.size
	return Rect2(_shape_node.global_position - size / 2.0, size)


func _physics_process(_delta: float) -> void:
	if GameClock.scale(_clock_group) <= 0.0:
		return
	if not is_instance_valid(_target) or not _target.is_hittable():
		return
	var rect: Rect2 = world_rect()
	var target_rect: Rect2 = _target.world_rect()
	if not rect.intersects(target_rect):
		return
	var info: DamageInfo = DamageInfo.from_bullet(
		_damage, (target_rect.get_center() - rect.get_center()).normalized(), _source
	)
	info.is_heavy = _heavy
	_target.receive(info)
