extends Node
## Player settings: volumes, window mode, VSync, damage numbers. Holds no run state.
## Loads and applies user://settings.cfg at startup (never writes it then), applies every change at once
## and saves it atomically (temporary file, then rename). An unreadable file or value falls back to the
## default and is logged, never blocking the start (AR28).
## The [input] section arrives with story 1.7.

## Local signal: any setting changed (menus refresh their widgets).
signal changed

const FILE_PATH: String = "user://settings.cfg"

const MASTER_BUS: StringName = &"Master"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = Audio.SFX_BUS
const UI_BUS: StringName = &"UI"

## Player preferences, not GDD gameplay values: defined here only.
const DEFAULT_VOLUMES: Dictionary[StringName, float] = {
	MASTER_BUS: 0.8,
	MUSIC_BUS: 1.0,
	SFX_BUS: 1.0,
	UI_BUS: 1.0,
}
const DEFAULT_FULLSCREEN: bool = false
const DEFAULT_VSYNC: bool = true
const DEFAULT_DAMAGE_NUMBERS: bool = false

const SECTION_AUDIO: String = "audio"
const SECTION_DISPLAY: String = "display"
## Key of each bus in the [audio] section.
const VOLUME_KEYS: Dictionary[StringName, String] = {
	MASTER_BUS: "master",
	MUSIC_BUS: "music",
	SFX_BUS: "sfx",
	UI_BUS: "ui",
}
const KEY_FULLSCREEN: String = "fullscreen"
const KEY_VSYNC: String = "vsync"
const KEY_DAMAGE_NUMBERS: String = "damage_numbers"

## Read-only from outside: use the setters.
var fullscreen: bool = DEFAULT_FULLSCREEN
var vsync: bool = DEFAULT_VSYNC
var damage_numbers: bool = DEFAULT_DAMAGE_NUMBERS

var _volumes: Dictionary[StringName, float] = DEFAULT_VOLUMES.duplicate()
var _path: String = FILE_PATH


func _ready() -> void:
	for bus: StringName in DEFAULT_VOLUMES:
		if AudioServer.get_bus_index(bus) == -1:
			Log.error("audio", "bus %s is missing from default_bus_layout.tres" % bus)
			assert(false, "Missing audio bus")
	load_from(FILE_PATH)


## Loads, validates and applies the settings of path; later changes are saved there.
## Never writes: a missing file stays missing until the first change. Public for the checks.
func load_from(path: String) -> void:
	_path = path
	_reset_to_defaults()
	var config: ConfigFile = ConfigFile.new()
	var err: Error = config.load(path)
	if err == ERR_FILE_NOT_FOUND:
		Log.warn("save", "%s missing, using defaults" % path.get_file())
	elif err != OK and err != ERR_PARSE_ERROR and err != ERR_FILE_CORRUPT:
		# Cannot open or read (locked by an antivirus or a sync tool, permissions): the content may be fine,
		# so leave the file where it is.
		Log.warn("save", "%s cannot be read (error %d), using defaults" % [path.get_file(), err])
	elif err != OK:
		# Unreadable content: quarantined.
		var corrupt_path: String = path + ".corrupt"
		var rename_err: Error = DirAccess.rename_absolute(path, corrupt_path)
		Log.warn("save", "%s unreadable (error %d), using defaults, moved to %s (rename error %d)" % [
			path.get_file(), err, corrupt_path.get_file(), rename_err,
		])
	else:
		_read(config)
	_apply_all()
	changed.emit()


## Linear volume [0, 1] of bus. 0 for an unknown bus (reported).
func volume(bus: StringName) -> float:
	if not _check_bus(bus):
		return 0.0
	return _volumes[bus]


## Applies and saves. linear is clamped to [0, 1]; a non-finite value falls back to the default.
func set_volume(bus: StringName, linear: float) -> void:
	if not _check_bus(bus):
		return
	var value: float = _sanitize_volume(bus, linear)
	if value == _volumes[bus]:
		return
	_volumes[bus] = value
	_apply_volume(bus, value)
	_save()
	changed.emit()


## Applies only, without saving (a slider being dragged). set_volume() saves the final value.
func preview_volume(bus: StringName, linear: float) -> void:
	if not _check_bus(bus):
		return
	_apply_volume(bus, _sanitize_volume(bus, linear))


func set_fullscreen(value: bool) -> void:
	if value == fullscreen:
		return
	fullscreen = value
	_apply_fullscreen()
	_save()
	changed.emit()


func set_vsync(value: bool) -> void:
	if value == vsync:
		return
	vsync = value
	_apply_vsync()
	_save()
	changed.emit()


func set_damage_numbers(value: bool) -> void:
	if value == damage_numbers:
		return
	damage_numbers = value
	_save()
	changed.emit()


