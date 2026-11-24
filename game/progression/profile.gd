class_name Profile
extends RefCounted
## What persists between nights (profile.json, D12): statistics, first victories, achievements, unlocks.
## Versioned: from_dict() runs the migrations one version at a time. A file this game cannot read (damaged, no version,
## newer version) is quarantined by load_file() and the game starts with a new profile.

const SCHEMA_VERSION: int = 1
const FILE_NAME: String = "profile.json"
## Migrations, by the version they leave: _MIGRATIONS[1] turns a version 1 dictionary into a version 2 one.
## Empty today (one schema); the tests give their own table.
const MIGRATIONS: Dictionary[int, Callable] = {}

var runs: int = 0
var victories: int = 0
var deaths: int = 0
## Minute of the day of the last wake time, -1 before any run.
var last_wake_minute: int = -1
## Nightmare id -> statistics of the run that beat it first (seed, duration, items, wake_minute, date).
var first_victories: Dictionary[String, Dictionary] = {}
## Achievement id -> same fields.
var achievements: Dictionary[String, Dictionary] = {}
## Unlocked content ids. Empty at the MVP: nothing unlocks yet (act 1).
var unlocks: Array[StringName] = []

## True when the file was unreadable and moved aside: the game tells the player.
var was_corrupt: bool = false
## False when the file exists but could not be read (locked): it must not be overwritten this session.
var writable: bool = true


func to_dict() -> Dictionary:
	var unlock_ids: Array[String] = []
	for id: StringName in unlocks:
		unlock_ids.append(String(id))
	return {
		"schema_version": SCHEMA_VERSION,
		"stats": {"runs": runs, "victories": victories, "deaths": deaths, "last_wake_minute": last_wake_minute},
		"first_victories": first_victories,
		"achievements": achievements,
		"unlocks": unlock_ids,
	}


## The profile of data (after migration), or null when the data cannot be read.
static func from_dict(data: Dictionary, migrations: Dictionary = MIGRATIONS, current_version: int = SCHEMA_VERSION) -> Profile:
	var migrated: Dictionary = migrate(data, migrations, current_version)
	if migrated.is_empty():
		return null
	var profile: Profile = Profile.new()
	var stats: Variant = migrated.get("stats", {})
	if stats is Dictionary:
		var stats_dict: Dictionary = stats
		profile.runs = _int_of(stats_dict.get("runs"), 0)
		profile.victories = _int_of(stats_dict.get("victories"), 0)
		profile.deaths = _int_of(stats_dict.get("deaths"), 0)
		profile.last_wake_minute = _int_of(stats_dict.get("last_wake_minute"), -1)
	profile.first_victories = _entries_of(migrated.get("first_victories"))
	profile.achievements = _entries_of(migrated.get("achievements"))
	var raw_unlocks: Variant = migrated.get("unlocks", [])
	if raw_unlocks is Array:
		var unlock_list: Array = raw_unlocks
		for id: Variant in unlock_list:
			if typeof(id) == TYPE_STRING:
				var text: String = id
				profile.unlocks.append(StringName(text))
	return profile


## data brought to current_version by the migrations, or an empty Dictionary when it cannot be read: no integer
## schema_version, a version newer than the game, or a missing migration.
static func migrate(data: Dictionary, migrations: Dictionary = MIGRATIONS, current_version: int = SCHEMA_VERSION) -> Dictionary:
	var raw_version: Variant = data.get("schema_version")
	var version: int = -1
	if typeof(raw_version) == TYPE_INT:
		version = raw_version
	elif typeof(raw_version) == TYPE_FLOAT:
		var number: float = raw_version
		if is_equal_approx(floorf(number), number):
			version = int(number)
	if version < 1 or version > current_version:
		return {}
	var result: Dictionary = data.duplicate(true)
	while version < current_version:
		var step: Variant = migrations.get(version)
		if typeof(step) != TYPE_CALLABLE:
			Log.error("save", "no migration from profile version %d" % version)
			return {}
		var migration: Callable = step
		var next: Variant = migration.call(result)
		if typeof(next) != TYPE_DICTIONARY:
			return {}
		result = next
		version += 1
		result["schema_version"] = version
	return result


## Reads profile.json at path. A missing file gives a new profile; a damaged one is quarantined and gives a new profile
## with was_corrupt; a locked one gives a new profile that will not be written.
static func load_file(path: String) -> Profile:
	var data: Variant = SaveService.read_json(path)
	var status: SaveService.Status = SaveService.last_read_status
	var profile: Profile = null
	if data is Dictionary:
		var dict: Dictionary = data
		profile = from_dict(dict)
		if profile == null:
			status = SaveService.Status.CORRUPT if SaveService.quarantine(path) else SaveService.Status.UNREADABLE
	if profile == null:
		profile = Profile.new()
		profile.was_corrupt = status == SaveService.Status.CORRUPT
		profile.writable = status != SaveService.Status.UNREADABLE
	return profile


## Writes the profile atomically. False (and nothing written) when the existing file could not be read.
func save(path: String) -> bool:
	if not writable:
		return false
	return SaveService.write_json(path, to_dict())


## JSON gives every number as a float.
static func _int_of(value: Variant, default: int) -> int:
	if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
		var number: float = value
		return int(number)
	return default


static func _entries_of(value: Variant) -> Dictionary[String, Dictionary]:
	var result: Dictionary[String, Dictionary] = {}
	if value is Dictionary:
		var source: Dictionary = value
		for key: Variant in source:
			var entry: Variant = source[key]
			if typeof(key) == TYPE_STRING and typeof(entry) == TYPE_DICTIONARY:
				var name: String = key
				var fields: Dictionary = entry
				result[name] = _clean_entry(fields)
	return result


## One entry read back: the integers are integers again.
static func _clean_entry(entry: Dictionary) -> Dictionary:
	var cleaned: Dictionary = entry.duplicate(true)
	for key: String in ["duration", "wake_minute"]:
		if cleaned.has(key):
			cleaned[key] = _int_of(cleaned[key], -1)
	return cleaned
