class_name SoakRunner
extends Node
## Stability soak of milestone B (story 6.9): plays 20 whole nights in a row against the real Main, from the bedroom,
## headless and faster than real time (tools/soak.sh, --fixed-fps 60). Not a test of play: it proves nothing about balance
## or readability, it looks for crashes, errors and leaks. Every wait is counted in physics ticks (simulated), never in
## wall-clock time; the only wall-clock figure is the safety bound of the whole soak (SOAK_MAX_SECONDS).
##
## One night: the real bed (or "sleep again", or a typed seed) -> every combat room of the way to the nightmare, by the
## real doors -> the real fight of The Professor with simulated hits (the pop quiz on every other night) -> a victory, or a
## death in a room, during the announce, or in the fight. Between two nights: the wake screen, the bedroom, a direct restart.
## Env: SOAK_RUNS (default 20), SOAK_MAX_SECONDS (default 600). Exit code 0 when every check holds, 1 otherwise.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")

## The seeds typed on the nights that start from a typed seed (one in two of the others use a random seed, logged).
const SEEDS: Array[int] = [
	20260524, 777, 13579, 99999, 314159, 271828, 8675309, 4242424, 1, 42,
	123456, 654321, 2468, 1357, 808017, 31337, 5150, 9001, 1618033, 2718281,
]
## How the night ends, run by run: 10 victories, 4 deaths in a room, 3 during the announce, 3 in the fight.
const PLAN: Array[String] = [
	"victory", "death_room", "victory", "death_boss", "victory",
	"death_announce", "victory", "death_room", "victory", "victory",
	"death_boss", "victory", "death_room", "victory", "death_announce",
	"victory", "death_boss", "death_room", "death_announce", "victory",
]
## How a night is started: the bed, "sleep again" on the wake screen, a seed typed from the bedroom, a seed typed from the wake screen.
enum Start { BED, RESTART, TYPED_BEDROOM, TYPED_WAKE }

const AT_BED: Vector2 = Vector2(64, 122)
const RUN_COUNT_DEFAULT: int = 20
const SAFETY_SECONDS_DEFAULT: int = 600
const ROOM_WAIT_TICKS: int = 400
const TRAVEL_WAIT_TICKS: int = 400
const BOSS_APPEAR_TICKS: int = 900
const FIGHT_TICKS: int = 2400
const WAKE_WAIT_TICKS: int = 200
const BOSS_HIT_DAMAGE: float = 200.0
const BOSS_HIT_EVERY_TICKS: int = 12
## Budgets (NFR3 and the direct restart), in ms of wall-clock time and in simulated ticks.
const LOAD_BUDGET_MSEC: int = 2000
const RESTART_BUDGET_MSEC: int = 3000
const RESTART_BUDGET_TICKS: int = 180
## Margins around what the first run of each kind holds: the resource caches grow legitimately with the rooms met.
const OBJECT_MARGIN: int = 300
const NODE_MARGIN: int = 20
const ORPHAN_MARGIN: int = 5
## Static memory may not climb past this share of what the first runs hold, from the first fifth of the soak to the last.
const MEMORY_GROWTH_LIMIT: float = 1.5

class Sample extends RefCounted:
	var objects: int = 0
	var nodes: int = 0
	var orphans: int = 0
	var memory_mb: float = 0.0

class Night extends RefCounted:
	var index: int = 0
	var start: Start = Start.BED
	var plan: String = ""
	var seed_code: String = ""
	var outcome: String = ""
	var wake: String = ""
	var duration_seconds: float = 0.0
	var load_ms: int = -1
	var start_ticks: int = 0
	var rooms_cleared: int = 0
	var boss_reached: bool = false
	var max_bullets: int = 0
	var refused_bullets: int = 0
	var sample: Sample = Sample.new()

var _main: Main
var _nights: Array[Night] = []
var _failures: PackedStringArray = PackedStringArray()
var _run_ended: int = -1
var _wake_minute: int = -1
var _started: bool = false
var _load_ms: int = -1
var _start_msec: int = 0
var _max_seconds: int = SAFETY_SECONDS_DEFAULT
var _save_dir: DirAccess
var _answered_runs: int = 0
## Nights that reached the boss, and the pop quizzes announced on the blackboard.
var _boss_nights: int = 0
var _quizzes: int = 0


