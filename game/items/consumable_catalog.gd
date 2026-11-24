class_name ConsumableCatalog
extends RefCounted
## Every ConsumableDef of res://data/consumables, sorted by file name, invalid ones refused (logged, asserted in debug).

const DIR: String = "res://data/consumables"


static func all() -> Array[ConsumableDef]:
	var names: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(DIR):
		var name: String = file.trim_suffix(".remap") # exported builds list "x.tres.remap"
		if name.ends_with(".tres"):
			names.append(name)
	names.sort()
	var found: Array[ConsumableDef] = []
	var seen: Dictionary[StringName, bool] = {}
	for name: String in names:
		var def: ConsumableDef = load(DIR.path_join(name)) as ConsumableDef
		if def == null:
			Log.error("items", "%s is not a ConsumableDef" % name)
			continue
		if not validate(def):
			continue
		if seen.has(def.id):
			Log.error("items", "consumable %s refused: id already used" % def.id)
			assert(false, "Duplicate ConsumableDef id")
			continue
		seen[def.id] = true
		found.append(def)
	return found


static func by_id(id: StringName) -> ConsumableDef:
	for def: ConsumableDef in all():
		if def.id == id:
			return def
	return null


## What is wrong with this definition, "" when it is fine.
static func problem_of(def: ConsumableDef) -> String:
	if def == null:
		return "null definition"
	if def.id == &"":
		return "no id"
	if def.name_key == &"" or def.bonus_key == &"" or def.cost_key == &"":
		return "needs a name, a bonus and a cost key"
	var effect: ConsumableEffect = make_effect(def)
	if effect == null:
		return "effect_script missing or not a ConsumableEffect"
	for key: StringName in effect.required_params():
		if not def.params.has(key):
			return "missing param %s" % key
	return ""


static func validate(def: ConsumableDef) -> bool:
	var problem: String = problem_of(def)
	if problem.is_empty():
		return true
	Log.error("items", "consumable %s refused: %s" % [def.id if def != null else &"?", problem])
	assert(false, "Invalid ConsumableDef: %s" % problem)
	return false


## A new effect of the definition, null when its script is missing or of the wrong kind.
static func make_effect(def: ConsumableDef) -> ConsumableEffect:
	if def.effect_script == null:
		return null
	var made: Object = (def.effect_script as GDScript).new()
	var effect: ConsumableEffect = made as ConsumableEffect
	if effect != null:
		effect.def = def
	return effect
