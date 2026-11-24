class_name ItemPicker
extends RefCounted
## Draws the item of a treasure room or a shop (story 5.2). Pure: no scene, no global state.

## One item of the pool, or null when nothing is left to offer. An item the player already holds is out unless it is
## stackable, and so is one whose price in hearts the player cannot pay. Exactly one draw on the stream per call
## whatever the number of exclusions (the stream then depends only on how many rooms were opened), none when the
## filtered pool is empty.
## owned_ids: Loadout.owned_ids(); max_half_hearts: Health.max_half_hearts of the player.
static func draw(pool: ItemPoolDef, owned_ids: Array[StringName], max_half_hearts: int, rng: RandomNumberGenerator) -> ItemDef:
	var candidates: Array[ItemDef] = candidates_of(pool, owned_ids, max_half_hearts)
	if candidates.is_empty():
		return null
	return candidates[rng.randi_range(0, candidates.size() - 1)]


## The items of the pool that may be offered, in pool order.
static func candidates_of(pool: ItemPoolDef, owned_ids: Array[StringName], max_half_hearts: int) -> Array[ItemDef]:
	var found: Array[ItemDef] = []
	if pool == null:
		return found
	for def: ItemDef in pool.items:
		if def == null:
			continue
		if owned_ids.has(def.id) and not def.stackable:
			continue
		if not def.can_be_taken(max_half_hearts):
			continue
		found.append(def)
	return found