func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	var runs_text: String = OS.get_environment("SOAK_RUNS")
	var count: int = int(runs_text) if runs_text.is_valid_int() else RUN_COUNT_DEFAULT
	var max_text: String = OS.get_environment("SOAK_MAX_SECONDS")
	_max_seconds = int(max_text) if max_text.is_valid_int() else SAFETY_SECONDS_DEFAULT
	_run_soak.call_deferred(count)


func _run_soak(count: int) -> void:
	_save_dir = DirAccess.create_temp("hypnagogia_soak", true)
	if _save_dir == null:
		push_error("soak: cannot create the temporary save folder")
		get_tree().quit(1)
		return
	SaveService.set_directory(_save_dir.get_current_dir()) # never the profile of the player
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true) # audio keeps real time: silence it
	Events.run_ended.connect(_on_events_run_ended)
	Events.wake_time_set.connect(_on_events_wake_time_set)
	Events.run_started.connect(_on_events_run_started)
	Events.floor_ready.connect(_on_events_floor_ready)
	Events.boss_announced.connect(_on_events_boss_announced)
	Main.start_in_bedroom = true
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await _ticks(5)
	for index: int in count:
		var night: Night = Night.new()
		night.index = index
		night.plan = PLAN[index % PLAN.size()]
		night.start = (index % 4) as Start
		_nights.append(night)
		await _play(night)
		if _out_of_time() or not _failures.is_empty():
			break
	await _finish()


# --- one night -----------------------------------------------------------------------------------------------------


func _play(night: Night) -> void:
	_run_ended = -1
	_wake_minute = -1
	await _start_night(night)
	var run: Run = _run()
	if run == null:
		_fail(night, "no run after the start")
		return
	night.seed_code = run.rng.seed_code()
	night.load_ms = _load_ms
	await _ticks(3)
	night.sample = _sample()
	var player: Player = _player()
	player.health.set_forced_invulnerability(true) # the soak looks for crashes, not for the game balance
	var path: Array[Vector2i] = _path_to_nightmare(run)
	if path.is_empty():
		_fail(night, "no way to the nightmare room")
		return
	var rooms_before_death: int = 1 + night.index % 3 # a death in a room: the first, second or third of the way
	for step: Vector2i in path:
		if not await _walk_to(run, step, night):
			return
		var room: Room = run.current_room()
		if room.room_type == Room.RoomType.COMBAT:
			if night.plan == "death_room" and night.rooms_cleared + 1 >= rooms_before_death:
				await _ticks(20)
				await _kill_player(night)
				break
			await _clear_room(room, night)
			night.rooms_cleared += 1
	if night.plan != "death_room":
		await _fight_boss(run, night)
	await _wait_for_end(night)
	_finish_night(night)


## The way to the nightmare room by the doors: the cells to cross after the start room, the nightmare room last.
func _path_to_nightmare(run: Run) -> Array[Vector2i]:
	var layout: FloorLayout = run.floor_layout
	var targets: Array[Vector2i] = layout.cells_of_type(Room.RoomType.NIGHTMARE)
	var steps: Array[Vector2i] = []
	if targets.is_empty():
		return steps
	var from: Vector2i = layout.start
	var came_from: Dictionary[Vector2i, Vector2i] = {from: from}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty() and not came_from.has(targets[0]):
		var cell: Vector2i = queue.pop_front()
		for neighbor: Vector2i in layout.neighbors(cell):
			if not came_from.has(neighbor):
				came_from[neighbor] = cell
				queue.append(neighbor)
	if not came_from.has(targets[0]):
		return steps
	var cursor: Vector2i = targets[0]
	while cursor != from:
		steps.push_front(cursor)
		cursor = came_from[cursor]
	return steps


func _walk_to(run: Run, cell: Vector2i, night: Night) -> bool:
	var side: int = FloorLayout.side_towards(run.current_cell(), cell)
	run.travel(side)
	var arrived: bool = await _until(func() -> bool: return not run.is_traveling() and run.current_cell() == cell and run.current_room() != null, TRAVEL_WAIT_TICKS)
	if not arrived:
		_fail(night, "the trip to %s did not end" % cell)
	return arrived


## Empties a room by the debug tools, through the wave runner: its fight is won, its doors open, room_cleared goes out.
func _clear_room(room: Room, night: Night) -> void:
	var runner: WaveRunner = room.wave_runner()
	if runner == null:
		return
	for attempt: int in ROOM_WAIT_TICKS:
		if runner.state_name() == "DONE" or runner.state_name() == "IDLE":
			break
		runner.force_next_wave()
		await _ticks(2)
	await _ticks(2)
	night.max_bullets = maxi(night.max_bullets, room.enemy_bullets().active_count)
	night.refused_bullets += room.enemy_bullets().refused_count
	if not room.is_cleared():
		_fail(night, "room %s was not cleared" % room.name)


