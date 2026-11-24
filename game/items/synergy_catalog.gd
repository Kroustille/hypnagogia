class_name SynergyCatalog
extends RefCounted
## Every SynergyDef of res://data/synergies, valid ones only, sorted by threshold (then id).

const DIR: String = "res://data/synergies"


static func all() -> Array[SynergyDef]:
	var names: PackedStringArray = PackedStringArray()
	for file: String in DirAccess.get_files_at(DIR):
		var name: String = file.trim_suffix(".remap") # exported builds list "x.tres.remap"
		if name.ends_with(".tres"):
			names.append(name)
	names.sort()
	var found: Array[SynergyDef] = []
	for name: String in names:
		var def: SynergyDef = load(DIR.path_join(name)) as SynergyDef
		if def == null:
			Log.error("items", "%s is not a SynergyDef" % name)
			continue
		var problem: String = problem_of(def)
		if not problem.is_empty():
			Log.error("items", "synergy %s refused: %s" % [def.id, problem])
			assert(false, "Invalid SynergyDef: %s" % problem)
			continue
		found.append(def)
	found.sort_custom(func(a: SynergyDef, b: SynergyDef) -> bool:
		return a.threshold < b.threshold or (a.threshold == b.threshold and a.id < b.id))
	return found


## What is wrong with this definition, "" when it is fine.
static func problem_of(def: SynergyDef) -> String:
	if def == null:
		return "null definition"
	if def.id == &"" or def.tag == &"":
		return "needs an id and a tag"
	if def.threshold < 1:
		return "threshold must be at least 1"
	if def.name_key == &"" or def.description_key == &"":
		return "needs a name and a description key"
	if def.effect_script != null:
		var effect: SynergyEffect = make_effect(def)
		if effect == null:
			return "effect_script must be a script extending SynergyEffect"
		for key: StringName in effect.required_params():
			if not def.params.has(key):
				return "the effect needs the param %s" % key
	return ""


## A new effect for this synergy, null without a script or when the script is not a SynergyEffect.
static func make_effect(def: SynergyDef) -> SynergyEffect:
	if def.effect_script == null or not def.effect_script is GDScript:
		return null
	var made: Object = (def.effect_script as GDScript).new()
	var effect: SynergyEffect = made as SynergyEffect
	if effect == null and made != null and not made is RefCounted:
		made.free()
	return effect
