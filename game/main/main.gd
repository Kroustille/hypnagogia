class_name Main
extends Node
## Application root. Hosts the active scene and the UI layer.

const ARENA_PATH: String = "res://rooms/arena/arena.tscn"
const BULLET_LOAD_TEST_PATH: String = "res://debug/bullet_load_test.tscn"

var _last_scale_factor: int = -1
var _load_test_active: bool = false

@onready var _active_scene: Node = %ActiveScene
@onready var _ui: CanvasLayer = %UI


func _ready() -> void:
	get_window().min_size = Const.VIEWPORT
	if OS.is_debug_build():
		_check_viewport_size()
		_check_collision_layer_names()
		_ui.add_child(CollisionDrawer.new())
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


func _unhandled_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	if event.is_action_pressed("debug_load_test"):
		var wants_load_test: bool = not _load_test_active
		var path: String = BULLET_LOAD_TEST_PATH if wants_load_test else ARENA_PATH
		# Flip the flag only after a successful load, so a failed load cannot desynchronize it.
		if _show_scene(path):
			_load_test_active = wants_load_test
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


func _on_window_size_changed() -> void:
	var size: Vector2i = get_window().size
	var factor: int = Const.integer_scale(size)
	# Only log real scale changes: size_changed fires continuously while the user drags a window edge.
	# A factor of 0 means the window is minimized.
	if factor < 1 or factor == _last_scale_factor:
		return
	_last_scale_factor = factor
	Log.info("ui", "window scale changed size=%dx%d scale=x%d" % [size.x, size.y, factor])
