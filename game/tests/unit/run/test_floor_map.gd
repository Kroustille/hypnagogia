extends GutTest
## What the player did on the floor (story 4.8, AC 6).


func test_a_new_map_has_seen_nothing() -> void:
	var map: FloorMap = FloorMap.new()
	assert_false(map.is_visited(Vector2i(2, 3)))
	assert_false(map.is_cleared(Vector2i(2, 3)))
	assert_eq(map.visited.size(), 0)


func test_entering_a_cell_makes_it_current_and_visited() -> void:
	var map: FloorMap = FloorMap.new()
	map.mark_entered(Vector2i(1, 1))
	map.mark_entered(Vector2i(2, 1))
	assert_eq(map.current, Vector2i(2, 1))
	assert_true(map.is_visited(Vector2i(1, 1)))
	assert_true(map.is_visited(Vector2i(2, 1)))
	assert_eq(map.visited.size(), 2)


func test_entering_the_same_cell_twice_counts_once() -> void:
	var map: FloorMap = FloorMap.new()
	map.mark_entered(Vector2i(1, 1))
	map.mark_entered(Vector2i(1, 1))
	assert_eq(map.visited.size(), 1)


func test_clearing_a_cell_is_remembered_and_does_not_move_the_player() -> void:
	var map: FloorMap = FloorMap.new()
	map.mark_entered(Vector2i(4, 4))
	map.mark_cleared(Vector2i(4, 4))
	map.mark_cleared(Vector2i(0, 0))
	assert_true(map.is_cleared(Vector2i(4, 4)))
	assert_true(map.is_cleared(Vector2i(0, 0)))
	assert_false(map.is_cleared(Vector2i(1, 0)))
	assert_eq(map.current, Vector2i(4, 4))
	assert_false(map.is_visited(Vector2i(0, 0)), "cleared is not visited")
