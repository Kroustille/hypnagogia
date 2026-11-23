extends Node
## Playtest telemetry (story 2.8, AR25). Listens to Events only: no system calls it, nothing depends on it.
## Writes user://telemetry/<session>.json after every event (small file, nothing lost on a crash).
## Not behind OS.is_debug_build(): it ships in the builds sent to friends. Uses the real clock, never GameClock
## (answers arrive while the game is frozen).

const DIRECTORY: String = "user://telemetry"
const MAX_SESSION_FILES: int = 100

var _session: TelemetrySession
var _path: String = ""
var _start_msec: int = 0
var _last_hit_source: int = -1
var _ended: bool = false
var _disabled: bool = false


func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	var stamp: String = Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
	var dir_err: Error = DirAccess.make_dir_recursive_absolute(DIRECTORY)
	if dir_err != OK:
		Log.warn("save", "telemetry directory not writable (error %d): telemetry disabled" % dir_err)
		_disabled = true
	else:
		_prune_old_sessions()
	var base_id: String = "%s-%d" % [stamp, OS.get_process_id()]
	var session_id: String = base_id
	var n: int = 1
	while FileAccess.file_exists("%s/%s.json" % [DIRECTORY, session_id]):
		n += 1
		session_id = "%s-%d" % [base_id, n]
	_path = "%s/%s.json" % [DIRECTORY, session_id]
	_session = TelemetrySession.new(session_id)
	_session.start(0.0)
	Events.player_hit.connect(_on_events_player_hit)
	Events.run_started.connect(_on_events_run_started)
	Events.run_ended.connect(_on_events_run_ended)
	Events.lucidity_tier_changed.connect(_on_events_lucidity_tier_changed)
	Events.death_judged.connect(_on_events_death_judged)
	_write()


## Keeps the folder bounded: deletes the oldest session files (timestamped names) beyond the cap, leaving room for the new one.
func _prune_old_sessions() -> void:
	var names: Array[String] = []
	for file_name: String in DirAccess.get_files_at(DIRECTORY):
		if file_name.ends_with(".json"):
			names.append(file_name)
	names.sort()
	var excess: int = names.size() - (MAX_SESSION_FILES - 1)
	for i: int in range(maxi(excess, 0)):
		DirAccess.remove_absolute(DIRECTORY.path_join(names[i]))


func session_path() -> String:
	return _path


## Closes the session (idempotent): called on quit, also callable by checks.
func end_session() -> void:
	if _ended or _session == null:
		return
	_ended = true
	_session.end(_now())
	_write()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		end_session()


func _exit_tree() -> void:
	end_session()


func _now() -> float:
	return (Time.get_ticks_msec() - _start_msec) / 1000.0


func _on_events_player_hit(_damage: int, source: int) -> void:
	_last_hit_source = source


func _on_events_run_started() -> void:
	_last_hit_source = -1
	_session.run_started(_now())
	_write()


func _on_events_lucidity_tier_changed(tier: int, _previous_tier: int) -> void:
	_session.tier_changed(_now(), tier)


func _on_events_run_ended(_outcome: int) -> void:
	var tiers: Array[float] = _session.run_ended(_now())
	if not tiers.is_empty():
		Log.info("lucidity", "time per tier (s) %s" % [TelemetrySession.tier_dict(tiers)])
	var key: Variant = DamageInfo.Source.find_key(_last_hit_source)
	var cause: String = str(key).to_lower() if key != null else "unknown"
	_session.death(_now(), cause)
	_write()


func _on_events_death_judged(just: bool) -> void:
	if _session.answer(_now(), just):
		_write()


func _write() -> void:
	if _disabled or (_ended and _session.events.back()["type"] != "session_end"):
		return
	var tmp_path: String = _path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		Log.warn("save", "telemetry file not writable: %s (telemetry disabled)" % tmp_path)
		_disabled = true
		return
	var ok: bool = file.store_string(JSON.stringify(_session.to_dict(_now()), "\t"))
	file.close()
	if not ok:
		Log.warn("save", "telemetry write failed: %s (telemetry disabled)" % tmp_path)
		_disabled = true
		return
	var err: Error = DirAccess.rename_absolute(tmp_path, _path)
	if err != OK:
		Log.warn("save", "telemetry rename failed (error %d): telemetry disabled" % err)
		_disabled = true
