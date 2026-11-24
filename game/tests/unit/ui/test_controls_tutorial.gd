extends GutTest
## The controls help reads the keys of the active device from the InputMap (story 4.8, AC 7).

var _tutorial: ControlsTutorial


func before_each() -> void:
	_tutorial = ControlsTutorial.new()
	add_child_autofree(_tutorial)


func test_the_keyboard_help_names_the_keys_of_the_input_map() -> void:
	_tutorial.show_device(ControlsTutorial.Device.KEYBOARD)
	assert_string_contains(_tutorial.line_text(0), "W/A/S/D")
	assert_string_contains(_tutorial.line_text(0), "Se déplacer")
	assert_string_contains(_tutorial.line_text(1), "Clic gauche")
	assert_string_contains(_tutorial.line_text(2), "Space")
	assert_string_contains(_tutorial.line_text(3), "Clic droit")
	assert_string_contains(_tutorial.line_text(4), "Glissement")
	assert_string_contains(_tutorial.line_text(5), "Consommable")
	assert_string_contains(_tutorial.line_text(5), "Q")


func test_the_gamepad_help_names_the_buttons_and_the_stick() -> void:
	_tutorial.show_device(ControlsTutorial.Device.GAMEPAD)
	assert_string_contains(_tutorial.line_text(0), "Stick gauche")
	assert_string_contains(_tutorial.line_text(1), "RT")
	assert_string_contains(_tutorial.line_text(2), "RB")
	assert_string_contains(_tutorial.line_text(3), "LT")
	assert_string_contains(_tutorial.line_text(4), "LB")
	assert_string_contains(_tutorial.line_text(5), "Y")


func test_a_change_of_device_changes_the_help() -> void:
	_tutorial.show_device(ControlsTutorial.Device.KEYBOARD)
	var button: InputEventJoypadButton = InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	_tutorial._input(button)
	assert_eq(_tutorial.device(), ControlsTutorial.Device.GAMEPAD)
	assert_string_contains(_tutorial.line_text(1), "RT")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_W
	key.pressed = true
	_tutorial._input(key)
	assert_eq(_tutorial.device(), ControlsTutorial.Device.KEYBOARD)
	assert_string_contains(_tutorial.line_text(1), "Clic gauche")


func test_a_still_stick_does_not_change_the_device() -> void:
	_tutorial.show_device(ControlsTutorial.Device.KEYBOARD)
	var motion: InputEventJoypadMotion = InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.1
	_tutorial._input(motion)
	assert_eq(_tutorial.device(), ControlsTutorial.Device.KEYBOARD)
	motion.axis_value = 0.9
	_tutorial._input(motion)
	assert_eq(_tutorial.device(), ControlsTutorial.Device.GAMEPAD)


func test_the_keyboard_help_follows_the_active_layout_with_a_us_fallback() -> void:
	var key: InputEventKey = InputMap.action_get_events(&"move_up")[0] as InputEventKey
	var headless: bool = DisplayServer.get_name() == "headless"
	var label: Key = KEY_NONE if headless else DisplayServer.keyboard_get_label_from_physical(key.physical_keycode)
	var expected: String = OS.get_keycode_string(label) if label != KEY_NONE else key.as_text_physical_keycode()
	_tutorial.show_device(ControlsTutorial.Device.KEYBOARD)
	assert_string_contains(_tutorial.line_text(0), expected)
	if headless:
		assert_string_contains(_tutorial.line_text(0), "W/A/S/D", "headless: the US names")
