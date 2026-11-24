class_name Achievements
extends Node
## Keeps the first victories and the achievements of the profile (story 6.7), and the statistics of the runs. Listens to
## Events only, writes profile.json at each new entry and once at the end of a run.
## A run on a typed seed records nothing (AR29). Nothing is unlocked here: the profile unlocks stay empty at the MVP.

const ACHIEVEMENT_TOTAL_ABANDON_ROOM: StringName = &"total_abandon_room"
const ACHIEVEMENT_SYNERGY_THREE: StringName = &"synergy_three"
## Distinct items of a synergy that make the "synergy_three" achievement.
const SYNERGY_THREE_THRESHOLD: int = 3
## The nightmare whose first victory is recorded (the only boss of the MVP).
const DEFAULT_BOSS: StringName = &"professor"

var profile: Profile
var _path: String = ""
## State of the run in progress, reset by run_started.
var _seeded: bool = false
var _seed_code: String = ""
var _items: Array[String] = []
var _started_msec: int = 0
var _wake_minute: int = -1
var _boss_beaten: StringName = &""


## Dependency injection, before add_child(): the profile to fill and the file to write.
func setup(owned_profile: Profile, path: String) -> void:
	profile = owned_profile
	_path = path


func _ready() -> void:
	Events.run_started.connect(_on_run_started)
	Events.run_seeded.connect(_on_run_seeded)
	Events.item_acquired.connect(_on_item_acquired)
	Events.boss_defeated.connect(_on_boss_defeated)
	Events.room_cleared.connect(_on_room_cleared)
	Events.synergy_activated.connect(_on_synergy_activated)
	Events.wake_time_set.connect(_on_wake_time_set)
	Events.run_ended.connect(_on_run_ended)


func _on_run_started() -> void:
	_seeded = false
	_seed_code = ""
	_items.clear()
	_started_msec = Time.get_ticks_msec()
	_wake_minute = -1
	_boss_beaten = &""


func _on_run_seeded(seed_code: String, seeded: bool) -> void:
	_seed_code = seed_code
	_seeded = seeded


func _on_item_acquired(item_id: StringName, _copies: int) -> void:
	if not _items.has(String(item_id)):
		_items.append(String(item_id))


func _on_boss_defeated(boss_id: StringName) -> void:
	_boss_beaten = boss_id # recorded when the run ends in victory (run_ended), not here


func _on_room_cleared(_room: Node, lowest_tier: int) -> void:
	if lowest_tier == Lucidity.Tier.TOTAL_ABANDON:
		_obtain(ACHIEVEMENT_TOTAL_ABANDON_ROOM)


func _on_synergy_activated(_synergy_id: StringName, threshold: int) -> void:
	if _seed_code.is_empty():
		return # no run_seeded yet: synergies put back by a resume, counted in the night they were reached
	if threshold >= SYNERGY_THREE_THRESHOLD:
		_obtain(ACHIEVEMENT_SYNERGY_THREE)


func _on_wake_time_set(minute: int) -> void:
	_wake_minute = minute


## Statistics of the run (not for a seeded one), the first victory on a win, then one write.
func _on_run_ended(outcome: int) -> void:
	_record_run_end(outcome)
	_seed_code = "" # a later resume replays its synergies before run_seeded: they must not count


func _record_run_end(outcome: int) -> void:
	if _seeded or profile == null:
		return
	profile.runs += 1
	if outcome == Run.Outcome.VICTORY:
		profile.victories += 1
		var boss: StringName = _boss_beaten if _boss_beaten != &"" else DEFAULT_BOSS
		if not profile.first_victories.has(String(boss)):
			profile.first_victories[String(boss)] = _run_entry()
			Log.info("save", "first victory over %s recorded" % boss)
	else:
		profile.deaths += 1
	if _wake_minute >= 0:
		profile.last_wake_minute = _wake_minute
	_save()


## Records an achievement the first time only, and writes the profile at once.
func _obtain(id: StringName) -> void:
	if _seeded or profile == null or profile.achievements.has(String(id)):
		return
	profile.achievements[String(id)] = _run_entry()
	Log.info("save", "achievement %s recorded" % id)
	_save()


## Statistics of the run so far. The wake time is known at the end of a run only: -1 before.
func _run_entry() -> Dictionary:
	return {
		"seed": _seed_code,
		"duration": _duration_seconds(),
		"items": _items.duplicate(),
		"wake_minute": _wake_minute,
		"date": Time.get_datetime_string_from_system(true),
	}


## Seconds played in the night: what the run counted (pauses excluded, a resumed night included), else the wall clock.
func _duration_seconds() -> int:
	var run: Run = get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run if is_inside_tree() else null
	if run != null:
		return int(run.state.play_seconds)
	return maxi(0, Time.get_ticks_msec() - _started_msec) / 1000


func _save() -> void:
	if not _path.is_empty():
		profile.save(_path)