func _reset_to_defaults() -> void:
	_volumes = DEFAULT_VOLUMES.duplicate()
	fullscreen = DEFAULT_FULLSCREEN
	vsync = DEFAULT_VSYNC
	damage_numbers = DEFAULT_DAMAGE_NUMBERS


## A missing key keeps its default silently; a wrong type or an out-of-range value logs one warning.
func _read(config: ConfigFile) -> void:
	for bus: StringName in VOLUME_KEYS:
		var key: String = VOLUME_KEYS[bus]
		if not config.has_section_key(SECTION_AUDIO, key):
			continue
		var raw: Variant = config.get_value(SECTION_AUDIO, key)
		var type: int = typeof(raw)
		if type != TYPE_FLOAT and type != TYPE_INT:
			Log.warn("save", "settings %s/%s is not a number, using the default" % [SECTION_AUDIO, key])
			continue
		var number: float = raw
		var value: float = _sanitize_volume(bus, number)
		if value != number:
			Log.warn("save", "settings %s/%s=%s out of range, using %s" % [SECTION_AUDIO, key, number, value])
		_volumes[bus] = value
	fullscreen = _read_bool(config, KEY_FULLSCREEN, DEFAULT_FULLSCREEN)
	vsync = _read_bool(config, KEY_VSYNC, DEFAULT_VSYNC)
	damage_numbers = _read_bool(config, KEY_DAMAGE_NUMBERS, DEFAULT_DAMAGE_NUMBERS)


func _read_bool(config: ConfigFile, key: String, default: bool) -> bool:
	if not config.has_section_key(SECTION_DISPLAY, key):
		return default
	var raw: Variant = config.get_value(SECTION_DISPLAY, key)
	if typeof(raw) != TYPE_BOOL:
		Log.warn("save", "settings %s/%s is not a boolean, using the default" % [SECTION_DISPLAY, key])
		return default
	return raw


func _sanitize_volume(bus: StringName, linear: float) -> float:
	if not is_finite(linear):
		return DEFAULT_VOLUMES[bus]
	return clampf(linear, 0.0, 1.0)


func _check_bus(bus: StringName) -> bool:
	if DEFAULT_VOLUMES.has(bus):
		return true
	Log.error("audio", "unknown audio bus %s" % bus)
	assert(false, "Unknown audio bus")
	return false


func _apply_all() -> void:
	for bus: StringName in _volumes:
		_apply_volume(bus, _volumes[bus])
	_apply_fullscreen()
	_apply_vsync()


func _apply_volume(bus: StringName, linear: float) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	if index == -1:
		return # reported in _ready()
	AudioServer.set_bus_volume_linear(index, linear)
	AudioServer.set_bus_mute(index, linear <= 0.0) # linear_to_db(0) is -inf


## Borderless fullscreen (MODE_FULLSCREEN). Exclusive fullscreen is a story 1.8 option.
func _apply_fullscreen() -> void:
	var window: Window = get_window()
	var wanted: Window.Mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
	if window.mode == wanted:
		return
	window.mode = wanted
	if fullscreen:
		return
	# Back to windowed: at least the project's startup window size (1280x720).
	var width: int = ProjectSettings.get_setting("display/window/size/window_width_override", 0)
	var height: int = ProjectSettings.get_setting("display/window/size/window_height_override", 0)
	var startup_size: Vector2i = Vector2i(width, height)
	if window.size.x < startup_size.x or window.size.y < startup_size.y:
		window.size = window.size.max(startup_size)


## Only when the mode differs: some drivers (WSLg) warn on every call, even for the current mode.
func _apply_vsync() -> void:
	var wanted: DisplayServer.VSyncMode = DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != wanted:
		DisplayServer.window_set_vsync_mode(wanted)


## Atomic write: a fresh ConfigFile saved to a temporary file, then renamed over the real one.
## A failure is logged and the game goes on (the existing file stays intact if the first step fails).
## Private until story 6.8 needs the same for run.json and profile.json.
func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for bus: StringName in VOLUME_KEYS:
		config.set_value(SECTION_AUDIO, VOLUME_KEYS[bus], _volumes[bus])
	config.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, fullscreen)
	config.set_value(SECTION_DISPLAY, KEY_VSYNC, vsync)
	config.set_value(SECTION_DISPLAY, KEY_DAMAGE_NUMBERS, damage_numbers)
	var tmp_path: String = _path + ".tmp"
	var err: Error = config.save(tmp_path)
	if err != OK:
		Log.error("save", "cannot write %s (error %d)" % [tmp_path.get_file(), err])
		return
	# On Windows, Godot's rename removes an existing target first (short non-atomic window, engine side).
	err = DirAccess.rename_absolute(tmp_path, _path)
	if err != OK:
		Log.error("save", "cannot rename %s to %s (error %d)" % [tmp_path.get_file(), _path.get_file(), err])
		return
	Log.debug("save", "%s written" % _path.get_file())
