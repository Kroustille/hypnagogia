class_name ResumePrompt
extends Control
## "Resume the night?" window (story 6.8), shown at launch when run.json holds a readable night. Main opens it over the
## frozen game and listens to its signals. No cancel key: the player picks one of the two answers.
## Texts come from tr() (localization/strings.csv), never from the scene.

## Continue the saved night, from the start of the room it was in.
signal resume_chosen
## Give the saved night up and start from the bedroom.
signal new_night_chosen

@onready var _title: Label = %Title
@onready var _resume_button: Button = %ResumeButton
@onready var _new_night_button: Button = %NewNightButton


func _ready() -> void:
	_title.text = tr(&"UI_RESUME_TITLE")
	_resume_button.text = tr(&"UI_RESUME_YES")
	_new_night_button.text = tr(&"UI_RESUME_NO")
	_resume_button.pressed.connect(_on_resume_button_pressed)
	_new_night_button.pressed.connect(_on_new_night_button_pressed)
	hide()


## Shows the window, "Resume" focused.
func open() -> void:
	show()
	_resume_button.grab_focus()


func _on_resume_button_pressed() -> void:
	resume_chosen.emit()


func _on_new_night_button_pressed() -> void:
	new_night_chosen.emit()
