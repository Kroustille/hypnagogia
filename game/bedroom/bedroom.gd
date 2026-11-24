class_name Bedroom
extends Node2D
## The hub (story 6.5, D14): a one-screen room where every night starts and where the wake screen can bring the player
## back. The player walks (BedroomWalker), the bed starts the run, the desk opens the seed window. The bedroom only
## asks: Main replaces it by a Run (or freezes it for the seed window). The alarm clock shows the time of
## the last run (story 6.6).

## The player stands at the bed: interact puts them to sleep.
signal sleep_requested
## The player stands at the desk: interact opens the seed window.
signal seed_entry_requested

## Walls included: the frame the camera is centered on (the room is smaller than the screen, so it never scrolls).
const FRAME_TILES: Vector2i = Const.ROOM_TILES + Vector2i(2, 2)

var _at_bed: bool = false
var _at_desk: bool = false
var _requested: bool = false

@onready var _walker: BedroomWalker = %Walker
@onready var _camera: Camera2D = %Camera
@onready var _bed_zone: Area2D = %BedZone
@onready var _desk_zone: Area2D = %DeskZone
@onready var _prompt: Label = %Prompt
@onready var _alarm_clock: Label = %AlarmClock


func _ready() -> void:
	var frame_px: Vector2 = Vector2(FRAME_TILES * Const.TILE_SIZE)
	# A fixed camera: the player position given is the center of the frame, so the view is centered whatever happens.
	_camera.position = Vector2(RoomCamera.target(frame_px / 2.0, frame_px, Vector2(Const.VIEWPORT), 0.0))
	set_clock_minute(-1)
	_bed_zone.body_entered.connect(_on_bed_zone_body_entered)
	_bed_zone.body_exited.connect(_on_bed_zone_body_exited)
	_desk_zone.body_entered.connect(_on_desk_zone_body_entered)
	_desk_zone.body_exited.connect(_on_desk_zone_body_exited)
	_refresh_prompt()


## The alarm clock shows the time of the last run (story 6.6); -1 (no run yet) shows the start of the night.
func set_clock_minute(minute: int) -> void:
	_alarm_clock.text = WakeClock.format(minute if minute >= 0 else Tuning.WAKE.start_minute_of_day)
	_alarm_clock.visible = true


func walker() -> BedroomWalker:
	return _walker


func is_prompt_visible() -> bool:
	return _prompt.visible


func prompt_text() -> String:
	return _prompt.text


## Not in _physics_process: a press is an event. A frozen bedroom (ActiveScene disabled) never gets it.
func _unhandled_input(event: InputEvent) -> void:
	if _requested or not event.is_action_pressed(&"interact") or event.is_echo():
		return
	if _at_bed:
		_requested = true
		get_viewport().set_input_as_handled()
		sleep_requested.emit()
	elif _at_desk:
		get_viewport().set_input_as_handled()
		seed_entry_requested.emit()


func _on_bed_zone_body_entered(body: Node2D) -> void:
	if body == _walker:
		_at_bed = true
		_refresh_prompt()


func _on_bed_zone_body_exited(body: Node2D) -> void:
	if body == _walker:
		_at_bed = false
		_refresh_prompt()


func _on_desk_zone_body_entered(body: Node2D) -> void:
	if body == _walker:
		_at_desk = true
		_refresh_prompt()


func _on_desk_zone_body_exited(body: Node2D) -> void:
	if body == _walker:
		_at_desk = false
		_refresh_prompt()


## The bed wins when both zones overlap.
func _refresh_prompt() -> void:
	_prompt.visible = _at_bed or _at_desk
	if _at_bed:
		_prompt.text = tr(&"UI_BEDROOM_SLEEP") % _interact_key_label()
	elif _at_desk:
		_prompt.text = tr(&"UI_BEDROOM_SEED") % _interact_key_label()


## Label of the first key bound to interact. Works headless (unlike DisplayServer.keyboard_get_label_from_physical()).
func _interact_key_label() -> String:
	for event: InputEvent in InputMap.action_get_events(&"interact"):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			return key.as_text_physical_keycode()
	Log.error("ui", "action interact has no key")
	assert(false, "Action interact needs a key")
	return "?"
