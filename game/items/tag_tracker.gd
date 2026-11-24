class_name TagTracker
extends RefCounted
## Counts, per tag, the DISTINCT item ids held: two copies of the same item count once (synergy thresholds, story 5.7).

## The number of distinct items of a tag changed.
signal tag_count_changed(tag: StringName, count: int)

## tag -> distinct item ids held
var _counts: Dictionary[StringName, int] = {}
## item id -> copies held
var _copies: Dictionary[StringName, int] = {}


func _init(loadout: Loadout) -> void:
	loadout.item_added.connect(_on_item_added)
	loadout.item_removed.connect(_on_item_removed)


func count(tag: StringName) -> int:
	return _counts.get(tag, 0)


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
