class_name ShopStock
extends RefCounted
## What a shop puts on its stalls (story 5.5). Pure: it only reads the stream it is given.
##
## Always the same three draws on the stream, in this order: item 1, item 2, consumable. The number of draws never
## depends on what the player holds, so the same seed gives the same stall before and after an item taken elsewhere.


## The offers of the stalls, in slot order: item, item, consumable, heart, armor (a second heart when blocks_armor); an
## item or the consumable is missing when nothing is left to offer. Positions are not set: the Run puts each offer
## on its PickupSpot.
## owned_ids: Loadout.owned_ids(); max_half_hearts: Health.max_half_hearts of the player.
## blocks_armor: the player cannot gain armor (Naked in public, story 5.9): the armor stall becomes a second heart, at the
## price of a heart. The draws do not change.
static func draw(pool: ItemPoolDef, consumables: Array[ConsumableDef], owned_ids: Array[StringName],
		max_half_hearts: int, rng: RandomNumberGenerator, tuning: EconomyTuning, blocks_armor: bool = false) -> Array[RoomStock.Offer]:
	var offers: Array[RoomStock.Offer] = []
	var candidates: Array[ItemDef] = ItemPicker.candidates_of(pool, owned_ids, max_half_hearts)
	for _slot: int in 2:
		var roll: int = rng.randi() # drawn even with nothing left
		if candidates.is_empty():
			continue
		var def: ItemDef = candidates[roll % candidates.size()]
		candidates.erase(def) # the second item is drawn among the others
		var item_offer: RoomStock.Offer = RoomStock.Offer.new()
		item_offer.kind = RoomStock.Kind.ITEM
		item_offer.item = def
		item_offer.price = tuning.item_price
		offers.append(item_offer)
	var consumable_roll: int = rng.randi()
	if not consumables.is_empty():
		var consumable_offer: RoomStock.Offer = RoomStock.Offer.new()
		consumable_offer.kind = RoomStock.Kind.CONSUMABLE
		consumable_offer.consumable = consumables[consumable_roll % consumables.size()]
		consumable_offer.price = tuning.consumable_price
		offers.append(consumable_offer)
	offers.append(_drop(RoomStock.Kind.HEART, tuning.heal_half_hearts, tuning.heart_price))
	if blocks_armor:
		offers.append(_drop(RoomStock.Kind.HEART, tuning.heal_half_hearts, tuning.heart_price))
	else:
		offers.append(_drop(RoomStock.Kind.ARMOR, tuning.armor_half_hearts, tuning.armor_price))
	return offers


static func _drop(kind: RoomStock.Kind, amount: int, price: int) -> RoomStock.Offer:
	var offer: RoomStock.Offer = RoomStock.Offer.new()
	offer.kind = kind
	offer.amount = amount
	offer.price = price
	return offer
