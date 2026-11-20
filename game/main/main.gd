class_name Main
extends Node
## Application root. Hosts the active scene and the UI layer.

const SCALE_TEST_PATTERN_PATH: String = "res://debug/scale_test_pattern.tscn"

var _last_scale_factor: int = -1

@onready var _active_scene: Node = %ActiveScene


func _ready() -> void:
	get_window().min_size = Const.VIEWPORT
	if OS.is_debug_build():
		_check_viewport_size()
		_check_collision_layer_names()
		_spawn_scale_test_pattern()
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


func _spawn_scale_test_pattern() -> void:
	var pattern_scene: PackedScene = load(SCALE_TEST_PATTERN_PATH) as PackedScene
	if pattern_scene == null:
		Log.warn("ui", "scale test pattern not found at %s" % SCALE_TEST_PATTERN_PATH)
		return
	_active_scene.add_child(pattern_scene.instantiate())


func _on_window_size_changed() -> void:
	var size: Vector2i = get_window().size
	var factor: int = Const.integer_scale(size)
	# Only log real scale changes: size_changed fires continuously while the user drags a window edge.
	# A factor of 0 means the window is minimized.
	if factor < 1 or factor == _last_scale_factor:
		return
	_last_scale_factor = factor
	Log.info("ui", "window scale changed size=%dx%d scale=x%d" % [size.x, size.y, factor])
