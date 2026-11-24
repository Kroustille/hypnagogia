extends GutTest
## Banner (story 5.7 review): a queued banner waits for the one on screen, a requested one replaces it.

var _banner: Banner


func before_each() -> void:
	_banner = Banner.new()
	add_child_autofree(_banner)


func test_a_queued_banner_shows_at_once_when_idle() -> void:
	Events.banner_queued.emit(&"A", &"", &"")
	assert_true(_banner.is_showing())
	assert_eq(_banner.lines()[0], tr(&"A"))


func test_a_queued_banner_waits_for_the_one_on_screen() -> void:
	Events.banner_requested.emit(&"ITEM_FALLING_TOOTH_NAME", &"ITEM_FALLING_TOOTH_BONUS", &"")
	Events.banner_queued.emit(&"SYNERGY_FALL_2_NAME", &"SYNERGY_FALL_2_DESC", &"")
	assert_eq(_banner.lines()[0], tr(&"ITEM_FALLING_TOOTH_NAME"), "the item stays on screen")
	_banner._process(Banner.DURATION + 0.1)
	assert_true(_banner.is_showing())
	assert_eq(_banner.lines()[0], tr(&"SYNERGY_FALL_2_NAME"), "then the synergy")
	_banner._process(Banner.DURATION + 0.1)
	assert_false(_banner.is_showing(), "nothing left")


func test_a_requested_banner_replaces_without_emptying_the_queue() -> void:
	Events.banner_requested.emit(&"ITEM_FALLING_TOOTH_NAME", &"", &"")
	Events.banner_queued.emit(&"SYNERGY_FALL_2_NAME", &"", &"")
	Events.banner_requested.emit(&"ITEM_LEAD_LEGS_NAME", &"", &"")
	assert_eq(_banner.lines()[0], tr(&"ITEM_LEAD_LEGS_NAME"))
	_banner._process(Banner.DURATION + 0.1)
	assert_eq(_banner.lines()[0], tr(&"SYNERGY_FALL_2_NAME"))
