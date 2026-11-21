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

var _last_scale_factor: int = -1
var _last_window_size: Vector2i = Vector2i.ZERO
var _load_test_active: bool = false
## True while the wake screen is open (the run is over, the game is frozen behind it).
var _run_over: bool = false
var _run_ended_msec: int = 0
var _wake_screen: WakeScreen
var _pause_menu: PauseMenu
var _settings_menu: SettingsMenu

@onready var _active_scene: Node = %ActiveScene
@onready var _ui: CanvasLayer = %UI


func _ready() -> void:
	get_window().min_size = Const.VIEWPORT
	if OS.is_debug_build():
		_check_viewport_size()
		_check_collision_layer_names()
		_ui.add_child(CollisionDrawer.new())
		# Loaded here, not preloaded: release code holds no reference to debug/ (F1 panel, AR24).
		var panel_scene: PackedScene = load(DEBUG_PANEL_PATH) as PackedScene
		if panel_scene != null:
			_ui.add_child(panel_scene.instantiate())
	_setup_menus()
	Events.run_ended.connect(_on_events_run_ended)
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
	_ui.add_child(_wake_screen)
	_ui.add_child(_pause_menu)
	_ui.add_child(_settings_menu)
	_wake_screen.restart_requested.connect(_on_wake_screen_restart_requested)
	_pause_menu.resume_requested.connect(_on_pause_menu_resume_requested)
	_pause_menu.settings_requested.connect(_on_pause_menu_settings_requested)
	_pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	_settings_menu.back_requested.connect(_on_settings_menu_back_requested)


func _notification(what: int) -> void:
	# Auto pause when the application loses focus; no auto resume: the player resumes.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_paused(true, "focus lost")


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
		_pause_menu.open()
	else:
		_settings_menu.hide()
		_pause_menu.hide()
		get_viewport().gui_release_focus()
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
			var load_test: PackedScene = load(BULLET_LOAD_TEST_PATH) as PackedScene
			# Flip the flag only after a successful load, so a failed load cannot desynchronize it.
			if load_test != null and _show_scene(load_test):
				_load_test_active = true
			else:
				Log.warn("ui", "scene not found at %s" % BULLET_LOAD_TEST_PATH)
		else:
			_start_run()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_slow_motion"):
		# The state lives in GameClock, so it survives scene changes (F5).
		var was_slow: bool = GameClock.global_multiplier < 1.0
		GameClock.global_multiplier = 1.0 if was_slow else SLOW_MOTION_SCALE
		Log.info("input", "slow motion %s" % ("off" if was_slow else "on"))
		get_viewport().set_input_as_handled()


## Starts a new run: the old Run (if any) is destroyed, a fresh one is instantiated (AR20).
func _start_run() -> void:
	_wake_screen.hide()
	_run_over = false
	# Unfreeze before adding the new run: a node added under a disabled parent would miss NOTIFICATION_DISABLED/ENABLED.
	_freeze(false)
	_show_scene(RUN_SCENE)
	_load_test_active = false


## Replaces the content of ActiveScene by an instance of scene.
func _show_scene(scene: PackedScene) -> bool:
	for child: Node in _active_scene.get_children():
		# Out of the tree at once, so its node groups (bullet managers, debug shapes) stop counting this frame.
		_active_scene.remove_child(child)
		child.queue_free()
	_active_scene.add_child(scene.instantiate())
	return true


## The run ended (death): freeze the game and show the wake screen. Synchronous, in the tick of the lethal hit.
func _on_events_run_ended(_outcome: int) -> void:
	if _run_over:
		return
	_run_over = true
	_run_ended_msec = Time.get_ticks_msec()
	_freeze(true)
	_wake_screen.open()


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
	get_tree().quit()


func _on_settings_menu_back_requested() -> void:
	_settings_menu.hide()
	_pause_menu.open(true)


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
