class_name Drops
extends RefCounted
## What a cleared room can leave on the floor (story 5.4) and how it gets there.

enum Kind { HALF_HEART, HALF_ARMOR, CONSUMABLE, SHARDS_3 }


## Lays a drop in the room, at the nearest free cell to position (room coordinates). The Pickup joins the tree on the next
## idle moment: the caller is usually inside the emission of room_cleared, while the room is still removing its enemies
## ("Parent node is busy"). consumable_roll: the raw draw Loot.roll() made for the consumable of this drop.
static func spawn(room: Room, kind: Kind, position: Vector2, consumable_roll: int = 0) -> void:
	_lay.call_deferred(room, kind, position, consumable_roll)


## The consumable a raw draw designates: the catalog sorted by id (a stable order across platforms).
static func consumable_for(consumable_roll: int) -> ConsumableDef:
	var pool: Array[ConsumableDef] = ConsumableCatalog.all()
	if pool.is_empty():
		return null
	pool.sort_custom(func(a: ConsumableDef, b: ConsumableDef) -> bool: return String(a.id) < String(b.id))
	return pool[consumable_roll % pool.size()]


## room_ref is a Variant on purpose: a Room (or Object) typed parameter rejects a freed instance before the guard runs.
static func _lay(room_ref: Variant, kind: Kind, position: Vector2, consumable_roll: int) -> void:
	if not is_instance_valid(room_ref):
		return # the room was released meanwhile (the player left or died)
	@warning_ignore("unsafe_cast")
	var room: Room = room_ref as Room
	if room == null or not room.is_inside_tree():
		return
	match kind:
		Kind.HALF_HEART:
			room.add_drop_offer(RoomStock.Kind.HEART, Tuning.ECONOMY.heart_drop_half_hearts, position)
		Kind.HALF_ARMOR:
			room.add_drop_offer(RoomStock.Kind.ARMOR, Tuning.ECONOMY.armor_drop_half_hearts, position)
		Kind.SHARDS_3:
			room.add_drop_offer(RoomStock.Kind.SHARDS, Tuning.ECONOMY.shard_drop_amount, position)
		Kind.CONSUMABLE:
			var def: ConsumableDef = consumable_for(consumable_roll)
			if def == null:
				Log.warn("economy", "no consumable to drop")
				return
			room.add_consumable_offer(def, position)
