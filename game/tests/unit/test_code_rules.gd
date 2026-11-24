extends GutTest
## Source rules that tests can enforce by reading the code (story 4.7, AC 5): the generation code never touches the
## global random generator, so that a seed alone decides a floor.

const GENERATION_DIR: String = "res://generation"
## Global random calls (a method of a RandomNumberGenerator is written "x.randi_range(" and is allowed), the global
## shuffle/pick helpers of Array, and the seeding of the global generator.
const FORBIDDEN: String = "(^|[^\\w.])(randi|randf|randi_range|randf_range|randfn|randomize|seed|rand_from_seed)\\s*\\(|\\.shuffle\\s*\\(|\\.pick_random\\s*\\("


func _sources(dir: String) -> Array[String]:
	var paths: Array[String] = []
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			paths.append(dir.path_join(file))
	for sub: String in DirAccess.get_directories_at(dir):
		paths.append_array(_sources(dir.path_join(sub)))
	return paths


func test_the_generation_code_has_sources_to_scan() -> void:
	assert_gte(_sources(GENERATION_DIR).size(), 5, "floor_def, floor_layout, floor_generator, room_catalog, room_info")


func test_the_generation_code_never_uses_the_global_rng() -> void:
	var rule: RegEx = RegEx.create_from_string(FORBIDDEN)
	for path: String in _sources(GENERATION_DIR):
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for index: int in lines.size():
			var code: String = lines[index].split("#")[0] # comments may talk about it
			assert_null(rule.search(code), "%s:%d uses the global RNG: %s" % [path, index + 1, code.strip_edges()])


func test_the_rule_catches_what_it_forbids() -> void:
	var rule: RegEx = RegEx.create_from_string(FORBIDDEN)
	for bad: String in ["var x: int = randi()", "randf()", "x = randi_range(0, 3)", "randomize()", "list.shuffle()",
			"list.pick_random()", "seed(4)"]:
		assert_not_null(rule.search(bad), bad)
	for fine: String in ["var x: int = shape.randi_range(0, 3)", "var y: float = shape.randf()", "rng.stream(&\"x\").randi()"]:
		assert_null(rule.search(fine), fine)
