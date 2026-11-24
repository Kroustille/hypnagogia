class_name ConsumableCatalog
extends RefCounted
## Every ConsumableDef of res://data/consumables, sorted by file name, invalid ones refused (logged, asserted in debug).

const DIR: String = "res://data/consumables"

## The files of the valid definitions, found and checked on the first call only. Resources are not cached here (a static
## array of them is reported as leaked at exit): load() keeps its own cache.
static var _valid_paths: PackedStringArray = PackedStringArray()
static var _scanned: bool = false


static func all() -> Array[ConsumableDef]:
	if not _scanned:
		_scan()
	var found: Array[ConsumableDef] = []
	for path: String in _valid_paths:
		var def: ConsumableDef = load(path) as ConsumableDef
		if def != null:
			found.append(def)
	return found


static func by_id(id: StringName) -> ConsumableDef:
	for def: ConsumableDef in all():
		if def.id == id:
			return def
	return null


static func _scan() -> void:
	var names: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(DIR):
		var name: String = file.trim_suffix(".remap") # exported builds list "x.tres.remap"
		if name.ends_with(".tres"):
			names.append(name)
	names.sort()
	var valid: PackedStringArray = PackedStringArray()
	var seen: Dictionary[StringName, bool] = {}
	for name: String in names:
		var path: String = DIR.path_join(name)
		var def: ConsumableDef = load(path) as ConsumableDef
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
		valid.append(path)
	_valid_paths = valid
	_scanned = true


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
		if def.params[key] <= 0.0:
			return "param %s must be above 0" % key
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
	var script: GDScript = def.effect_script as GDScript
	if script == null or script.get_instance_base_type() != &"RefCounted" and not ClassDB.is_parent_class(script.get_instance_base_type(), &"RefCounted"):
		return null # not a GDScript, or an instance that nobody would free
	var made: Object = script.new()
	var effect: ConsumableEffect = made as ConsumableEffect
	if effect != null:
		effect.def = def
	return effect
