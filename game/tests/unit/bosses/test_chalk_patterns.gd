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


func test_a_four_arm_spiral_has_arms_a_quarter_turn_apart() -> void:
	var arms: Array[Vector2] = ChalkPatterns.spiral_directions(0.0, 4)
	assert_eq(arms.size(), 4)
	assert_almost_eq(arms[0], Vector2.RIGHT, Vector2.ONE * 1e-5)
	assert_almost_eq(arms[1], Vector2.DOWN, Vector2.ONE * 1e-5)
	assert_almost_eq(arms[2], Vector2.LEFT, Vector2.ONE * 1e-5)
	assert_almost_eq(arms[3], Vector2.UP, Vector2.ONE * 1e-5)


func test_an_arm_turns_twelve_degrees_between_two_chalks_at_sixty_degrees_per_second_and_0_2_s() -> void:
	var rotation_deg_per_s: float = 60.0
	var emit_interval: float = 0.2
	var first: Vector2 = ChalkPatterns.spiral_directions(30.0, 4)[0]
	var second: Vector2 = ChalkPatterns.spiral_directions(30.0 + rotation_deg_per_s * emit_interval, 4)[0]
	assert_almost_eq(rad_to_deg(first.angle_to(second)), 12.0, 1e-3)


func test_a_spiral_without_arms_or_a_valid_angle_is_empty() -> void:
	assert_eq(ChalkPatterns.spiral_directions(0.0, 0).size(), 0)
	assert_eq(ChalkPatterns.spiral_directions(NAN, 4).size(), 0)


func test_an_aimed_fan_of_three_over_twenty_degrees_is_centered_on_the_aim() -> void:
	var aim: Vector2 = Vector2(3.0, 4.0)
	var fan: Array[Vector2] = ChalkPatterns.aimed_fan(aim, 3, 20.0)
	assert_eq(fan.size(), 3)
	assert_almost_eq(fan[1], aim.normalized(), Vector2.ONE * 1e-5, "the middle chalk is on the aim")
	assert_almost_eq(rad_to_deg(absf(fan[0].angle_to(fan[2]))), 20.0, 1e-3, "the outer ones are 20 degrees apart")
	assert_almost_eq(rad_to_deg(absf(fan[0].angle_to(fan[1]))), 10.0, 1e-3)
	assert_almost_eq(rad_to_deg(absf(fan[1].angle_to(fan[2]))), 10.0, 1e-3)


func test_a_single_chalk_fan_is_the_aim_and_a_zero_aim_fires_nothing() -> void:
	assert_almost_eq(ChalkPatterns.aimed_fan(Vector2.UP * 5.0, 1, 20.0)[0], Vector2.UP, Vector2.ONE * 1e-5)
	assert_eq(ChalkPatterns.aimed_fan(Vector2.ZERO, 3, 20.0).size(), 0)
	assert_eq(ChalkPatterns.aimed_fan(Vector2(0.0, 1e-4), 3, 20.0).size(), 0)


func test_a_ring_of_twelve_is_thirty_degrees_apart() -> void:
	var ring: Array[Vector2] = ChalkPatterns.ring_directions(12, 0.0)
	assert_eq(ring.size(), 12)
	assert_almost_eq(ring[0], Vector2.RIGHT, Vector2.ONE * 1e-5)
	for i: int in 12:
		assert_almost_eq(rad_to_deg(ring[i].angle_to(ring[(i + 1) % 12])), 30.0, 1e-3)


func test_successive_rings_offset_by_half_a_step_never_coincide_and_repeat_every_two() -> void:
	var first: Array[Vector2] = ChalkPatterns.ring_directions(12, 0.0)
	var second: Array[Vector2] = ChalkPatterns.ring_directions(12, 15.0)
	var third: Array[Vector2] = ChalkPatterns.ring_directions(12, 30.0)
	for chalk: Vector2 in second:
		for other: Vector2 in first:
			assert_gt(rad_to_deg(absf(chalk.angle_to(other))), 14.9, "a chalk of the second ring is in a hole of the first")
	for i: int in 12:
		assert_almost_eq(third[i], first[(i + 1) % 12], Vector2.ONE * 1e-5, "every other circle has the same holes: a fixed pattern")


func test_a_ring_without_chalks_or_with_a_bad_offset_is_empty() -> void:
	assert_eq(ChalkPatterns.ring_directions(0, 0.0).size(), 0)
	assert_eq(ChalkPatterns.ring_directions(12, NAN).size(), 0)
