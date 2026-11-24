class_name RoomStock
extends RefCounted
## Everything lying in or offered by one room of the floor (D9): the only way anything pickable gets into a room.
## The Run keeps one per cell, so what was not taken (or was dropped) is still there on the next visit.

enum Kind { ITEM }


## One pickable thing. position: room coordinates (pixels).
class Offer extends RefCounted:
	var kind: Kind = Kind.ITEM
	var item: ItemDef
	var position: Vector2 = Vector2.ZERO
	var taken: bool = false
	## Shards to pay; 0 = free (shops: story 5.x).
	var price: int = 0


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


## Offers not taken yet.
func remaining() -> Array[Offer]:
	var left: Array[Offer] = []
	for offer: Offer in offers:
		if not offer.taken:
			left.append(offer)
	return left