## The real fight: the Professor appears, announces, and takes simulated hits through the three phases.
func _fight_boss(run: Run, night: Night) -> void:
	var room: Room = run.current_room()
	await _until(func() -> bool: return _find_boss(room) != null, BOSS_APPEAR_TICKS)
	var boss: Boss = _find_boss(room)
	if boss == null:
		_fail(night, "the boss did not appear")
		return
	night.boss_reached = true
	var player: Player = _player()
	var quiz: bool = _boss_nights % 2 == 1
	_boss_nights += 1
	if quiz:
		player.lucidity.set_value(0) # the room reaches Total abandon: the pop quiz joins the fight
	if night.plan == "death_announce":
		await _ticks(10)
		await _kill_player(night)
		return
	var tick: int = 0
	while _run_ended < 0 and is_instance_valid(boss) and not boss.is_dead() and tick < FIGHT_TICKS:
		await _ticks(1)
		tick += 1
		night.max_bullets = maxi(night.max_bullets, room.enemy_bullets().active_count)
		if tick % BOSS_HIT_EVERY_TICKS == 0 and boss.is_fighting():
			boss.hurtbox.receive(DamageInfo.from_bullet(BOSS_HIT_DAMAGE, Vector2.UP, DamageInfo.Source.PLAYER_SHOT))
		if night.plan == "death_boss" and boss.hp_share() < 0.6:
			await _kill_player(night)
			return
	night.refused_bullets += room.enemy_bullets().refused_count
	if night.plan == "victory" and (not is_instance_valid(boss) or not boss.is_dead()):
		_fail(night, "the boss did not die within %d ticks" % FIGHT_TICKS)


func _find_boss(room: Room) -> Boss:
	for child: Node in room.get_node("Enemies").get_children():
		var boss: Boss = child as Boss
		if boss != null and not boss.is_queued_for_deletion():
			return boss
	return null


func _kill_player(night: Night) -> void:
	var player: Player = _player()
	if player == null:
		return
	player.health.set_forced_invulnerability(false)
	player.health.half_hearts = 1
	for attempt: int in 10:
		player.hurtbox.receive(DamageInfo.from_bullet(1.0, Vector2.RIGHT, DamageInfo.Source.CONTACT))
		await _ticks(2)
		if _run_ended >= 0:
			return
	_fail(night, "the player could not be killed")


func _wait_for_end(night: Night) -> void:
	var ended: bool = await _until(func() -> bool: return _run_ended >= 0, FIGHT_TICKS)
	if not ended:
		_fail(night, "the night did not end")
		return
	night.outcome = "victory" if _run_ended == Run.Outcome.VICTORY else "death"
	var wanted: String = "victory" if night.plan == "victory" else "death"
	if night.outcome != wanted:
		_fail(night, "expected %s, got %s" % [wanted, night.outcome])


func _finish_night(night: Night) -> void:
	night.wake = WakeClock.format(_wake_minute) if _wake_minute >= 0 else "?"
	var details: Array[Dictionary] = Telemetry.session().runs_detail
	if not details.is_empty():
		night.duration_seconds = float(str(details.back()["duration_seconds"]))
	if night.outcome == "death" and night.index % 2 == 0:
		Events.death_judged.emit(night.index % 4 == 0) # the question of the wake screen, answered
		_answered_runs += 1
	if night.load_ms > (LOAD_BUDGET_MSEC if night.start == Start.BED else RESTART_BUDGET_MSEC):
		_fail(night, "floor ready in %d ms" % night.load_ms)
	if night.start == Start.RESTART and night.start_ticks > RESTART_BUDGET_TICKS:
		_fail(night, "restart took %d ticks" % night.start_ticks)
	Log.info("run", "soak: run %2d done seed=%s %s plan=%s" % [night.index + 1, night.seed_code, night.outcome, night.plan])


# --- starting a night ----------------------------------------------------------------------------------------------


