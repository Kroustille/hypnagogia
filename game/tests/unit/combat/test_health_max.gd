extends GutTest
## Health.lose_max / restore_max: the price of an item paid in hearts (story 5.1, AC 5).

var _health: Health


func before_each() -> void:
	_health = Health.new()
	_health.setup(6, 10, 0.5, GameClock.Group.PLAYER)
	add_child_autofree(_health)


func test_lose_max_lowers_max_and_brings_current_hearts_down() -> void:
	watch_signals(_health)
	assert_eq(_health.lose_max(2), 2)
	assert_eq(_health.max_half_hearts, 4)
	assert_eq(_health.half_hearts, 4)
	assert_signal_emitted(_health, "changed")
	assert_false(_health.is_hit_invulnerable(), "not a hit")


func test_lose_max_never_goes_below_one_heart() -> void:
	assert_eq(_health.lose_max(10), 4, "6 -> 2")
	assert_eq(_health.max_half_hearts, 2)
	assert_eq(_health.lose_max(2), 0)
	assert_eq(_health.max_half_hearts, 2)


func test_hearts_below_the_new_max_stay_and_armor_is_untouched() -> void:
	_health.half_hearts = 2
	_health.add_armor(2)
	_health.lose_max(2)
	assert_eq(_health.half_hearts, 2)
	assert_eq(_health.armor, 2)


func test_restore_max_gives_back_only_what_was_lost() -> void:
	_health.lose_max(2)
	assert_eq(_health.restore_max(4), 2)
	assert_eq(_health.max_half_hearts, 6)
	assert_eq(_health.half_hearts, 4, "the hearts do not come back by themselves")
	assert_eq(_health.restore_max(2), 0)
