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
	var seen: Dictionary[int, bool] = {}
	for modifier: ModifierDef in def.modifiers:
		if modifier == null:
			return "null modifier"
		if seen.has(modifier.stat):
			return "two modifiers on the same stat (a source holds one per stat)"
		seen[modifier.stat] = true
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
	for name: String in names:
		var def: ItemDef = load(dir.path_join(name)) as ItemDef
		if def == null:
			if check:
				Log.error("items", "%s is not an ItemDef" % name)
			continue
		if check and not validate(def):
			continue
		found.append(def)
	return found
