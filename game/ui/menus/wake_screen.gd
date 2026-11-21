class_name WakeScreen
extends Control
## Wake-up screen shown by Main when a run ends (death). The restart key or the button asks Main for a new run.
## Inputs are ignored for a short guard so a held or mashed key at the moment of death cannot skip it.
## The game behind is frozen by Main (GameClock.paused): the guard counts raw physics ticks, not GameClock time.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal restart_requested

## Input guard after the screen opens, in seconds (UI placeholder, not a gameplay value).
const INPUT_GUARD_SECONDS: float = 0.3

var _guard_ticks_left: float = 0.0
var _armed: bool = false

@onready var _title: Label = %Title
@onready var _restart_button: Button = %RestartButton


func _ready() -> void:
	_title.text = tr(&"UI_WAKE_TITLE")
	_restart_button.text = tr(&"UI_WAKE_RESTART") % _restart_key_label()
	_restart_button.pressed.connect(_on_restart_button_pressed)
	hide()


## Shows the screen with the inputs guarded; the restart button takes the focus.
func open() -> void:
	show()
	_guard_ticks_left = INPUT_GUARD_SECONDS * Engine.physics_ticks_per_second
	_armed = false
	_restart_button.disabled = true
	_restart_button.grab_focus()


func _physics_process(_delta: float) -> void:
	if not visible or _armed:
		return
	_guard_ticks_left -= 1.0 # raw ticks: GameClock is paused behind this screen
	if _guard_ticks_left <= 1e-6:
		_armed = true
		_restart_button.disabled = false


## Pause and ui_cancel are not consumed: Main ignores them while this screen is open.
func _unhandled_input(event: InputEvent) -> void:
	if not visible or not _armed:
		return
	if event.is_action_pressed(&"restart"):
		get_viewport().set_input_as_handled()
		_request_restart()


func _request_restart() -> void:
	if not visible or not _armed:
		return
	_armed = false # no double request
	restart_requested.emit()


func _on_restart_button_pressed() -> void:
	_request_restart()


## Label of the first key bound to restart. Works headless (unlike DisplayServer.keyboard_get_label_from_physical()).
func _restart_key_label() -> String:
	for event: InputEvent in InputMap.action_get_events(&"restart"):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return key.as_text_physical_keycode()
	Log.error("ui", "action restart has no key")
	assert(false, "Action restart needs a key")
	return "?"
