class_name Trigger
extends Marker2D
## An element of the room that a shot of the player sets off (story 4.4). The only kind for now is the lamp: the first
## player shot that touches it dazzles the living enemies around it, once per room. Enemy shots pass through it.
## It has no body (nothing is blocked by it) and no hit points: the shot is consumed, the hit refused.

## Lamp kind, as written in the room source text (`trigger lamp x y`).
const KIND_LAMP: StringName = &"lamp"
## Kinds the validator accepts.
const KNOWN_KINDS: Array[StringName] = [KIND_LAMP]
## Size of the lamp's hurtbox in pixels (one tile).
const LAMP_SIZE_PX: float = 16.0
## Placeholder look until epic 7: a bright disc, a dull one once spent.
const LAMP_ON_COLOR: Color = Color(1.0, 0.95, 0.5)
const LAMP_OFF_COLOR: Color = Color(0.3, 0.28, 0.22)
const LAMP_RADIUS_PX: float = 5.0

## The lamp was set off: it dazzled the room's enemies. Carries how many it reached.
signal triggered(dazzled_count: int)

## Kind of trigger, read from the room source text.
@export var kind: StringName = &""

## Hit by the player's shots (registered with the player's BulletManager). Null for an unknown kind.
var hurtbox: Hurtbox

var _room: Room
var _spent: bool = false


func _ready() -> void:
	if kind != KIND_LAMP:
		Log.error("room", "trigger %s has unknown kind '%s'" % [get_path(), kind])
		assert(false, "Trigger needs a known kind")
		return
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(LAMP_SIZE_PX, LAMP_SIZE_PX)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.name = "Shape"
	shape_node.shape = shape
	hurtbox = Hurtbox.new()
	hurtbox.name = "Hurtbox"
	hurtbox.camp = BulletManager.Camp.ENEMY # hit by the player's camp only
	hurtbox.add_child(shape_node) # before add_child(): its _ready() looks for it
	add_child(hurtbox)
	hurtbox.set_hit_filter(_can_be_hit)
	hurtbox.damage_received.connect(_on_damage_received)


func _draw() -> void:
	if kind == KIND_LAMP:
		draw_circle(Vector2.ZERO, LAMP_RADIUS_PX, LAMP_OFF_COLOR if _spent else LAMP_ON_COLOR)


## Given by the room once its BulletManager exists: the lamp is hit by the player's shots and reaches the enemies
## through this room.
func register(player_bullets: BulletManager, room: Room) -> void:
	_room = room
	if hurtbox != null and player_bullets != null:
		player_bullets.register_hurtbox(hurtbox)


## True once the lamp has been set off.
func is_spent() -> bool:
	return _spent


func _can_be_hit() -> bool:
	return not _spent


func _on_damage_received(_info: DamageInfo) -> void:
	hurtbox.refuse_hit() # no damage number: the shot is consumed, nothing is hurt
	if _spent:
		return
	_spent = true
	queue_redraw()
	var dazzled: int = 0
	if _room != null:
		var radius_px: float = Tuning.ROOM.lamp_radius_tiles * Const.TILE_SIZE
		for enemy: Enemy in _room.enemies_within(global_position, radius_px):
			enemy.dazzle(Tuning.ROOM.lamp_dazzle_duration)
			dazzled += 1
	Log.debug("room", "%s lamp set off, dazzled=%d" % [name, dazzled])
	triggered.emit(dazzled)
