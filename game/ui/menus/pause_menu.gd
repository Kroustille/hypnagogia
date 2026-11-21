class_name PauseMenu
extends Control
## Pause menu: resume, settings, quit. Main owns the pause: it opens this menu and listens to its
## local signals. Pause, Start, Escape or B (pause / ui_cancel) asks to resume.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal resume_requested
signal settings_requested
signal quit_requested

@onready var _title: Label = %Title
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_title.text = tr(&"UI_PAUSE_TITLE")
	_resume_button.text = tr(&"UI_PAUSE_RESUME")
	_settings_button.text = tr(&"UI_PAUSE_SETTINGS")
	_quit_button.text = tr(&"UI_PAUSE_QUIT")
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	hide()


## Shows the menu, focus on Resume (or on Settings when coming back from the settings menu).
func open(focus_settings: bool = false) -> void:
	show()
	if focus_settings:
		_settings_button.grab_focus()
	else:
		_resume_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		resume_requested.emit()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_settings_button_pressed() -> void:
	settings_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
