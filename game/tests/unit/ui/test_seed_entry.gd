extends GutTest
## The seed window (story 4.11, AC 2 and 4): a valid code is decoded and emitted, an invalid one is refused with a message.

const SCENE: PackedScene = preload("res://ui/menus/seed_entry.tscn")

var _entry: SeedEntry
var _submitted: Array[int] = []
var _cancels: int = 0


func before_each() -> void:
	_submitted = []
	_cancels = 0
	_entry = SCENE.instantiate() as SeedEntry
	add_child_autofree(_entry)
	_entry.seed_submitted.connect(func(value: int) -> void: _submitted.append(value))
	_entry.cancelled.connect(func() -> void: _cancels += 1)
	_entry.open()


func test_a_valid_code_emits_its_seed() -> void:
	_entry.set_text("00000c1s")
	_entry.submit()
	assert_eq(_submitted, [12345] as Array[int])
	assert_eq(_entry.error_text(), "")


func test_the_zero_seed_is_valid() -> void:
	_entry.set_text("0000-0000")
	_entry.submit()
	assert_eq(_submitted, [0] as Array[int])


func test_an_invalid_code_is_refused_and_the_window_stays_open() -> void:
	for code: String in ["", "1234567", "123456789", "1234567U", "1234 567!"]:
		_entry.set_text(code)
		_entry.submit()
		assert_eq(_entry.error_text(), tr(&"UI_SEED_INVALID"), "message for '%s'" % code)
	assert_eq(_submitted.size(), 0, "nothing emitted")
	assert_true(_entry.visible)


func test_typing_clears_the_message() -> void:
	_entry.set_text("zz")
	_entry.submit()
	assert_ne(_entry.error_text(), "")
	var field: LineEdit = _entry.get_node("%Field") as LineEdit
	field.text_changed.emit("zzz")
	assert_eq(_entry.error_text(), "")


func test_the_field_has_the_focus_and_is_empty_when_opened() -> void:
	var field: LineEdit = _entry.get_node("%Field") as LineEdit
	assert_eq(field.text, "")
	assert_true(field.has_focus())


func test_the_message_comes_from_the_translations() -> void:
	assert_ne(tr(&"UI_SEED_INVALID"), "UI_SEED_INVALID")
	assert_ne(tr(&"UI_SEED_NEW_GAME"), "UI_SEED_NEW_GAME")


func test_escape_cancels_and_is_consumed() -> void:
	var event: InputEventAction = InputEventAction.new()
	event.action = &"ui_cancel"
	event.pressed = true
	_entry._input(event)
	assert_eq(_cancels, 1)
