class_name ItemCatalog
extends RefCounted
## Every ItemDef of res://data/items, sorted by path, invalid ones refused (logged, asserted in debug builds).

const DIR: String = "res://data/items"


## The valid definitions, sorted by file name.
static func all() -> Array[ItemDef]:
	return _load(DIR, true) # no static cache: a static array of Resources is reported as leaked at exit


static func by_id(id: StringName) -> ItemDef:
	for def: ItemDef in all():
		if def.id == id:
			return def
	return null


## Every file of the folder, valid or not (checks); nothing is reported.
static func load_unchecked(dir: String = DIR) -> Array[ItemDef]:
	return _load(dir, false)


## What is wrong with this definition, "" when it is fine.
static func problem_of(def: ItemDef) -> String:
	if def == null:
		return "null definition"
	if def.id == &"":
		return "no id"
	if def.name_key == &"" or def.bonus_key == &"" or def.cost_key == &"":
		return "needs a name, a bonus and a cost key"
	if def.max_half_hearts_delta > 0:
		return "a positive max_half_hearts_delta is not handled (the item would give nothing)"
	var tags_seen: Dictionary[StringName, bool] = {}
	for tag: StringName in def.tags:
		if tags_seen.has(tag):
			return "duplicate tag %s (it would be counted twice)" % tag
		tags_seen[tag] = true
	var seen: Dictionary[int, bool] = {}
	for modifier: ModifierDef in def.modifiers:
		if modifier == null:
			return "null modifier"
		if seen.has(modifier.stat):
			return "two modifiers on the same stat (a source holds one per stat)"
		seen[modifier.stat] = true
	if def.effect_script != null:
		var made: Object = (def.effect_script as GDScript).new() if def.effect_script is GDScript else null
		var effect: ItemEffect = made as ItemEffect
		if effect == null:
			if made != null and not made is RefCounted:
				made.free()
			return "effect_script must be a script extending ItemEffect"
		for key: StringName in effect.required_params():
			if not def.params.has(key):
				return "the effect needs the param %s" % key
	return ""


## problem_of() with the report: an error in the journal and an assert in debug builds. True when valid.
static func validate(def: ItemDef) -> bool:
	var problem: String = problem_of(def)
	if problem.is_empty():
		return true
	Log.error("items", "item %s refused: %s" % [def.id if def != null else &"?", problem])
	assert(false, "Invalid ItemDef: %s" % problem)
	return false


static func _load(dir: String, check: bool) -> Array[ItemDef]:
	var names: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(dir):
		var name: String = file.trim_suffix(".remap") # exported builds list "x.tres.remap"
		if name.ends_with(".tres"):
			names.append(name)
	names.sort()
	var found: Array[ItemDef] = []
	var ids_seen: Dictionary[StringName, bool] = {}
	for name: String in names:
		var def: ItemDef = load(dir.path_join(name)) as ItemDef
		if def == null:
			if check:
				Log.error("items", "%s is not an ItemDef" % name)
			continue
		if check and not validate(def):
			continue
		if check and not _register_id(def, ids_seen):
			continue
		found.append(def)
	return found


## True the first time an id is seen; a repeated id is reported (journal + assert in debug builds) and refused.
static func _register_id(def: ItemDef, ids_seen: Dictionary[StringName, bool]) -> bool:
	if not is_new_id(def, ids_seen):
		Log.error("items", "item %s refused: id already used by another definition" % def.id)
		assert(false, "Duplicate ItemDef id")
		return false
	return true


## Records the id of def in ids_seen; false when it was already there.
static func is_new_id(def: ItemDef, ids_seen: Dictionary[StringName, bool]) -> bool:
	if ids_seen.has(def.id):
		return false
	ids_seen[def.id] = true
	return true
