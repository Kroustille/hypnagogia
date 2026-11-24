class_name Loadout
extends RefCounted
## The items the player holds (D9). Adding gives the modifiers and attaches the effect; removing undoes both.

## After the modifiers are in place and the effect attached.
signal item_added(owned: OwnedItem)
## After the modifiers are cleared and the effect detached.
signal item_removed(owned: OwnedItem)
## The consumable slot changed (null = emptied).
signal consumable_changed(def: ConsumableDef)

## The consumable carried, at most one (story 5.3). Null = the slot is free.
var consumable: ConsumableDef

var _carrier: BuildCarrier
var _items: Array[OwnedItem] = []


func _init(carrier: BuildCarrier) -> void:
	_carrier = carrier


## Every copy held, in the order taken.
func items() -> Array[OwnedItem]:
	return _items.duplicate()


func count() -> int:
	return _items.size()


## Copies of this item id held.
func copies_of(id: StringName) -> int:
	var copies: int = 0
	for owned: OwnedItem in _items:
		if owned.def.id == id:
			copies += 1
	return copies


## The ids of the items held, one entry per distinct item (copies of one item count once).
func owned_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for owned: OwnedItem in _items:
		if not ids.has(owned.def.id):
			ids.append(owned.def.id)
	return ids


## Puts a consumable in the slot (null empties it). Returns the one that was there (null when the slot was free).
func set_consumable(def: ConsumableDef) -> ConsumableDef:
	var previous: ConsumableDef = consumable
	consumable = def
	consumable_changed.emit(def)
	return previous

## Takes a new copy of the item. Returns it.
func add(def: ItemDef) -> OwnedItem:
	var owned: OwnedItem = OwnedItem.new(def)
	for modifier: ModifierDef in def.modifiers:
		_carrier.stats.set_modifier(owned, modifier.stat, modifier.kind, modifier.value)
	if def.effect_script != null:
		var made: Object = (def.effect_script as GDScript).new()
		var effect: ItemEffect = made as ItemEffect
		if effect == null:
			Log.error("items", "effect_script of %s does not extend ItemEffect" % def.id)
			assert(false, "effect_script must extend ItemEffect")
		else:
			effect.owned = owned
			owned.effect = effect
	_items.append(owned)
	if owned.effect != null:
		owned.effect.attach(_carrier)
	item_added.emit(owned)
	return owned


## Takes this copy away. False when it is not held.
func remove(owned: OwnedItem) -> bool:
	var index: int = _items.find(owned)
	if index == -1:
		return false
	_items.remove_at(index)
	_carrier.stats.clear_source(owned) # a freed source would stay a key of the stat block
	if owned.effect != null:
		owned.effect.detach()
	item_removed.emit(owned)
	return true


## Detaches every effect without touching the stats or the list (the carrier leaves the tree).
func detach_all() -> void:
	for owned: OwnedItem in _items:
		if owned.effect != null:
			owned.effect.detach()
