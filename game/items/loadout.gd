class_name Loadout
extends RefCounted
## The items the player holds (D9). Adding gives the modifiers and attaches the effect; removing undoes both.

## After the modifiers are in place and the effect attached.
signal item_added(owned: OwnedItem)
## After the modifiers are cleared and the effect detached.
signal item_removed(owned: OwnedItem)
## The consumable slot changed (null = emptied).
signal consumable_changed(def: ConsumableDef)
## The active item changed (taken, replaced, charged, used); null = none.
signal active_changed(owned: OwnedItem)

## The consumable carried, at most one (story 5.3). Null = the slot is free.
var consumable: ConsumableDef
## The active item carried, at most one (story 5.8); it is also in items(), so its tags and effect count. Null = none.
var active: OwnedItem

var _carrier: BuildCarrier
var _items: Array[OwnedItem] = []
var _swapping: bool = false


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
func add(def: ItemDef, charge: int = -1) -> OwnedItem:
	var owned: OwnedItem = OwnedItem.new(def)
	if def.active:
		owned.charge_max = int(def.params[&"charge_rooms"]) if def.params.has(&"charge_rooms") else 1
		owned.charge = owned.charge_max if charge < 0 else mini(charge, owned.charge_max)
	for modifier: ModifierDef in def.modifiers:
		_carrier.stats.set_modifier(owned, modifier.stat, modifier.kind, modifier.value)
	if def.effect_script != null:
		var made: Object = (def.effect_script as GDScript).new() if def.effect_script is GDScript else null
		var effect: ItemEffect = made as ItemEffect
		if effect == null:
			if made != null and not made is RefCounted:
				made.free()
			Log.error("items", "effect_script of %s does not extend ItemEffect" % def.id)
			assert(false, "effect_script must extend ItemEffect")
		else:
			effect.owned = owned
			owned.effect = effect
	_items.append(owned)
	if owned.effect != null:
		owned.effect.attach(_carrier)
	if def.active:
		active = owned
		active_changed.emit(owned)
	item_added.emit(owned)
	return owned


## Takes this copy away. False when it is not held.
func remove(owned: OwnedItem) -> bool:
	var index: int = _items.find(owned)
	if index == -1:
		return false
	_items.remove_at(index)
	var was_active: bool = owned == active
	if was_active:
		active = null
	_carrier.stats.clear_source(owned) # a freed source would stay a key of the stat block
	if owned.effect != null:
		owned.effect.detach()
	if was_active and not _swapping:
		active_changed.emit(null)
	item_removed.emit(owned)
	return true


## Attaches again the effects that were detached by detach_all().
func attach_all() -> void:
	for owned: OwnedItem in _items:
		if owned.effect != null and owned.effect.carrier == null:
			owned.effect.attach(_carrier)


## Detaches every effect without touching the stats or the list (the carrier leaves the tree).
func detach_all() -> void:
	for owned: OwnedItem in _items:
		if owned.effect != null:
			owned.effect.detach()


## Puts an active item in the slot (the former one is removed). charge < 0: a new item, fully charged. Returns the former
## active item (null when the slot was free), already removed: the caller lays it down with its charge.
func set_active(def: ItemDef, charge: int = -1) -> OwnedItem:
	var previous: OwnedItem = active
	_swapping = true
	if previous != null:
		remove(previous)
	add(def, charge)
	_swapping = false
	return previous


## Adds rooms of charge to the active item, up to its maximum. True when the charge changed.
func add_charge(amount: int) -> bool:
	if active == null or active.charge >= active.charge_max:
		return false
	active.charge = clampi(active.charge + amount, 0, active.charge_max)
	active_changed.emit(active)
	return true


## Sets the charge (use: 0, debug: full).
func set_charge(value: int) -> void:
	if active == null:
		return
	active.charge = clampi(value, 0, active.charge_max)
	active_changed.emit(active)
