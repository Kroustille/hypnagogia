class_name RoomCatalog
extends RefCounted
## The rooms of a pool folder as RoomInfo, read once per session (story 4.7). The listing is sorted by path (the file
## system order is not guaranteed) and an exported build lists "x.tscn.remap" instead of "x.tscn" (RoomInfo.scene_paths
## handles both). Reading a room instantiates its scene, so the result is cached by folder.

## Folder -> Array[RoomInfo], every room of the folder whatever its unlock.
static var _cache: Dictionary = {}


## The rooms of dir the player may meet: those that need no unlock, or one of unlocks. The order is the sorted path
## order, so the same unlocks always give the same pool.
static func pool(dir: String, unlocks: Array[StringName] = []) -> Array[RoomInfo]:
	var result: Array[RoomInfo] = []
	for info: RoomInfo in all(dir):
		if info.requires_unlock == &"" or unlocks.has(info.requires_unlock):
			result.append(info)
	return result


## Every room of dir, sorted by path.
static func all(dir: String) -> Array[RoomInfo]:
	if _cache.has(dir):
		var stored: Array = _cache[dir]
		var cached: Array[RoomInfo] = []
		cached.assign(stored)
		return cached
	var infos: Array[RoomInfo] = []
	for path: String in RoomInfo.scene_paths(dir):
		var scene: PackedScene = load(path) as PackedScene
		if scene == null:
			Log.error("gen", "room scene %s cannot be loaded" % path)
			continue
		var info: RoomInfo = RoomInfo.from_scene(scene)
		if info == null:
			Log.error("gen", "room scene %s has no Room root" % path)
			continue
		infos.append(info)
	_cache[dir] = infos
	var copy: Array[RoomInfo] = []
	copy.assign(infos)
	return copy


## Forgets what was read (tests that change the files).
static func clear_cache() -> void:
	_cache.clear()