func _start_night(night: Night) -> void:
	_started = false
	_load_ms = -1
	if night.index == 0:
		night.start = Start.BED
	if night.start == Start.RESTART:
		await _on_wake_screen()
		var pressed_at: int = Engine.get_physics_frames()
		(_wake().get_node("%RestartButton") as Button).pressed.emit()
		await _until(func() -> bool: return _started, RESTART_BUDGET_TICKS + 60)
		night.start_ticks = Engine.get_physics_frames() - pressed_at
	elif night.start == Start.TYPED_WAKE:
		await _on_wake_screen()
		var requested_at: int = Engine.get_physics_frames()
		Events.run_requested.emit(RunOptions.Mode.FLOOR, SEEDS[night.index % SEEDS.size()], true, "")
		await _until(func() -> bool: return _started, RESTART_BUDGET_TICKS + 60)
		night.start_ticks = Engine.get_physics_frames() - requested_at
	else:
		if night.index > 0:
			await _on_wake_screen()
			(_wake().get_node("%BedroomButton") as Button).pressed.emit()
			await _ticks(3)
		var bedroom: Bedroom = _bedroom()
		if bedroom == null:
			return
		if night.start == Start.BED:
			bedroom.walker().global_position = AT_BED
			await _ticks(3) # the zone reports on the physics tick
			_press(&"interact", true)
			await _until(func() -> bool: return _started, 30)
			_press(&"interact", false)
		else:
			Events.run_requested.emit(RunOptions.Mode.FLOOR, SEEDS[night.index % SEEDS.size()], true, "")
			await _until(func() -> bool: return _started, 30)
	await _ticks(2)


## Waits until the wake screen takes input (its guard of a few ticks is over).
func _on_wake_screen() -> void:
	var armed: bool = await _until(func() -> bool: return _wake().visible and not (_wake().get_node("%RestartButton") as Button).disabled, WAKE_WAIT_TICKS)
	if not armed:
		_failures.append("the wake screen never took input")


func _press(action: StringName, pressed: bool) -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


# --- the end -------------------------------------------------------------------------------------------------------


func _finish() -> void:
	await _ticks(5)
	_check_consistency()
	_main.queue_free()
	_main = null
	await _ticks(5)
	RoomLoader.collect_orphans(true)
	var tokens: int = RoomLoader.orphan_count()
	if tokens != 0:
		_failures.append("%d ResourceLoader token(s) left open" % tokens)
	_remove_save_dir()
	_report()
	get_tree().quit(1 if not _failures.is_empty() else 0)


func _check_consistency() -> void:
	_check_leaks()
	var session: TelemetrySession = Telemetry.session()
	var played: int = _nights.size()
	if session.runs_detail.size() < played:
		_failures.append("the telemetry holds %d runs of %d" % [session.runs_detail.size(), played])
	var wanted_attempts: int = _nights.filter(func(night: Night) -> bool: return night.boss_reached).size()
	if session.boss_attempts.size() != wanted_attempts:
		_failures.append("the telemetry holds %d boss attempts, %d expected" % [session.boss_attempts.size(), wanted_attempts])
	for attempt: Dictionary in session.boss_attempts:
		if not ["victory", "death", "abandoned"].has(str(attempt["outcome"])):
			_failures.append("boss attempt with outcome %s" % attempt["outcome"])
	for detail: Dictionary in session.runs_detail:
		if float(str(detail["duration_seconds"])) <= 0.0:
			_failures.append("run %s has no duration" % detail["run"])
		var share: float = float(str(detail["below_lucid_share"]))
		if share < 0.0 or share > 1.0:
			_failures.append("run %s: share below Lucid %s" % [detail["run"], share])
	if _boss_nights >= 2 and _quizzes == 0:
		_failures.append("no pop quiz in %d fights" % _boss_nights)
	var refused: int = 0
	for night: Night in _nights:
		refused += night.refused_bullets
	if refused > 0:
		_failures.append("the bullet pool refused %d shot(s)" % refused)


