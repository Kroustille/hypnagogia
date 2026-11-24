extends GutTest
## strings.csv: a value with a comma is quoted, or the CSV splits it and tr() returns a truncated text.


func test_the_naked_in_public_bonus_keeps_its_decimal_comma() -> void:
	assert_string_contains(tr(&"ITEM_NAKED_IN_PUBLIC_BONUS"), "1,5 s")


func test_the_mirror_cost_is_whole() -> void:
	assert_string_contains(tr(&"ITEM_MIRROR_COST"), "1 salle de combat sur 4")
