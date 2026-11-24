class_name RoomLoader
extends RefCounted
## Loads the room scenes of a floor (story 4.8, AR17, D11): every one is requested in a background thread when the
## floor starts, and scene_for() hands it over when the player walks through a door. Every request is collected exactly
## once (load_threaded_get), else the resource would stay held by the loader.

## Requests a leaving run left in progress: collected by a later loader once they are over, without ever waiting.
static var _orphans: Array[String] = []

var _requested: Dictionary[String, bool] = {}
var _scenes: Dictionary[String, PackedScene] = {}


## Starts loading the scenes in the background. A path already requested or loaded is skipped.
func request_all(paths: PackedStringArray) -> void:
	collect_orphans()
	for path: String in paths:
		if _requested.has(path) or _scenes.has(path):
			continue
		_orphans.erase(path) # asked for again: this loader collects it
		if ResourceLoader.load_threaded_request(path, "PackedScene") == OK:
			_requested[path] = true
		else:
			Log.error("run", "room scene %s cannot be requested" % path)


## True when scene_for(path) would not wait: the scene is loaded, or was never requested and is loaded on the spot (false).
func is_ready(path: String) -> bool:
	if _scenes.has(path):
		return true
	return _requested.has(path) and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED


## The scene of the path, waiting for the background load when it is not over; a path never requested is loaded now.
## Null (and an error) when it cannot be loaded.
func scene_for(path: String) -> PackedScene:
	if _scenes.has(path):
		return _scenes[path]
	var scene: PackedScene
	if _requested.has(path):
		_requested.erase(path)
		scene = ResourceLoader.load_threaded_get(path) as PackedScene
	else:
		_collect_pending() # a synchronous load() while threaded requests run can deadlock
		collect_orphans(true)
		scene = load(path) as PackedScene
	if scene == null:
		Log.error("run", "room scene %s cannot be loaded" % path)
		return null
	_scenes[path] = scene
	return scene


## Lets go of the requests still pending (the run ends before the player went everywhere). Never waits: the finished
## ones are collected now, the ones still loading are left to a later loader (collect_orphans).
func drain() -> void:
	for path: String in _requested.keys():
		var status: ResourceLoader.ThreadLoadStatus = ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			_orphans.append(path)
		else:
			ResourceLoader.load_threaded_get(path) # over: collecting does not wait
	_requested.clear()


## Collects the requests of past runs that are over by now; the others stay for the next call. wait: collects every
## one, waiting for the loads in progress (before a synchronous load(), which can deadlock beside a threaded request).
static func collect_orphans(wait: bool = false) -> void:
	var still_loading: Array[String] = []
	for path: String in _orphans:
		if not wait and ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			still_loading.append(path)
		else:
			ResourceLoader.load_threaded_get(path)
	_orphans = still_loading


## Requests of past runs not collected yet (checks).
static func orphan_count() -> int:
	return _orphans.size()


func _collect_pending() -> void:
	for path: String in _requested.keys():
		var scene: PackedScene = ResourceLoader.load_threaded_get(path) as PackedScene
		if scene != null:
			_scenes[path] = scene
	_requested.clear()


func pending_count() -> int:
	return _requested.size()