## The counts at the start of each night come back to what the first night of the same kind held, within a fixed margin.
func _check_leaks() -> void:
	var baselines: Dictionary[bool, Night] = {}
	for night: Night in _nights:
		var from_bedroom: bool = night.start == Start.BED or night.start == Start.TYPED_BEDROOM
		if not baselines.has(from_bedroom):
			baselines[from_bedroom] = night
			continue
		var base: Sample = baselines[from_bedroom].sample
		if absi(night.sample.objects - base.objects) > OBJECT_MARGIN:
			_failures.append("run %d: %d objects against %d at the first run" % [night.index + 1, night.sample.objects, base.objects])
		if absi(night.sample.nodes - base.nodes) > NODE_MARGIN:
			_failures.append("run %d: %d nodes against %d at the first run" % [night.index + 1, night.sample.nodes, base.nodes])
		if night.sample.orphans > base.orphans + ORPHAN_MARGIN:
			_failures.append("run %d: %d orphan nodes against %d at the first run" % [night.index + 1, night.sample.orphans, base.orphans])
	var fifth: int = maxi(_nights.size() / 5, 1)
	if _nights.size() >= 10:
		var early: float = 0.0
		var late: float = 0.0
		for i: int in fifth:
			early += _nights[i].sample.memory_mb
			late += _nights[_nights.size() - 1 - i].sample.memory_mb
		if late > early * MEMORY_GROWTH_LIMIT:
			_failures.append("static memory grew from %.1f to %.1f MB" % [early / fifth, late / fifth])


func _report() -> void:
	var lines: PackedStringArray = PackedStringArray()
	lines.append("| run | start | seed | outcome | game s | wake | rooms | load ms | objects | nodes | orphans | MB | max bullets |")
	lines.append("|---|---|---|---|---|---|---|---|---|---|---|---|---|")
	for night: Night in _nights:
		lines.append("| %d | %s | %s | %s (%s) | %.1f | %s | %d | %d | %d | %d | %d | %.1f | %d |" % [night.index + 1, Start.keys()[night.start], night.seed_code, night.outcome, night.plan,
				night.duration_seconds, night.wake, night.rooms_cleared, night.load_ms, night.sample.objects, night.sample.nodes,
				night.sample.orphans, night.sample.memory_mb, night.max_bullets])
	lines.append("")
	lines.append("soak: %d fight(s) against the Professor, %d pop quiz(zes)" % [_boss_nights, _quizzes])
	lines.append("soak: %d run(s), %.1f s of wall-clock time" % [_nights.size(), (Time.get_ticks_msec() - _start_msec) / 1000.0])
	for failure: String in _failures:
		lines.append("soak: FAIL %s" % failure)
	lines.append("soak: %s" % ("FAILED" if not _failures.is_empty() else "PASSED"))
	for line: String in lines:
		Log.info("run", line)


# --- helpers -------------------------------------------------------------------------------------------------------


## The temporary save folder goes away with the soak.
func _remove_save_dir() -> void:
	var path: String = _save_dir.get_current_dir()
	for dir_name: String in DirAccess.get_directories_at(path):
		for inner: String in DirAccess.get_files_at(path.path_join(dir_name)):
			DirAccess.remove_absolute(path.path_join(dir_name).path_join(inner))
		DirAccess.remove_absolute(path.path_join(dir_name))
	for file_name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	DirAccess.remove_absolute(path)



func _sample() -> Sample:
	var sample: Sample = Sample.new()
	sample.objects = int(Performance.get_monitor(Performance.OBJECT_COUNT))
	sample.nodes = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	sample.orphans = int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT))
	sample.memory_mb = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
	return sample


func _fail(night: Night, message: String) -> void:
	_failures.append("run %d (%s): %s" % [night.index + 1, night.plan, message])


func _out_of_time() -> bool:
	if (Time.get_ticks_msec() - _start_msec) / 1000 > _max_seconds:
		_failures.append("the soak ran over its %d s bound" % _max_seconds)
		return true
	return false


func _ticks(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _until(condition: Callable, max_ticks: int) -> bool:
	for i: int in max_ticks:
		if condition.call():
			return true
		await get_tree().physics_frame
	return condition.call()


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _player() -> Player:
	return get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player


func _bedroom() -> Bedroom:
	for child: Node in _main.get_node("%ActiveScene").get_children():
		if child is Bedroom:
			return child as Bedroom
	return null


func _wake() -> WakeScreen:
	return _main.find_children("*", "WakeScreen", true, false)[0] as WakeScreen


func _on_events_run_ended(outcome: int) -> void:
	_run_ended = outcome


func _on_events_wake_time_set(minute: int) -> void:
	_wake_minute = minute


func _on_events_boss_announced(_boss_id: StringName, text_key: StringName) -> void:
	if text_key == Boss.EXTRA_TITLE_KEY:
		_quizzes += 1


func _on_events_run_started() -> void:
	_started = true


func _on_events_floor_ready(_startup_ms: int, load_ms: int) -> void:
	_load_ms = load_ms
