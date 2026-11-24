extends GutTest
## RoomNav (story 4.5, AC 1 to 3): the grid, the paths around blocked cells, the line test.
## Grid of 12 x 8 cells; a cell (x, y) has its center at ((x + 0.5) * 16, (y + 0.5) * 16).


func _center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * Const.TILE_SIZE


## A vertical wall at column 5 from row 0 to row 5: the way around is through rows 6 and 7.
func _walled() -> RoomNav:
	var blocked: Array[Vector2i] = []
	for y: int in 6:
		blocked.append(Vector2i(5, y))
	return RoomNav.new(Vector2i(12, 8), blocked)


func test_an_open_grid_gives_the_cell_centers_from_start_to_goal() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(12, 8))
	var points: PackedVector2Array = nav.path(_center(Vector2i(1, 1)), _center(Vector2i(4, 1)))
	assert_eq(points[0], _center(Vector2i(1, 1)), "starts at the center of the start cell")
	assert_eq(points[points.size() - 1], _center(Vector2i(4, 1)), "ends at the center of the goal cell")
	assert_eq(points.size(), 4)


func test_a_wall_is_walked_around() -> void:
	var nav: RoomNav = _walled()
	var points: PackedVector2Array = nav.path(_center(Vector2i(2, 2)), _center(Vector2i(8, 2)))
	assert_gt(points.size(), 7, "longer than the straight line")
	var lowest: float = 0.0
	for point: Vector2 in points:
		assert_false(nav.is_blocked(nav.cell_of(point)), "no waypoint on a blocked cell")
		lowest = maxf(lowest, point.y)
	assert_gte(lowest, _center(Vector2i(5, 6)).y, "goes through the opening under the wall")


func test_no_corner_is_cut() -> void:
	# A single blocked cell at (3, 2): from (2, 2) to (4, 3) a diagonal step through the corner is refused.
	var nav: RoomNav = RoomNav.new(Vector2i(8, 6), [Vector2i(3, 2)])
	var points: PackedVector2Array = nav.path(_center(Vector2i(2, 2)), _center(Vector2i(3, 3)))
	# (2, 2) -> (3, 3) is diagonal and touches the blocked neighbor (3, 2): two orthogonal steps instead.
	assert_eq(points.size(), 3, "an orthogonal detour, not the diagonal")
	assert_eq(points[1], _center(Vector2i(2, 3)))


func test_listed_cells_and_the_outside_of_the_grid_are_blocked() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(8, 6), [Vector2i(0, 0), Vector2i(3, 3)])
	assert_true(nav.is_blocked(Vector2i(0, 0)))
	assert_true(nav.is_blocked(Vector2i(3, 3)))
	assert_false(nav.is_blocked(Vector2i(1, 1)))
	assert_true(nav.is_blocked(Vector2i(-1, 2)), "outside the grid counts as blocked")
	assert_true(nav.is_blocked(Vector2i(8, 2)))


func test_updating_a_cell_changes_the_paths() -> void:
	var nav: RoomNav = _walled()
	var from: Vector2 = _center(Vector2i(4, 2))
	var to: Vector2 = _center(Vector2i(6, 2))
	var around: int = nav.path(from, to).size()
	nav.set_blocked(Vector2i(5, 2), false) # a piece of furniture destroyed
	assert_lt(nav.path(from, to).size(), around, "the short way is open")
	nav.set_blocked(Vector2i(5, 2), true)
	assert_eq(nav.path(from, to).size(), around, "and closed again")


func test_an_unreachable_goal_gives_an_empty_path() -> void:
	var blocked: Array[Vector2i] = []
	for y: int in 8: # a full wall: the right half cannot be reached
		blocked.append(Vector2i(5, y))
	var nav: RoomNav = RoomNav.new(Vector2i(12, 8), blocked)
	assert_eq(nav.path(_center(Vector2i(2, 2)), _center(Vector2i(8, 2))).size(), 0)


func test_a_blocked_start_or_goal_falls_back_to_the_nearest_free_cell() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(12, 8), [Vector2i(2, 2), Vector2i(8, 2)])
	var points: PackedVector2Array = nav.path(_center(Vector2i(2, 2)), _center(Vector2i(8, 2)))
	assert_gt(points.size(), 0, "a path anyway")
	assert_false(nav.is_blocked(nav.cell_of(points[0])))
	assert_false(nav.is_blocked(nav.cell_of(points[points.size() - 1])))
	assert_lte(points[0].distance_to(_center(Vector2i(2, 2))), 16.0 * 1.5, "one cell from where it stood")
	assert_eq(nav.nearest_free_cell(Vector2i(2, 2)).distance_squared_to(Vector2i(2, 2)), 1, "an orthogonal neighbor")


func test_a_grid_with_no_free_cell_never_errors() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(2, 1), [Vector2i(0, 0), Vector2i(1, 0)])
	assert_eq(nav.path(Vector2(4, 4), Vector2(20, 4)).size(), 0)


func test_a_line_is_clear_in_the_open_and_blocked_by_a_cell() -> void:
	var nav: RoomNav = _walled()
	assert_true(nav.is_line_clear(_center(Vector2i(1, 7)), _center(Vector2i(10, 7)), 5.0), "below the wall")
	assert_false(nav.is_line_clear(_center(Vector2i(2, 2)), _center(Vector2i(8, 2)), 5.0), "through the wall")


func test_the_half_width_makes_a_line_along_a_wall_blocked() -> void:
	# The wall occupies x from 80 to 96 px. A line at x = 100 px (4 px from its edge) is clear for a point, not for 5 px.
	var nav: RoomNav = _walled()
	assert_true(nav.is_line_clear(Vector2(100, 8), Vector2(100, 90), 0.0))
	assert_false(nav.is_line_clear(Vector2(100, 8), Vector2(100, 90), 5.0))


func test_the_path_budget_is_per_physics_tick() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(4, 4))
	nav.max_paths_per_tick = 3
	var granted: int = 0
	for i: int in 10:
		if nav.take_path_slot():
			granted += 1
	assert_eq(granted, 3, "no more than the budget in one tick")


func test_path_requests_count_the_calls() -> void:
	var nav: RoomNav = RoomNav.new(Vector2i(4, 4))
	nav.path(Vector2(8, 8), Vector2(40, 40))
	nav.path(Vector2(8, 8), Vector2(40, 40))
	assert_eq(nav.path_requests, 2)
