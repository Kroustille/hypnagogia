class_name RoomInfo
extends RefCounted
## What the floor generator and the validator need to know about a room scene, read once (story 4.2).

var id: StringName = &""
var path: String = ""
var room_type: Room.RoomType = Room.RoomType.COMBAT
var size_kind: Room.SizeKind = Room.SizeKind.SCREEN
## Door.Side values of the doors the room declares, sorted.
var doors: Array[int] = []


## Instantiates the scene, reads it and frees it. Null when the root is not a Room.
static func from_scene(scene: PackedScene) -> RoomInfo:
	var node: Node = scene.instantiate()
	var room: Room = node as Room
	if room == null:
		node.free()
		return null
	var info: RoomInfo = RoomInfo.new()
	info.path = scene.resource_path
	info.id = StringName(info.path.get_file().get_basename())
	info.room_type = room.room_type
	info.size_kind = room.size_kind
	for door: Door in room.doors():
		if not info.doors.has(door.side):
			info.doors.append(door.side)
	info.doors.sort()
	room.free()
	return info


## Every room scene under dir (recursive), sorted: DirAccess does not guarantee any order and the floor generator
## (story 4.7) needs a deterministic one.
static func scene_paths(dir: String) -> PackedStringArray:
	var found: PackedStringArray = PackedStringArray()
	_collect(dir, found)
	found.sort()
	return found


static func _collect(dir: String, found: PackedStringArray) -> void:
	for file: String in DirAccess.get_files_at(dir):
		var name: String = file.trim_suffix(".remap") # exported builds list "x.tscn.remap"
		if name.ends_with(".tscn"):
			found.append(dir.path_join(name))
	for sub: String in DirAccess.get_directories_at(dir):
		_collect(dir.path_join(sub), found)
