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
func add_item(def: ItemDef, position: Vector2, price: int = 0) -> Offer:
	var offer: Offer = Offer.new()
	offer.kind = Kind.ITEM
	offer.item = def
	offer.position = position
	offer.price = price
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
