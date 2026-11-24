class_name PauseMenu
extends Control
## Pause menu: resume, settings, new game on a seed, quit. Main owns the pause: it opens this menu and listens to its
## local signals. Pause, Start, Escape or B (pause / ui_cancel) asks to resume.
## Texts come from tr() (localization/strings.csv), never from the scene.

signal resume_requested
signal settings_requested
signal quit_requested
## The player asks to start a new game on a seed they type (Main opens the SeedEntry window).
signal new_seed_requested

enum Focus { RESUME, SETTINGS, NEW_SEED }

@onready var _title: Label = %Title
@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _seed_label: Label = %SeedLabel
@onready var _new_seed_button: Button = %NewSeedButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_title.text = tr(&"UI_PAUSE_TITLE")
	_resume_button.text = tr(&"UI_PAUSE_RESUME")
	_settings_button.text = tr(&"UI_PAUSE_SETTINGS")
	_new_seed_button.text = tr(&"UI_SEED_NEW_GAME")
	_quit_button.text = tr(&"UI_PAUSE_QUIT")
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_settings_button.pressed.connect(_on_settings_button_pressed)
	_new_seed_button.pressed.connect(_on_new_seed_button_pressed)
	_quit_button.pressed.connect(_on_quit_button_pressed)
	hide()


## Shows the menu with the seed of the run in progress, focus on Resume (or on Settings when coming back from the
## settings menu, or on the seed button when the seed window closes). in_run: a floor run is saved, so Quit says so.
func open(seed_code: String, focus: Focus = Focus.RESUME, in_run: bool = false) -> void:
	_quit_button.text = tr(&"UI_PAUSE_SAVE_QUIT" if in_run else &"UI_PAUSE_QUIT") # in a floor run the night stays saved
	_seed_label.text = tr(&"UI_PAUSE_SEED") % seed_code
	_seed_label.visible = not seed_code.is_empty() # no run behind it (the bedroom)
	show()
	match focus:
		Focus.SETTINGS:
			_settings_button.grab_focus()
		Focus.NEW_SEED:
			_new_seed_button.grab_focus()
		_:
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


func _on_new_seed_button_pressed() -> void:
	new_seed_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()
