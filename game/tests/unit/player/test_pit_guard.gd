extends GutTest
## PitGuard: remembers the last safe position, decides the fall (story 4.3, AC 1).

var _guard: PitGuard


func before_each() -> void:
	_guard = PitGuard.new()


func test_nothing_is_safe_before_the_first_observation() -> void:
	assert_false(_guard.has_safe())
	assert_false(_guard.should_fall(Vector2(10, 10), true), "no place to return to: no fall")


func test_a_safe_observation_is_remembered() -> void:
	_guard.observe(Vector2(8, 8), true)
	assert_eq(_guard.last_safe, Vector2(8, 8))
	assert_true(_guard.has_safe())


func test_an_unsafe_observation_keeps_the_previous_position() -> void:
	_guard.observe(Vector2(8, 8), true)
	_guard.observe(Vector2(24, 8), false)
	assert_eq(_guard.last_safe, Vector2(8, 8))


func test_it_falls_in_a_pit_only_once_a_safe_position_is_known() -> void:
	_guard.observe(Vector2(8, 8), true)
	assert_true(_guard.should_fall(Vector2(24, 8), true))
	assert_false(_guard.should_fall(Vector2(8, 8), false))
