extends GutTest
## The geometry of the chalk rows (story 6.1): count, gap, spacing, the next gap.

const WIDTH: float = 36.0
const SPACING: float = 0.75
const GAP: float = 5.0
const RADIUS: float = 0.25


func test_a_row_has_the_right_number_of_chalks_and_none_in_the_gap() -> void:
	var chalks: Array[Vector2] = ChalkPatterns.row(WIDTH, SPACING, 18.0, GAP, RADIUS)
	assert_between(chalks.size(), 38, 44, "48 positions minus the gap")
	for chalk: Vector2 in chalks:
		var outside: bool = chalk.x + RADIUS <= 15.5 + 1e-4 or chalk.x - RADIUS >= 20.5 - 1e-4
		assert_true(outside, "chalk at %s is clear of the gap" % chalk.x)


func test_the_gap_is_at_least_as_wide_as_asked() -> void:
	var chalks: Array[Vector2] = ChalkPatterns.row(WIDTH, SPACING, 10.0, GAP, RADIUS)
	var widest: float = 0.0
	for i: int in range(1, chalks.size()):
		widest = maxf(widest, chalks[i].x - chalks[i - 1].x - 2.0 * RADIUS)
	assert_gte(widest, GAP - 1e-4)


func test_no_passage_outside_the_gap() -> void:
	var chalks: Array[Vector2] = ChalkPatterns.row(WIDTH, SPACING, 30.0, GAP, RADIUS)
	var free_limit: float = 2.0 * RADIUS + 0.25 # a passage under the diameter plus a quarter tile does not fit the player
	var gaps_found: int = 0
	for i: int in range(1, chalks.size()):
		var free: float = chalks[i].x - chalks[i - 1].x - 2.0 * RADIUS
		if free > 0.25 + 1e-4:
			gaps_found += 1
	assert_eq(gaps_found, 1, "the only wide passage is the gap")
	assert_lte(SPACING, free_limit, "the spacing of the data")
	assert_gt(chalks[0].x - RADIUS, 0.0, "inside the room")
	assert_lt(chalks[chalks.size() - 1].x + RADIUS, WIDTH)


func test_a_gap_at_the_wall_leaves_chalks_only_on_one_side() -> void:
	var chalks: Array[Vector2] = ChalkPatterns.row(WIDTH, SPACING, GAP / 2.0, GAP, RADIUS)
	assert_gt(chalks[0].x, GAP)


func test_a_row_without_a_valid_width_is_empty() -> void:
	assert_eq(ChalkPatterns.row(0.0, SPACING, 1.0, GAP, RADIUS).size(), 0)
	assert_eq(ChalkPatterns.row(WIDTH, 0.0, 1.0, GAP, RADIUS).size(), 0)
	assert_eq(ChalkPatterns.row(NAN, SPACING, 1.0, GAP, RADIUS).size(), 0)


func test_next_gap_never_moves_more_than_the_shift_nor_leaves_the_room() -> void:
	var rng: RandomNumberGenerator = RunRng.new(42).stream(RunRng.BOSS, 0)
	var gap: float = ChalkPatterns.next_gap(rng.randf(), NAN, WIDTH, GAP, 10.0)
	assert_between(gap, GAP / 2.0, WIDTH - GAP / 2.0)
	for i: int in 500:
		var next: float = ChalkPatterns.next_gap(rng.randf(), gap, WIDTH, GAP, 10.0)
		assert_lte(absf(next - gap), 10.0 + 1e-4)
		assert_gte(next, GAP / 2.0 - 1e-4)
		assert_lte(next, WIDTH - GAP / 2.0 + 1e-4)
		gap = next


func test_the_same_stream_gives_the_same_gaps() -> void:
	var first: Array[float] = _gaps(RunRng.new(7))
	assert_eq(_gaps(RunRng.new(7)), first)
	assert_ne(_gaps(RunRng.new(8)), first)


func test_the_boss_stream_is_not_the_combat_stream() -> void:
	var rng: RunRng = RunRng.new(7)
	assert_ne(rng.stream(RunRng.BOSS, 0).seed, rng.stream(RunRng.COMBAT, 0).seed)
	assert_ne(rng.stream(RunRng.BOSS, 0).seed, rng.stream(RunRng.BOSS, 1).seed, "one per floor")


func _gaps(run_rng: RunRng) -> Array[float]:
	var rng: RandomNumberGenerator = run_rng.stream(RunRng.BOSS, 0)
	var found: Array[float] = []
	var gap: float = NAN
	for i: int in 20:
		gap = ChalkPatterns.next_gap(rng.randf(), gap, WIDTH, GAP, 10.0)
		found.append(gap)
	return found
