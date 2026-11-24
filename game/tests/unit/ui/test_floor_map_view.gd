extends GutTest
## The geometry of the map (story 4.9, AC 5): cells fit the free area and never overlap, whatever the floor's extent.

const AREA: Rect2 = FloorMapView.AREA


func _check_shape(bounds: Rect2i) -> void:
	var rects: Array[Rect2] = []
	for y: int in range(bounds.position.y, bounds.end.y):
		for x: int in range(bounds.position.x, bounds.end.x):
			rects.append(FloorMapView.cell_rect(Vector2i(x, y), bounds, AREA))
	for rect: Rect2 in rects:
		assert_true(AREA.encloses(rect), "%s inside %s for %s" % [rect, AREA, bounds])
		assert_eq(rect.position, rect.position.round(), "integer coordinates")
		assert_gt(rect.size.x, 0.0)
	for i: int in rects.size():
		for j: int in range(i + 1, rects.size()):
			assert_false(rects[i].intersects(rects[j]), "no overlap %s %s" % [rects[i], rects[j]])


func test_a_wide_floor_fits() -> void:
	_check_shape(Rect2i(-2, 0, 14, 3))


func test_a_tall_floor_fits() -> void:
	_check_shape(Rect2i(0, -3, 3, 12))


func test_a_square_floor_fits() -> void:
	_check_shape(Rect2i(0, 0, 6, 6))


func test_a_single_cell_is_capped() -> void:
	var rect: Rect2 = FloorMapView.cell_rect(Vector2i.ZERO, Rect2i(0, 0, 1, 1), AREA)
	assert_lte(rect.size.x, float(FloorMapView.MAX_PITCH))
	assert_true(AREA.encloses(rect))

func test_the_backdrop_starts_below_the_hud_band() -> void:
	var rect: Rect2 = FloorMapView.backdrop_rect(Vector2(Const.VIEWPORT))
	assert_eq(rect.position.y, float(Const.HUD_BAND_HEIGHT))
	assert_eq(rect.end, Vector2(Const.VIEWPORT))
