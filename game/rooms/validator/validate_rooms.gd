class_name ValidateRooms
extends Node
## Headless room validation (story 4.2): validates every room scene under rooms/pool/ (or under the directory given
## after "--"), prints one line per problem and quits with a non-zero code when a room is invalid.
## Run it with tools/validate_rooms.sh.

const DEFAULT_ROOT: String = "res://rooms/pool"


func _ready() -> void:
	await get_tree().process_frame # `--scene` never returns without a quit issued after the first frame
	get_tree().quit(run(_root_from_args()))


## Validates every scene under root. Returns the exit code: 0 when all rooms are valid (and at least one exists).
func run(root: String) -> int:
	var paths: PackedStringArray = RoomInfo.scene_paths(root)
	if paths.is_empty():
		printerr("validate_rooms: no room under %s" % root)
		return 1
	var invalid: int = 0
	for path: String in paths:
		var scene: PackedScene = load(path) as PackedScene
		var problems: PackedStringArray = PackedStringArray(["%s: cannot be loaded" % path.get_file()]) \
			if scene == null else RoomValidator.validate(scene)
		for problem: String in problems:
			printerr(problem)
		if not problems.is_empty():
			invalid += 1
	if invalid == 0:
		Log.info("room", "validate_rooms: %d rooms valid" % paths.size())
		return 0
	printerr("validate_rooms: %d of %d rooms invalid" % [invalid, paths.size()])
	return 1


func _root_from_args() -> String:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	return args[0] if not args.is_empty() else DEFAULT_ROOT
