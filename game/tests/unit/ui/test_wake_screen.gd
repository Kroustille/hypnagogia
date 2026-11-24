extends GutTest
## The wake screen by outcome (story 6.4): a victory has no "was this death fair?" question.

const SCENE: PackedScene = preload("res://ui/menus/wake_screen.tscn")

var _wake: WakeScreen


func before_each() -> void:
	_wake = SCENE.instantiate() as WakeScreen
	add_child_autofree(_wake)


func _title() -> String:
	return (_wake.get_node("%Title") as Label).text


func _question_shown() -> bool:
	var question: Label = _wake.get_node("%Question") as Label
	return question.is_visible_in_tree()


func test_a_death_keeps_the_title_and_the_question() -> void:
	_wake.open("ABCD1234", Run.Outcome.DEATH)
	assert_eq(_title(), tr(&"UI_WAKE_TITLE"))
	assert_true(_question_shown())
	assert_true((_wake.get_node("%YesButton") as Button).visible)


func test_a_victory_wakes_by_itself_without_a_question() -> void:
	_wake.open("ABCD1234", Run.Outcome.VICTORY)
	assert_eq(_title(), tr(&"UI_WAKE_TITLE_VICTORY"))
	assert_ne(tr(&"UI_WAKE_TITLE_VICTORY"), "UI_WAKE_TITLE_VICTORY", "the string exists")
	assert_false(_question_shown())
	assert_false((_wake.get_node("%YesButton") as Button).visible)
	assert_false((_wake.get_node("%NoButton") as Button).visible)
	assert_true((_wake.get_node("%RestartButton") as Button).has_focus(), "the restart button keeps the focus")


func test_the_next_death_after_a_victory_shows_the_question_again() -> void:
	_wake.open("ABCD1234", Run.Outcome.VICTORY)
	_wake.open("ABCD1234", Run.Outcome.DEATH)
	assert_true(_question_shown())
	assert_eq(_title(), tr(&"UI_WAKE_TITLE"))


func test_an_unknown_outcome_is_a_defeat() -> void:
	_wake.open("ABCD1234", 42)
	assert_eq(_title(), tr(&"UI_WAKE_TITLE"))
	assert_true(_question_shown())
