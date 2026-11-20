extends Node
## Central logger. The only place allowed to call print().
## Output: console + Godot's built-in file logging (user://logs/godot.log).
## Never log from per-frame code: per-frame data goes through the F3 overlay.

const CATEGORIES: PackedStringArray = [
	"run", "room", "combat", "lucidity", "items", "gen", "save", "input", "audio", "ui",
]

var _is_debug: bool = false
var _trace_categories: Dictionary[String, bool] = {}


func _ready() -> void:
	_is_debug = OS.is_debug_build()


func error(category: String, message: String) -> void:
	var line: String = _write("ERROR", category, message)
	push_error(line)


func warn(category: String, message: String) -> void:
	var line: String = _write("WARN", category, message)
	push_warning(line)


func info(category: String, message: String) -> void:
	_write("INFO", category, message)


func debug(category: String, message: String) -> void:
	if not _is_debug:
		return
	_write("DEBUG", category, message)


func trace(category: String, message: String) -> void:
	if not _is_debug:
		return
	if not _trace_categories.get(category, false):
		return
	_write("TRACE", category, message)


func set_trace_enabled(category: String, enabled: bool) -> void:
	_trace_categories[category] = enabled


func _write(level: String, category: String, message: String) -> String:
	if _is_debug:
		assert(CATEGORIES.has(category), "Unknown log category: %s" % category)
	var line: String = "[%s] [%s] [%s] %s" % [_timestamp(), level, category, message]
	print(line)
	return line


func _timestamp() -> String:
	# Single clock read so the seconds and the milliseconds can never disagree.
	var now: float = Time.get_unix_time_from_system()
	var time_zone: Dictionary = Time.get_time_zone_from_system()
	var bias_minutes: int = time_zone.get("bias", 0)
	var local_seconds: int = int(now) + bias_minutes * 60
	var millis: int = int((now - floorf(now)) * 1000.0)
	return "%s.%03d" % [Time.get_time_string_from_unix_time(local_seconds), millis]
