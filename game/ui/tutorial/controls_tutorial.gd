class_name ControlsTutorial
extends CanvasLayer
## The controls help of the start room of the first floor (story 4.8): move, shoot, dash, the two powers and the consumable,
## each with the keys of the device the player used last (keyboard and mouse, or gamepad), read from the InputMap, never typed here.
## It follows the player's change of device while it is shown. Texts come from tr() (localization/strings.csv).
## It knows the input system only: nothing of the room or the player.

enum Device { KEYBOARD, GAMEPAD }

## Button names of the gamepad, by JoyButton index (the pad labels are the hardware's, not translated).
const JOY_BUTTON_NAMES: Dictionary[int, String] = {3: "Y", 9: "LB", 10: "RB"}
## Axis names of the triggers, by JoyAxis index.
const JOY_TRIGGER_NAMES: Dictionary[int, String] = {4: "LT", 5: "RT"}
const JOY_STICK_LEFT_AXES: Array[int] = [0, 1]
const JOY_STICK_RIGHT_AXES: Array[int] = [2, 3]
## Stick deflection that counts as the player using the gamepad (not a drifting stick).
const JOY_ACTIVITY_THRESHOLD: float = 0.5
## Top margin under the HUD band, in pixels (a layout value, not gameplay).
const TOP_MARGIN: int = 30
const LINE_SEPARATION: int = 2

## The help lines: label key, then the actions whose keys are shown (several: shown together).
const LINES: Array[Dictionary] = [
	{"label": &"UI_TUTORIAL_MOVE", "actions": [&"move_up", &"move_left", &"move_down", &"move_right"]},
	{"label": &"UI_TUTORIAL_SHOOT", "actions": [&"shoot"]},
	{"label": &"UI_TUTORIAL_DASH", "actions": [&"dash"]},
	{"label": &"UI_TUTORIAL_AWAKENING", "actions": [&"power_1"]},
	{"label": &"UI_TUTORIAL_GLIDE", "actions": [&"power_2"]},
	{"label": &"UI_TUTORIAL_CONSUMABLE", "actions": [&"use_consumable"]},
]

var _device: Device = Device.KEYBOARD
var _labels: Array[Label] = []


func _ready() -> void:
	var root: Control = Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var box: VBoxContainer = VBoxContainer.new()
	box.name = "Lines"
	box.add_theme_constant_override(&"separation", LINE_SEPARATION)
	box.set_anchors_preset(Control.PRESET_CENTER_TOP)
	box.position.y = TOP_MARGIN
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	for line: Dictionary in LINES:
		var label: Label = Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(label)
		_labels.append(label)
	_device = Device.GAMEPAD if not Input.get_connected_joypads().is_empty() else Device.KEYBOARD
	_refresh()


## The last device the player touched decides the keys shown.
func _input(event: InputEvent) -> void:
	var used: int = _device_of(event)
	if used != -1 and used != _device:
		_device = used as Device
		_refresh()


## The device an event comes from, -1 for an event that says nothing (a still stick, a release).
static func _device_of(event: InputEvent) -> int:
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		return Device.KEYBOARD
	if event is InputEventJoypadButton:
		return Device.GAMEPAD
	var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion != null and absf(motion.axis_value) >= JOY_ACTIVITY_THRESHOLD:
		return Device.GAMEPAD
	return -1


func device() -> Device:
	return _device


## Switches to a device and redraws (checks and the input handler).
func show_device(device_used: Device) -> void:
	_device = device_used
	_refresh()


## The text of the line of the given index (checks).
func line_text(index: int) -> String:
	return _labels[index].text


func _refresh() -> void:
	for i: int in LINES.size():
		var actions: Array = LINES[i]["actions"]
		var label_key: StringName = LINES[i]["label"]
		_labels[i].text = "%s  %s" % [keys_text(actions, _device), tr(label_key)]


## The keys of some actions for a device, from the InputMap ("?" for an action without any event of that device).
func keys_text(actions: Array, device_used: Device) -> String:
	var parts: PackedStringArray = PackedStringArray()
	var seen_sticks: Dictionary[String, bool] = {}
	for action: StringName in actions:
		var text: String = _event_text(action, device_used)
		if device_used == Device.GAMEPAD and text.begins_with("stick:"):
			if seen_sticks.has(text):
				continue # four directions on one stick: one name
			seen_sticks[text] = true
			text = tr(&"UI_TUTORIAL_STICK_LEFT") if text == "stick:left" else tr(&"UI_TUTORIAL_STICK_RIGHT")
		parts.append(text)
	return "/".join(parts) if device_used == Device.KEYBOARD and actions.size() > 1 else " ".join(parts)


## The name of the key as the player's layout prints it (AZERTY: Z/Q/S/D); the US name when the layout is unknown (headless).
func _key_label(key: InputEventKey) -> String:
	if DisplayServer.get_name() != "headless": # the headless server has no layout and logs an error
		var label: Key = DisplayServer.keyboard_get_label_from_physical(key.physical_keycode)
		if label != KEY_NONE:
			return OS.get_keycode_string(label)
	return key.as_text_physical_keycode()


func _event_text(action: StringName, device_used: Device) -> String:
	for event: InputEvent in InputMap.action_get_events(action):
		if device_used == Device.KEYBOARD:
			var key: InputEventKey = event as InputEventKey
			if key != null:
				return _key_label(key)
			var click: InputEventMouseButton = event as InputEventMouseButton
			if click != null:
				return tr(&"UI_TUTORIAL_MOUSE_LEFT") if click.button_index == MOUSE_BUTTON_LEFT else tr(&"UI_TUTORIAL_MOUSE_RIGHT")
		else:
			var button: InputEventJoypadButton = event as InputEventJoypadButton
			if button != null:
				return JOY_BUTTON_NAMES.get(button.button_index, "B%d" % button.button_index)
			var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
			if motion != null:
				if JOY_TRIGGER_NAMES.has(motion.axis):
					return JOY_TRIGGER_NAMES[motion.axis]
				if JOY_STICK_LEFT_AXES.has(motion.axis):
					return "stick:left"
				if JOY_STICK_RIGHT_AXES.has(motion.axis):
					return "stick:right"
	return "?"
