class_name SeedEntry
extends Control
## Seed entry window (story 4.11, FR43): a text field, Enter validates, Escape cancels. Keyboard only (a gamepad
## player can replay the current seed but not type one: the gamepad menus are epic 7). Main shows it over the pause
## menu or the wake screen and starts the run on seed_submitted. Texts come from tr() (localization/strings.csv).

## A valid code was typed: the seed is already decoded (RunRng.code_to_seed).
signal seed_submitted(seed_value: int)
signal cancelled

@onready var _prompt: Label = %Prompt
@onready var _field: LineEdit = %Field
@onready var _error: Label = %Error
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	_prompt.text = tr(&"UI_SEED_PROMPT")
	_confirm_button.text = tr(&"UI_SEED_CONFIRM")
	_cancel_button.text = tr(&"UI_SEED_CANCEL")
	# Room for the separators a player may paste ("ABCD-EFGH"): the code itself is checked on submit.
	_field.max_length = RunRng.CODE_LENGTH * 2
	_field.keep_editing_on_text_submit = true # an invalid Enter must not stop the typing
	_field.text_submitted.connect(_on_field_text_submitted)
	_field.text_changed.connect(_on_field_text_changed)
	_confirm_button.pressed.connect(submit)
	_cancel_button.pressed.connect(_cancel)
	hide()


## Shows the window with an empty field that has the focus.
func open() -> void:
	_field.text = ""
	_error.text = ""
	show()
	_field.grab_focus()
	_field.edit()


## The message shown under the field, empty when there is none.
func error_text() -> String:
	return _error.text


## Types a text in the field (checks and paste-like use); does not validate.
func set_text(text: String) -> void:
	_field.text = text
	_error.text = ""


## Validates the field: emits seed_submitted for a valid code, else shows the message and keeps the window open.
func submit() -> void:
	if not visible:
		return
	var seed_value: int = RunRng.code_to_seed(_field.text)
	if seed_value < 0:
		_error.text = tr(&"UI_SEED_INVALID")
		_field.grab_focus()
		_field.select_all()
		_field.edit()
		return
	seed_submitted.emit(seed_value)


## Escape cancels. Taken in _input, before the focused LineEdit, which would swallow it to leave the edit mode (a second
## press would be needed); consumed, so the pause menu below does not close with it.
func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()


## Enter is the field's text_submitted. Any other key is consumed: no game key (restart, pause, debug) reaches what is below.
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		get_viewport().set_input_as_handled() # modal: no game key (restart, pause, debug) reaches what is below


func _cancel() -> void:
	cancelled.emit()


func _on_field_text_submitted(_text: String) -> void:
	submit()


func _on_field_text_changed(_text: String) -> void:
	_error.text = ""
