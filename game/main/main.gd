class_name Main
extends Node
## Application root. Hosts the active scene and the UI layer, and owns the pause (story 1.6):
## pausing disables ActiveScene (process_mode) and sets GameClock.paused, together and only here.
## SceneTree.paused is never used, so the UI layer and the autoloads (Audio) keep running.

const ARENA_PATH: String = "res://rooms/arena/arena.tscn"
const BULLET_LOAD_TEST_PATH: String = "res://debug/bullet_load_test.tscn"
## Debug slow motion factor (F4). A debug tool, not a gameplay value.
const SLOW_MOTION_SCALE: float = 0.25
const PAUSE_MENU_SCENE: PackedScene = preload("res://ui/menus/pause_menu.tscn")
const SETTINGS_MENU_SCENE: PackedScene = preload("res://ui/menus/settings_menu.tscn")

var _last_scale_factor: int = -1
var _load_test_active: bool = false
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
	_setup_menus()
	_show_scene(ARENA_PATH)
	get_window().size_changed.connect(_on_window_size_changed)
	_on_window_size_changed()


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
	_pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	_settings_menu = SETTINGS_MENU_SCENE.instantiate() as SettingsMenu
	_ui.add_child(_pause_menu)
	_ui.add_child(_settings_menu)
	_pause_menu.resume_requested.connect(_on_pause_menu_resume_requested)
	_pause_menu.settings_requested.connect(_on_pause_menu_settings_requested)
	_pause_menu.quit_requested.connect(_on_pause_menu_quit_requested)
	_settings_menu.back_requested.connect(_on_settings_menu_back_requested)


func _notification(what: int) -> void:
	# Auto pause when the application loses focus; no auto resume: the player resumes.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_set_paused(true, "focus lost")


## The only place that pauses or resumes the game. Never use get_tree().paused.
func _set_paused(value: bool, reason: String = "") -> void:
	if value == GameClock.paused:
		return
	GameClock.paused = value
	_active_scene.process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT
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
		var path: String = BULLET_LOAD_TEST_PATH if wants_load_test else ARENA_PATH
		# Flip the flag only after a successful load, so a failed load cannot desynchronize it.
		if _show_scene(path):
			_load_test_active = wants_load_test
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_slow_motion"):
		# The state lives in GameClock, so it survives scene changes (F5).
		var was_slow: bool = GameClock.global_multiplier < 1.0
		GameClock.global_multiplier = 1.0 if was_slow else SLOW_MOTION_SCALE
		Log.info("input", "slow motion %s" % ("off" if was_slow else "on"))
		get_viewport().set_input_as_handled()


## Replaces the content of ActiveScene by the scene at path. Returns false if it cannot load.
func _show_scene(path: String) -> bool:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		Log.warn("ui", "scene not found at %s" % path)
		return false
	for child: Node in _active_scene.get_children():
		# Out of the tree at once, so its node groups (bullet managers, debug shapes) stop counting this frame.
		_active_scene.remove_child(child)
		child.queue_free()
	_active_scene.add_child(scene.instantiate())
	return true


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


func _on_window_size_changed() -> void:
	var size: Vector2i = get_window().size
	var factor: int = Const.integer_scale(size)
	# Only log real scale changes: size_changed fires continuously while the user drags a window edge.
	# A factor of 0 means the window is minimized.
	if factor < 1 or factor == _last_scale_factor:
		return
	_last_scale_factor = factor
	Log.info("ui", "window scale changed size=%dx%d scale=x%d" % [size.x, size.y, factor])
