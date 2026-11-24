class_name WakeScreen
extends Control
## Wake-up screen shown by Main when a run ends (death or victory; a victory has no "was this death fair?" question).
## The restart key or the button asks Main for a new run.
## Inputs are ignored for a short guard so a held or mashed key at the moment of death cannot skip it.
## The game behind is frozen by Main (GameClock.paused): the guard counts raw physics ticks, not GameClock time.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal restart_requested
## The player goes back to the bedroom instead of falling asleep again at once (story 6.5).
signal wake_up_requested
## The player answered "was this death fair?". Never emitted when they restart without answering.
signal verdict_given(just: bool)
## The player asks to start a new game on a seed they type (Main opens the SeedEntry window).
signal new_seed_requested

## Input guard after the screen opens, in seconds (UI placeholder, not a gameplay value).
const INPUT_GUARD_SECONDS: float = 0.3

var _guard_ticks_left: float = 0.0
var _armed: bool = false
var _answered: bool = false
var _victory: bool = false

@onready var _time_label: Label = %TimeLabel

@onready var _title: Label = %Title
@onready var _seed_label: Label = %SeedLabel
@onready var _restart_button: Button = %RestartButton
@onready var _new_seed_button: Button = %NewSeedButton
@onready var _bedroom_button: Button = %BedroomButton
@onready var _question: Label = %Question
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	_title.text = tr(&"UI_WAKE_TITLE")
	_restart_button.text = tr(&"UI_WAKE_RESTART") % _restart_key_label()
	_new_seed_button.text = tr(&"UI_SEED_NEW_GAME")
	_bedroom_button.text = tr(&"UI_WAKE_BEDROOM")
	_yes_button.text = tr(&"UI_WAKE_YES")
	_no_button.text = tr(&"UI_WAKE_NO")
	_yes_button.pressed.connect(_give_verdict.bind(true))
	_no_button.pressed.connect(_give_verdict.bind(false))
	_restart_button.pressed.connect(_on_restart_button_pressed)
	_new_seed_button.pressed.connect(_on_new_seed_button_pressed)
	_bedroom_button.pressed.connect(_on_bedroom_button_pressed)
	hide()


## Shows the screen with the inputs guarded and the seed of the run that just ended; the restart button takes the focus.
## outcome: Run.Outcome. Anything but VICTORY is a defeat. wake_minute: the time of the wake-up (WakeClock), -1 for none.
func open(seed_code: String, outcome: int = Run.Outcome.DEATH, wake_minute: int = -1) -> void:
	_victory = outcome == Run.Outcome.VICTORY
	_title.text = tr(&"UI_WAKE_TITLE_VICTORY" if _victory else &"UI_WAKE_TITLE")
	_seed_label.text = tr(&"UI_WAKE_SEED") % seed_code
	_time_label.visible = wake_minute >= 0
	_time_label.text = tr(&"UI_WAKE_TIME") % WakeClock.format(wake_minute) if wake_minute >= 0 else ""
	show()
	_guard_ticks_left = INPUT_GUARD_SECONDS * Engine.physics_ticks_per_second
	_armed = false
	_restart_button.disabled = true
	_new_seed_button.disabled = true
	_new_seed_button.focus_mode = Control.FOCUS_NONE # disabled buttons must not take the focus during the guard
	_bedroom_button.focus_mode = Control.FOCUS_NONE
	_bedroom_button.disabled = true
	_answered = false
	_question.text = tr(&"UI_WAKE_QUESTION")
	_question.visible = not _victory
	_yes_button.visible = not _victory
	_no_button.visible = not _victory
	_set_answers_enabled(false)
	_restart_button.grab_focus()


func _physics_process(_delta: float) -> void:
	if not visible or _armed:
		return
	_guard_ticks_left -= 1.0 # raw ticks: GameClock is paused behind this screen
	if _guard_ticks_left <= 1e-6:
		_armed = true
		_restart_button.disabled = false
		_new_seed_button.disabled = false
		_bedroom_button.disabled = false
		_new_seed_button.focus_mode = Control.FOCUS_ALL
		_bedroom_button.focus_mode = Control.FOCUS_ALL
		_set_answers_enabled(true)


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


## Gives the focus back to the seed button (the seed window was cancelled).
func focus_new_seed() -> void:
	if _armed:
		_new_seed_button.grab_focus()
	else:
		_restart_button.grab_focus()


func _on_restart_button_pressed() -> void:
	_request_restart()


func _on_bedroom_button_pressed() -> void:
	if visible and _armed:
		_armed = false # no double request, and no restart behind it
		wake_up_requested.emit()


func _on_new_seed_button_pressed() -> void:
	if visible and _armed:
		new_seed_requested.emit()


## Label of the first key bound to restart. Works headless (unlike DisplayServer.keyboard_get_label_from_physical()).
func _restart_key_label() -> String:
	for event: InputEvent in InputMap.action_get_events(&"restart"):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return key.as_text_physical_keycode()
	Log.error("ui", "action restart has no key")
	assert(false, "Action restart needs a key")
	return "?"


## One answer per death; it does not restart, and the restart button keeps the focus.
func _give_verdict(just: bool) -> void:
	if not visible or not _armed or _answered:
		return
	_answered = true
	_question.text = tr(&"UI_WAKE_ANSWERED")
	_set_answers_enabled(false)
	_restart_button.grab_focus()
	verdict_given.emit(just)


func _set_answers_enabled(enabled: bool) -> void:
	var active: bool = enabled and not _answered and not _victory
	_yes_button.disabled = not active
	_no_button.disabled = not active
	# Disabled buttons must not take the focus (a stick still pushed at death would land on Yes)
	var mode: Control.FocusMode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
	_yes_button.focus_mode = mode
	_no_button.focus_mode = mode
