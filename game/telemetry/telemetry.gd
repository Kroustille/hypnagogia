extends Node
## Playtest telemetry (story 2.8, AR25). Listens to Events only: no system calls it, nothing depends on it.
## Writes user://telemetry/<session>.json after every event (small file, nothing lost on a crash).
## Not behind OS.is_debug_build(): it ships in the builds sent to friends. Uses the real clock, never GameClock
## (answers arrive while the game is frozen).

const DIRECTORY: String = "user://telemetry"

var _session: TelemetrySession
var _path: String = ""
var _start_msec: int = 0
var _last_hit_source: int = -1
var _ended: bool = false


func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	var stamp: String = Time.get_datetime_string_from_system().replace("-", "").replace(":", "").replace("T", "-")
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var session_id: String = stamp
	var n: int = 1
	while FileAccess.file_exists("%s/%s.json" % [DIRECTORY, session_id]):
		n += 1
		session_id = "%s-%d" % [stamp, n]
	_path = "%s/%s.json" % [DIRECTORY, session_id]
	_session = TelemetrySession.new(session_id)
	_session.start(0.0)
	Events.player_hit.connect(_on_events_player_hit)
	Events.run_started.connect(_on_events_run_started)
	Events.run_ended.connect(_on_events_run_ended)
	Events.death_judged.connect(_on_events_death_judged)
	_write()


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


func _on_events_run_ended(_outcome: int) -> void:
	var cause: String = "unknown"
	var names: Array[String] = []
	names.assign(DamageInfo.Source.keys())
	if _last_hit_source >= 0 and _last_hit_source < names.size():
		cause = names[_last_hit_source].to_lower()
	_session.death(_now(), cause)
	_write()


func _on_events_death_judged(just: bool) -> void:
	if _session.answer(_now(), just):
		_write()


func _write() -> void:
	if _ended and _session.events.back()["type"] != "session_end":
		return
	var file: FileAccess = FileAccess.open(_path, FileAccess.WRITE)
	if file == null:
		Log.warn("run", "telemetry file not writable: %s" % _path)
		return
	file.store_string(JSON.stringify(_session.to_dict(_now()), "\t"))
