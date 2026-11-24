class_name Main
extends Node
## Application root. Hosts the active scene (the Run) and the UI layer, and owns the pause (story 1.6) and the
## wake screen freeze (story 2.2): freezing disables ActiveScene (process_mode) and sets GameClock.paused,
## together and only here.
## SceneTree.paused is never used, so the UI layer and the autoloads (Audio) keep running.

## Preloaded: keeps run.tscn, so its arena, in the resource cache for the whole session (restart without reload).
const RUN_SCENE: PackedScene = preload("res://run/run.tscn")
const BULLET_LOAD_TEST_PATH: String = "res://debug/bullet_load_test.tscn"
const DEBUG_PANEL_PATH: String = "res://debug/debug_panel.tscn"
## Debug slow motion factor (F4). A debug tool, not a gameplay value.
const SLOW_MOTION_SCALE: float = 0.25
const WAKE_SCREEN_SCENE: PackedScene = preload("res://ui/menus/wake_screen.tscn")
const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/menus/pause_menu.tscn")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://ui/menus/settings_menu.tscn")
const SEED_ENTRY_SCENE: PackedScene = preload("res://ui/menus/seed_entry.tscn")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")
const MAP_VIEW_SCENE: PackedScene = preload("res://ui/map/floor_map_view.tscn")
const BEDROOM_SCENE: PackedScene = preload("res://bedroom/bedroom.tscn")

## What a new game plays: the generated floor (story 4.8). Checks that rely on the arena of milestone A set it back
## to ARENA before creating Main. Not a setting: nothing in the game writes it.
static var default_mode: RunOptions.Mode = RunOptions.Mode.FLOOR
## Whether the game starts in the bedroom (story 6.5) rather than in a run. Checks that expect a Run at launch set it to
## false before creating Main, like default_mode. Not a setting: nothing in the game writes it.
static var start_in_bedroom: bool = true

## Where the seed window was opened from: it gives the focus (or the freeze) back where it came from when cancelled.
enum SeedOrigin { PAUSE, WAKE, BEDROOM }

var _last_scale_factor: int = -1
var _last_window_size: Vector2i = Vector2i.ZERO
var _load_test_active: bool = false
## True while the wake screen is open (the run is over, the game is frozen behind it).
var _run_over: bool = false
var _run_ended_msec: int = 0
## Wake time of the last run (story 6.6), -1 before any run: the bedroom alarm clock shows it. Kept in memory only (6.7 persists it).
var _last_wake_minute: int = -1
var _run_options: RunOptions
var _wake_screen: WakeScreen
var _pause_menu: PauseMenu
var _settings_menu: SettingsMenu
var _seed_entry: SeedEntry
var _seed_origin: SeedOrigin = SeedOrigin.PAUSE
var _hud: Hud
var _map_view: FloorMapView

@onready var _active_scene: Node = %ActiveScene
@onready var _ui: CanvasLayer = %UI


func _ready() -> void:
	_run_options = RunOptions.new()
	_run_options.mode = default_mode
	get_window().min_size = Const.VIEWPORT
	_hud = HUD_SCENE.instantiate() as Hud
	_ui.add_child(_hud)
	_ui.move_child(_hud, 0) # below every overlay and menu; added before the run starts, so it gets the first health state
	_map_view = MAP_VIEW_SCENE.instantiate() as FloorMapView
	_ui.add_child(_map_view) # over the HUD, under the menus
	_ui.move_child(_map_view, 1)
	var boss_bar: BossBar = BossBar.new()
	_ui.add_child(boss_bar) # the health bar of a boss and the chalk title of its phase, over the map and under the menus
	_ui.move_child(boss_bar, 2)
	var chalk_title: ChalkTitle = ChalkTitle.new()
	_ui.add_child(chalk_title)
	_ui.move_child(chalk_title, 3)
	if OS.is_debug_build():
		_check_viewport_size()
		_check_collision_layer_names()
		_ui.add_child(CollisionDrawer.new())
		# Loaded here, not preloaded: release code holds no reference to debug/ (F1 panel, AR24).
		var panel_scene: PackedScene = load(DEBUG_PANEL_PATH) as PackedScene
		if panel_scene != null:
			_ui.add_child(panel_scene.instantiate())
	_setup_menus()
	Events.wake_time_set.connect(_on_events_wake_time_set) # before run_ended: the time is set when the screen opens
	Events.run_ended.connect(_on_events_run_ended)
	Events.run_requested.connect(_on_run_requested)
	Events.run_started.connect(_on_events_run_started)
	if start_in_bedroom:
		_enter_bedroom()
	else:
		_start_run()
	_check_window_scale()


