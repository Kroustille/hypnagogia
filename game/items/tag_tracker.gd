class_name TagTracker
extends RefCounted
## Counts, per tag, the DISTINCT item ids held: two copies of the same item count once. Also decides which synergy
## level is active per tag (story 5.7): the highest threshold reached; a higher level replaces the lower one.

## The number of distinct items of a tag changed.
signal tag_count_changed(tag: StringName, count: int)
## A synergy level became the active one of its tag (also when it comes back after a removal: announcing it only the
## first time is the carrier's business).
signal synergy_activated(def: SynergyDef)
## A synergy level stopped being active (an item was removed, or a higher level replaced it). Emitted before the
## activation of the level that replaces it.
signal synergy_deactivated(def: SynergyDef)

## tag -> distinct item ids held
var _counts: Dictionary[StringName, int] = {}
## item id -> copies held
var _copies: Dictionary[StringName, int] = {}
## Every synergy.
var _synergies: Array[SynergyDef]
## tag -> the active synergy level
var _active: Dictionary[StringName, SynergyDef] = {}


## synergies: by default every SynergyDef of the catalog.
func _init(loadout: Loadout, synergies: Array[SynergyDef] = SynergyCatalog.all()) -> void:
	_synergies = synergies
	loadout.item_added.connect(_on_item_added)
	loadout.item_removed.connect(_on_item_removed)


func count(tag: StringName) -> int:
	return _counts.get(tag, 0)


## The active level of the tag, null when none.
func active_synergy(tag: StringName) -> SynergyDef:
	return _active.get(tag)


func _on_item_added(owned: OwnedItem) -> void:
	var id: StringName = owned.def.id
	_copies[id] = _copies.get(id, 0) + 1
	if _copies[id] == 1:
		_shift(owned.def, 1)


func _on_item_removed(owned: OwnedItem) -> void:
	var id: StringName = owned.def.id
	_copies[id] = _copies.get(id, 0) - 1
	if _copies[id] <= 0:
		_copies.erase(id)
		_shift(owned.def, -1)


func _shift(def: ItemDef, step: int) -> void:
	for tag: StringName in def.tags:
		var now: int = _counts.get(tag, 0) + step
		_counts[tag] = now
		tag_count_changed.emit(tag, now)
		_update_synergy(tag, now)


func _update_synergy(tag: StringName, now: int) -> void:
	var best: SynergyDef = null
	for def: SynergyDef in _synergies:
		if def.tag == tag and def.threshold <= now and (best == null or def.threshold > best.threshold):
			best = def
	var previous: SynergyDef = _active.get(tag)
	if best == previous:
		return
	if previous != null:
		_active.erase(tag)
		synergy_deactivated.emit(previous)
	if best != null:
		_active[tag] = best
		synergy_activated.emit(best)
