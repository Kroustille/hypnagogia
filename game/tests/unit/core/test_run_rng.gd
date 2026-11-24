extends GutTest
## RunRng: determinism of the streams and the seed code round trip.

const SAMPLE: int = 8


func _draws(generator: RandomNumberGenerator) -> Array[int]:
	var result: Array[int] = []
	for i: int in SAMPLE:
		result.append(generator.randi())
	return result


func test_same_seed_and_stream_give_the_same_sequence() -> void:
	var first: Array[int] = _draws(RunRng.new(12345).stream(&"combat"))
	var second: Array[int] = _draws(RunRng.new(12345).stream(&"combat"))
	assert_eq(first, second)


func test_stream_is_kept_and_continues() -> void:
	var rng: RunRng = RunRng.new(777)
	assert_same(rng.stream(&"combat"), rng.stream(&"combat"))
	var reference: Array[int] = _draws(RunRng.new(777).stream(&"combat"))
	var continued: RandomNumberGenerator = rng.stream(&"combat")
	var head: int = continued.randi()
	assert_eq(head, reference[0])
	assert_eq(continued.randi(), reference[1], "the next call to stream() does not rewind")
	assert_eq(rng.stream(&"combat").randi(), reference[2])


func test_two_streams_of_one_seed_differ() -> void:
	var rng: RunRng = RunRng.new(12345)
	assert_ne(_draws(rng.stream(&"combat")), _draws(rng.stream(&"cosmetic")))


func test_one_stream_does_not_disturb_another() -> void:
	var alone: RunRng = RunRng.new(99)
	var expected: Array[int] = _draws(alone.stream(&"combat"))
	var mixed: RunRng = RunRng.new(99)
	_draws(mixed.stream(&"cosmetic"))
	assert_eq(_draws(mixed.stream(&"combat")), expected)


func test_floor_index_changes_the_sequence() -> void:
	var rng: RunRng = RunRng.new(12345)
	assert_ne(_draws(rng.stream(&"combat", 0)), _draws(rng.stream(&"combat", 1)))


func test_different_seeds_differ() -> void:
	assert_ne(_draws(RunRng.new(1).stream(&"combat")), _draws(RunRng.new(2).stream(&"combat")))


func test_seed_code_has_eight_characters_from_the_alphabet() -> void:
	for value: int in [0, 1, 31, 32, (1 << RunRng.SEED_BITS) - 1]:
		var code: String = RunRng.new(value).seed_code()
		assert_eq(code.length(), RunRng.CODE_LENGTH, "code of %d" % value)
		for character: String in code:
			assert_true(RunRng.ALPHABET.contains(character), "'%s' is in the alphabet" % character)


func test_seed_code_round_trip_on_many_seeds() -> void:
	var generator: RandomNumberGenerator = RandomNumberGenerator.new()
	generator.seed = 4242
	var seeds: Array[int] = [0, 1, (1 << RunRng.SEED_BITS) - 1]
	for i: int in 60:
		seeds.append(generator.randi() | (generator.randi() << 8)) # mixes high bits in
	for value: int in seeds:
		var masked: int = value & ((1 << RunRng.SEED_BITS) - 1)
		var code: String = RunRng.new(value).seed_code()
		assert_eq(RunRng.code_to_seed(code), masked, "round trip of %s" % code)


func test_code_to_seed_tolerates_case_and_look_alike_letters() -> void:
	assert_eq(RunRng.code_to_seed("abcdefgh"), RunRng.code_to_seed("ABCDEFGH"))
	assert_eq(RunRng.code_to_seed("OOOOOOOO"), 0, "O reads as 0")
	assert_eq(RunRng.code_to_seed("IIIIIIII"), RunRng.code_to_seed("11111111"), "I reads as 1")
	assert_eq(RunRng.code_to_seed("LLLLLLLL"), RunRng.code_to_seed("11111111"), "L reads as 1")


func test_invalid_codes_are_refused() -> void:
	assert_eq(RunRng.code_to_seed(""), -1)
	assert_eq(RunRng.code_to_seed("ABC"), -1, "too short")
	assert_eq(RunRng.code_to_seed("ABCDEFGHJ"), -1, "too long")
	assert_eq(RunRng.code_to_seed("ABCDEFG!"), -1, "foreign character")
	assert_eq(RunRng.code_to_seed("UUUUUUUU"), -1, "U is not in the alphabet")