func _check_viewport_size() -> void:
	var width: int = ProjectSettings.get_setting("display/window/size/viewport_width", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/viewport_height", 0)
	if Vector2i(width, height) != Const.VIEWPORT:
		Log.error("ui", "project viewport is %dx%d, Const.VIEWPORT is %s" % [width, height, Const.VIEWPORT])
		assert(false, "Viewport size out of sync with Const")


func _check_collision_layer_names() -> void:
	for i: int in Const.LAYER_NAMES.size():
		var setting: String = "layer_names/2d_physics/layer_%d" % (i + 1)
		var actual: String = str(ProjectSettings.get_setting(setting, ""))
		if actual != Const.LAYER_NAMES[i]:
			Log.error("ui", "collision layer %d is '%s', expected '%s'" % [i + 1, actual, Const.LAYER_NAMES[i]])
			assert(false, "Collision layer names out of sync with Const")


## Hidden menus, added last to UI so they draw above the overlays.
func _setup_menus() -> void:
	_wake_screen = WAKE_SCREEN_SCENE.instantiate() as WakeScreen
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	_settings_menu = SETTINGS_MENU_SCENE.instantiate() as SettingsMenu
	_seed_entry = SEED_ENTRY_SCENE.instantiate() as SeedEntry
	_ui.add_child(_wake_screen)
	_ui.add_child(_pause_menu)
	_ui.add_child(_settings_menu)
	_ui.add_child(_seed_entry) # last: it takes the input before the menus below it
	_wake_screen.restart_requested.connect(_on_wake_screen_restart_requested)
	_wake_screen.verdict_given.connect(_on_wake_screen_verdict_given)
	_wake_screen.new_seed_requested.connect(_on_wake_screen_new_seed_requested)
	_wake_screen.wake_up_requested.connect(_on_wake_screen_wake_up_requested)
	_pause_menu.resume_requested.connect(_on_pause_menu_resume_requested)
	_pause_menu.settings_requested.connect(_on_pause_menu_settings_requested)
	_pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	_pause_menu.new_seed_requested.connect(_on_pause_menu_new_seed_requested)
	_settings_menu.back_requested.connect(_on_settings_menu_back_requested)
	_seed_entry.seed_submitted.connect(_on_seed_entry_seed_submitted)
	_seed_entry.cancelled.connect(_on_seed_entry_cancelled)


func _notification(what: int) -> void:
	# Auto pause when the application loses focus; no auto resume: the player resumes.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_paused(true, "focus lost")
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_release_for_quit()


## The only code that freezes or unfreezes the game (pause and wake screen). Never use get_tree().paused.
func _freeze(frozen: bool) -> void:
	GameClock.paused = frozen
	_active_scene.process_mode = Node.PROCESS_MODE_DISABLED if frozen else Node.PROCESS_MODE_INHERIT


## Pause and resume. Ignored behind the wake screen: no pause menu over it (it would reopen the dead game).
func _set_paused(value: bool, reason: String = "") -> void:
	if _run_over or value == GameClock.paused:
		return
	_freeze(value)
	if value:
		_pause_menu.open(_seed_code())
	else:
		_close_menus()
	var suffix: String = " (%s)" % reason if not reason.is_empty() else ""
	Log.info("ui", "game %s%s" % ["paused" if value else "resumed", suffix])


## While paused, the menus get pause and ui_cancel first (deeper in the tree) and consume them.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		_set_paused(true)
		get_viewport().set_input_as_handled()
		return
	# Debug tools only, and never while paused: a scene loaded under a disabled ActiveScene would be frozen.
	if not OS.is_debug_build() or GameClock.paused:
		return
	if event.is_action_pressed("debug_load_test"):
		var wants_load_test: bool = not _load_test_active
		if wants_load_test:
			_clear_active_scene() # the run releases its pending background loads before a synchronous load()
			RoomLoader.collect_orphans(true)
			var load_test: PackedScene = load(BULLET_LOAD_TEST_PATH) as PackedScene
			# Flip the flag only after a successful load, so a failed load cannot desynchronize it.
			if load_test != null and _show_scene(load_test):
				_load_test_active = true
			else:
				Log.warn("ui", "scene not found at %s" % BULLET_LOAD_TEST_PATH)
				_start_run() # the run was cleared above
		else:
			_start_run()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_slow_motion"):
		# The state lives in GameClock, so it survives scene changes (F5).
		var was_slow: bool = GameClock.global_multiplier < 1.0
		GameClock.global_multiplier = 1.0 if was_slow else SLOW_MOTION_SCALE
		Log.info("input", "slow motion %s" % ("off" if was_slow else "on"))
		get_viewport().set_input_as_handled()


## Starts a new run: the old Run (if any) is destroyed, a fresh one is instantiated (AR20). Without options the run
## repeats the last ones (restart, F5 back from the load test): the floor unless something else was asked for.
func _start_run(options: RunOptions = null) -> void:
	if options != null:
		_run_options = options
	else:
		_run_options = _fresh_seed_options(_run_options) # a restart is a new night, not a replay of the typed seed
	_wake_screen.hide()
	_close_menus()
	_run_over = false
	_hud.visible = true
	# Remove the old run while still frozen, unfreeze, then add the new one: it must enter an enabled tree.
	_clear_active_scene()
	_freeze(false)
	var run: Run = RUN_SCENE.instantiate() as Run
	run.setup(_run_options) # before add_child()
	_active_scene.add_child(run)
	_run_options = run.played_options() # the options actually played: a room that could not load fell back to the arena
	_load_test_active = false


## The bedroom replaces whatever is active (story 6.5): the hub where a night starts. The HUD and the map belong to a run
## and are hidden; nothing is frozen. Called at launch and from the wake screen, never during run_ended.
func _enter_bedroom() -> void:
	_wake_screen.hide()
	_close_menus()
	_run_over = false
	_hud.visible = false
	_clear_active_scene() # also unbinds the map
	_freeze(false)
	var bedroom: Bedroom = BEDROOM_SCENE.instantiate() as Bedroom
	bedroom.sleep_requested.connect(_on_bedroom_sleep_requested)
	bedroom.seed_entry_requested.connect(_on_bedroom_seed_entry_requested)
	_active_scene.add_child(bedroom)
	bedroom.set_clock_minute(_last_wake_minute)
	_load_test_active = false
	Log.info("run", "entered the bedroom")


## The player went to bed: a night on a seed drawn at random, from the one place that starts runs.
func _on_bedroom_sleep_requested() -> void:
	Log.info("run", "going to sleep")
	Events.run_requested.emit(RunOptions.Mode.FLOOR, -1, false, "")


## The desk: the seed window opens over a frozen bedroom (the typed letters would also move and interact).
func _on_bedroom_seed_entry_requested() -> void:
	_seed_origin = SeedOrigin.BEDROOM
	_freeze(true)
	_seed_entry.open()


## The same mode and room as options, with a seed to draw: a restart never replays the seed of the run before.
func _fresh_seed_options(previous: RunOptions) -> RunOptions:
	var options: RunOptions = RunOptions.new()
	options.mode = previous.mode
	options.room_path = previous.room_path
	return options


## Hides the pause menu, the settings and the seed window, and drops the focus they held.
func _close_menus() -> void:
	_settings_menu.hide()
	_pause_menu.hide()
	_seed_entry.hide()
	get_viewport().gui_release_focus()


## The seed code of the run in progress (or just ended), empty when there is no run (load test).
func _seed_code() -> String:
	var run: Run = get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run
	return run.rng.seed_code() if run != null and run.rng != null else ""


## Lets the run go (its loader hands the pending loads over) and collects them: no ResourceLoader token left at exit.
func _release_for_quit() -> void:
	_clear_active_scene()
	RoomLoader.collect_orphans(true)


## Removes every child of ActiveScene.
func _clear_active_scene() -> void:
	_map_view.unbind()
	for child: Node in _active_scene.get_children():
		# Out of the tree at once, so its node groups (bullet managers, debug shapes) stop counting this frame.
		_active_scene.remove_child(child)
		child.queue_free()


## Replaces the content of ActiveScene by an instance of scene.
func _show_scene(scene: PackedScene) -> bool:
	_clear_active_scene()
	_active_scene.add_child(scene.instantiate())
	return true


## A run is ready: the map reads its floor.
func _on_events_run_started() -> void:
	if not is_inside_tree():
		return # a Main already removed from the tree still hears the bus
	var run: Run = null
	for child: Node in _active_scene.get_children():
		if child is Run:
			run = child as Run
			break
	_map_view.bind(run.floor_map if run != null else null)


## The wake time of the run that is ending (published by Run just before run_ended).
func _on_events_wake_time_set(minute: int) -> void:
	_last_wake_minute = minute


## The run ended (death or victory): freeze the game and show the wake screen of that outcome. Synchronous, in the tick
## of the lethal hit (or the last tick of the victory delay). An outcome Run does not know is a defeat.
func _on_events_run_ended(outcome: int) -> void:
	if _run_over:
		return
	_run_over = true
	_run_ended_msec = Time.get_ticks_msec()
	_freeze(true)
	if outcome != Run.Outcome.DEATH and outcome != Run.Outcome.VICTORY:
		Log.warn("run", "unknown run outcome %d: treated as a defeat" % outcome)
		outcome = Run.Outcome.DEATH
	_wake_screen.open(_seed_code(), outcome, _last_wake_minute)


## "Back to the bedroom" on the wake screen: the signal of a button, so the dead Run is removed after run_ended.
func _on_wake_screen_wake_up_requested() -> void:
	Log.info("run", "back to the bedroom %d ms after the end of the run" % (Time.get_ticks_msec() - _run_ended_msec))
	_enter_bedroom()


func _on_wake_screen_restart_requested() -> void:
	Log.info("run", "restart requested %d ms after the end of the run" % (Time.get_ticks_msec() - _run_ended_msec))
	_start_run()


func _on_pause_menu_resume_requested() -> void:
	_set_paused(false)


func _on_pause_menu_settings_requested() -> void:
	_pause_menu.hide()
	_settings_menu.open()


## No title screen at milestone A: Quit closes the game (settings are already saved).
func _on_pause_menu_quit_requested() -> void:
	Log.info("ui", "quit requested from the pause menu")
	_release_for_quit()
	get_tree().quit()


func _on_settings_menu_back_requested() -> void:
	_settings_menu.hide()
	_pause_menu.open(_seed_code(), PauseMenu.Focus.SETTINGS)


## The player wants to type a seed, from the pause menu or from the wake screen.
func _on_pause_menu_new_seed_requested() -> void:
	_seed_origin = SeedOrigin.PAUSE
	_pause_menu.hide()
	_seed_entry.open()


func _on_wake_screen_new_seed_requested() -> void:
	_seed_origin = SeedOrigin.WAKE
	_seed_entry.open()


## A valid seed was typed: a new run on it, from the one place that starts runs.
func _on_seed_entry_seed_submitted(seed_value: int) -> void:
	Log.info("run", "new game requested on a typed seed")
	Events.run_requested.emit(RunOptions.Mode.FLOOR, seed_value, true, "")


## Escape on the seed window: back to the menu it came from, nothing else changed.
func _on_seed_entry_cancelled() -> void:
	_seed_entry.hide()
	match _seed_origin:
		SeedOrigin.WAKE:
			_wake_screen.focus_new_seed()
		SeedOrigin.BEDROOM:
			get_viewport().gui_release_focus() # a focused control would eat the interact key
			_freeze(false)
		_:
			_pause_menu.open(_seed_code(), PauseMenu.Focus.NEW_SEED)


## A new run was requested on the bus. The game is unfrozen first (the pause menu may be what asked).
func _on_run_requested(mode: int, seed_value: int, seeded: bool, room_path: String) -> void:
	_start_run(RunOptions.from_request(mode, seed_value, seeded, room_path))


## Window size polled each frame: size_changed only fires when the root viewport changes, and the viewport
## stretch mode keeps it at 640x360 whatever the window (resize, fullscreen setting). Logs on scale changes only.
func _process(_delta: float) -> void:
	if get_window().size != _last_window_size:
		_check_window_scale()


func _check_window_scale() -> void:
	var size: Vector2i = get_window().size
	_last_window_size = size
	var factor: int = Const.integer_scale(size)
	# Only log real scale changes: the size changes continuously while the user drags a window edge.
	# A factor of 0 means the window is minimized.
	if factor < 1 or factor == _last_scale_factor:
		return
	_last_scale_factor = factor
	Log.info("ui", "window scale changed size=%dx%d scale=x%d" % [size.x, size.y, factor])


## Relays the answer on the bus: the telemetry listens to Events only.
func _on_wake_screen_verdict_given(just: bool) -> void:
	Events.death_judged.emit(just)
