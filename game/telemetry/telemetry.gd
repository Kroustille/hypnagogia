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
## Wake time set just before run_ended (-1 none).
var _wake_minute: int = -1
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
	Events.run_seeded.connect(_on_events_run_seeded)
	Events.wake_time_set.connect(_on_events_wake_time_set)
	Events.run_ended.connect(_on_events_run_ended)
	Events.room_entered.connect(_on_events_room_entered)
	Events.lucidity_tier_changed.connect(_on_events_lucidity_tier_changed)
	Events.lucidity_spent.connect(_on_events_lucidity_spent)
	Events.item_acquired.connect(_on_events_item_acquired)
	Events.shards_changed.connect(_on_events_shards_changed)
	Events.shop_purchased.connect(_on_events_shop_purchased)
	Events.death_judged.connect(_on_events_death_judged)
	_write()


## Keeps the folder bounded: deletes the oldest session files (timestamped names) beyond the cap, leaving room for the new one.
## directory is a parameter so the checks can prune a folder of their own, away from the sessions of parallel runs.
func _prune_old_sessions(directory: String = DIRECTORY) -> void:
	var names: Array[String] = []
	for file_name: String in DirAccess.get_files_at(directory):
		if file_name.ends_with(".json"):
			names.append(file_name)
	names.sort()
	var excess: int = names.size() - (MAX_SESSION_FILES - 1)
	for i: int in range(maxi(excess, 0)):
		DirAccess.remove_absolute(directory.path_join(names[i]))


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


func _on_events_run_seeded(seed_code: String, seeded: bool) -> void:
	_session.run_seeded(seed_code, seeded)
	_write()


func _on_events_room_entered(room_id: StringName, cell_x: int, cell_y: int) -> void:
	_session.room_entered(_now(), String(room_id), Vector2i(cell_x, cell_y))
	_write()


func _on_events_lucidity_tier_changed(tier: int, _previous_tier: int) -> void:
	_session.tier_changed(_now(), tier)


func _on_events_lucidity_spent(power: StringName, _cost: int, tier: int) -> void:
	_session.spent(String(power), tier)


func _on_events_shards_changed(total: int) -> void:
	_session.shards_changed(total)


func _on_events_shop_purchased(item_id: StringName, price: int) -> void:
	_session.purchase(_now(), String(item_id), price)
	_write()


func _on_events_item_acquired(item_id: StringName, _copies: int) -> void:
	_session.item_taken(String(item_id))
	_write()


## Only a defeat is a death: the cause and the question "was it fair?" belong to it. A victory is its own event.
## An outcome unknown to this build is a defeat, as for the wake screen.
## The wake time arrives just before run_ended (story 6.6).
func _on_events_wake_time_set(minute: int) -> void:
	_wake_minute = minute


func _on_events_run_ended(outcome: int) -> void:
	var victory: bool = outcome == Run.Outcome.VICTORY
	var outcome_name: String = TelemetrySession.OUTCOME_VICTORY if victory else TelemetrySession.OUTCOME_DEATH
	var tiers: Array[float] = _session.run_ended(_now(), outcome_name, _wake_minute)
	_wake_minute = -1
	if not tiers.is_empty():
		Log.info("lucidity", "time per tier (s) %s" % [TelemetrySession.tier_dict(tiers)])
	if victory:
		_session.victory(_now())
	else:
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
