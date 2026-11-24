extends Node
## Reads and writes the JSON save files (profile.json now, run.json in story 6.8). Atomic write (temporary file, then
## rename), quarantine of an unreadable file as <name>.corrupt. Never saves a .tres or a .res.
## The data folder is injectable so that the tests never touch the player's real user:// folder.

enum Status { OK, MISSING, UNREADABLE, CORRUPT }

const DEFAULT_DIRECTORY: String = "user://"

## Status of the last read_json() call: tells a missing file, a locked one (left alone) and a corrupt one (quarantined).
var last_read_status: Status = Status.MISSING

var _directory: String = DEFAULT_DIRECTORY


## Where the save files live (tests only; the game keeps user://).
func set_directory(directory: String) -> void:
	_directory = directory if directory.ends_with("/") else directory + "/"


func directory() -> String:
	return _directory


## Full path of a save file of the current directory.
func path_of(file_name: String) -> String:
	return _directory + file_name


## Writes data as JSON to path atomically: a failure is logged, returns false and leaves the existing file intact.
## On Windows the engine rename removes the target first (short non-atomic window, engine side).
func write_json(path: String, data: Dictionary) -> bool:
	var tmp_path: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		Log.error("save", "cannot write %s (error %d)" % [tmp_path.get_file(), FileAccess.get_open_error()])
		return false
	if not file.store_string(JSON.stringify(data, "\t")):
		var write_error: Error = file.get_error()
		file.close()
		DirAccess.remove_absolute(tmp_path) # a partial file never replaces the good one
		Log.error("save", "cannot write %s (error %d)" % [tmp_path.get_file(), write_error])
		return false
	file.close() # flushed before the rename
	var err: Error = DirAccess.rename_absolute(tmp_path, path)
	if err != OK:
		Log.error("save", "cannot rename %s to %s (error %d)" % [tmp_path.get_file(), path.get_file(), err])
		DirAccess.remove_absolute(tmp_path)
		return false
	Log.debug("save", "%s written" % path.get_file())
	return true


## The Dictionary stored at path, or null: missing file (MISSING), file that cannot be opened, for instance locked by an
## antivirus (UNREADABLE: left where it is), invalid JSON or a root that is not a Dictionary (CORRUPT: quarantined).
func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		last_read_status = Status.MISSING
		return null
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		Log.warn("save", "%s cannot be read (error %d), left untouched" % [path.get_file(), FileAccess.get_open_error()])
		last_read_status = Status.UNREADABLE
		return null
	var text: String = file.get_as_text()
	file.close()
	var json: JSON = JSON.new()
	var parsed: Variant = json.data if json.parse(text) == OK else null # parse() reports without an engine error
	if typeof(parsed) != TYPE_DICTIONARY:
		Log.warn("save", "%s is not a JSON object" % path.get_file())
		last_read_status = Status.CORRUPT if quarantine(path) else Status.UNREADABLE
		return null
	last_read_status = Status.OK
	return parsed


## Renames path to <path>.corrupt, replacing an older quarantined file. Returns true when the file was moved.
func quarantine(path: String) -> bool:
	var corrupt_path: String = path + ".corrupt"
	var err: Error = DirAccess.rename_absolute(path, corrupt_path)
	if err != OK:
		Log.error("save", "cannot quarantine %s (error %d): the file is left where it is" % [path.get_file(), err])
	Log.warn("save", "%s quarantined as %s (rename error %d)" % [path.get_file(), corrupt_path.get_file(), err])
	return err == OK
