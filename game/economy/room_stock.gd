class_name RoomStock
extends RefCounted
## Everything lying in or offered by one room of the floor (D9): the only way anything pickable gets into a room.
## The Run keeps one per cell, so what was not taken (or was dropped) is still there on the next visit.

enum Kind { ITEM, CONSUMABLE, HEART, ARMOR, SHARDS }


## One pickable thing. position: room coordinates (pixels).
class Offer extends RefCounted:
	var kind: Kind = Kind.ITEM
	var item: ItemDef
	var consumable: ConsumableDef
	var position: Vector2 = Vector2.ZERO
	var taken: bool = false
	## Shards to pay; 0 = free (a shop stall has a price, story 5.5).
	var price: int = 0
	## A consumable dropped by the player is armed only once the player has left its zone (story 5.3).
	var armed: bool = true
	## Half-hearts (HEART, ARMOR) or shards (SHARDS) a drop gives.
	var amount: int = 0
	## Charge of an active item laid again by the player; -1 = a new one, charged (story 5.8).
	var charge: int = -1

	## Id of what lies there, whatever its kind.
	func id() -> StringName:
		match kind:
			Kind.ITEM:
				return item.id
			Kind.CONSUMABLE:
				return consumable.id
			Kind.HEART:
				return &"heart"
			Kind.ARMOR:
				return &"armor"
		return &"shards"


var offers: Array[Offer] = []


## Adds an offer and returns it.
func add_item(def: ItemDef, position: Vector2, price: int = 0, armed: bool = true, charge: int = -1) -> Offer:
	var offer: Offer = Offer.new()
	offer.kind = Kind.ITEM
	offer.item = def
	offer.position = position
	offer.price = price
	offer.armed = armed
	offer.charge = charge
	offers.append(offer)
	return offer


## Adds a consumable offer and returns it. armed false: not to be taken until the player has stepped off it.
func add_consumable(def: ConsumableDef, position: Vector2, armed: bool = true) -> Offer:
	var offer: Offer = Offer.new()
	offer.kind = Kind.CONSUMABLE
	offer.consumable = def
	offer.position = position
	offer.armed = armed
	offers.append(offer)
	return offer


## Adds a heal, armor or shards drop (kind HEART, ARMOR or SHARDS) and returns it.
func add_drop(drop_kind: Kind, amount: int, position: Vector2) -> Offer:
	var offer: Offer = Offer.new()
	offer.kind = drop_kind
	offer.amount = amount
	offer.position = position
	offers.append(offer)
	return offer


## Adds an offer built elsewhere (a shop stall), at a position.
func add_offer(offer: Offer, position: Vector2) -> void:
	offer.position = position
	offers.append(offer)


## Offers not taken yet.
func remaining() -> Array[Offer]:
	var left: Array[Offer] = []
	for offer: Offer in offers:
		if not offer.taken:
			left.append(offer)
	return left


## The player can no longer gain armor (story 5.9): the armor stalls of a shop not bought yet become a heart at the price
## of a heart. An armor drop on the floor stays: it is refused at the contact, like any pickup the player cannot take.
## Returns how many stalls were changed.
func apply_no_armor(tuning: EconomyTuning) -> int:
	var changed: int = 0
	for offer: Offer in remaining():
		if offer.kind != Kind.ARMOR or offer.price <= 0:
			continue
		offer.kind = Kind.HEART
		offer.amount = tuning.heal_half_hearts
		offer.price = tuning.heart_price
		changed += 1
	return changed


## The offers as saved in run.json: objects are referenced by id, never stored (architecture D12).
func to_dict() -> Dictionary:
	var list: Array = []
	for offer: Offer in offers:
		list.append({
			"kind": int(offer.kind),
			"id": String(offer.id()),
			"position": [offer.position.x, offer.position.y],
			"taken": offer.taken,
			"price": offer.price,
			"armed": offer.armed,
			"amount": offer.amount,
			"charge": offer.charge,
		})
	return {"offers": list}


## The stock of a saved dictionary. An offer whose item or consumable no longer exists (removed from the game) is skipped
## and logged; one that is malformed makes the whole stock unreadable (null).
static func from_dict(data: Dictionary) -> RoomStock:
	var list: Variant = data.get("offers")
	if typeof(list) != TYPE_ARRAY:
		return null
	var stock: RoomStock = RoomStock.new()
	var entries: Array = list
	for entry: Variant in entries:
		if typeof(entry) != TYPE_DICTIONARY:
			return null
		var fields: Dictionary = entry
		var offer: Offer = _offer_from(fields)
		if offer == null:
			return null
		if offer.kind == Kind.ITEM and offer.item == null or offer.kind == Kind.CONSUMABLE and offer.consumable == null:
			Log.warn("save", "offer %s no longer exists: skipped" % fields.get("id"))
			continue
		stock.offers.append(offer)
	return stock


static func _offer_from(fields: Dictionary) -> Offer:
	var kind_value: Variant = fields.get("kind")
	var position_value: Variant = fields.get("position")
	var id_value: Variant = fields.get("id")
	if typeof(kind_value) != TYPE_FLOAT and typeof(kind_value) != TYPE_INT:
		return null
	if typeof(id_value) != TYPE_STRING or typeof(position_value) != TYPE_ARRAY:
		return null
	var coordinates: Array = position_value
	if coordinates.size() != 2:
		return null
	var kind_index: int = RunState.whole(kind_value)
	if kind_index < 0 or kind_index > int(Kind.SHARDS):
		return null
	var offer: Offer = Offer.new()
	offer.kind = kind_index as Kind
	for part: Variant in coordinates:
		if typeof(part) != TYPE_FLOAT and typeof(part) != TYPE_INT:
			return null
	offer.position = Vector2(_float_of(coordinates[0]), _float_of(coordinates[1]))
	offer.taken = fields.get("taken") == true
	offer.armed = fields.get("armed") != false
	offer.price = maxi(_int_field(fields, "price"), 0)
	offer.amount = maxi(_int_field(fields, "amount"), 0)
	offer.charge = _int_field(fields, "charge", -1)
	var id: StringName = StringName(_text_of(id_value))
	if offer.kind == Kind.ITEM:
		offer.item = ItemCatalog.by_id(id)
	elif offer.kind == Kind.CONSUMABLE:
		offer.consumable = ConsumableCatalog.by_id(id)
	return offer


static func _int_field(fields: Dictionary, key: String, default: int = 0) -> int:
	var value: Variant = fields.get(key, default)
	return RunState.whole(value, default) if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT else default


static func _float_of(value: Variant) -> float:
	var number: float = value
	return number


static func _text_of(value: Variant) -> String:
	var text: String = value
	return text
