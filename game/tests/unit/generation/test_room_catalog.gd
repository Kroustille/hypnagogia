extends GutTest
## RoomCatalog (story 4.7, AC 8): the real pool, sorted, cached and filtered by unlock.

const POOL_DIR: String = "res://rooms/pool/onset"


func before_each() -> void:
	RoomCatalog.clear_cache()


func after_each() -> void:
	RoomCatalog.clear_cache() # a test may have changed the cached infos


func test_the_real_pool_has_enough_rooms_of_every_kind() -> void:
	var counts: Dictionary = {}
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		var previous: int = counts.get(info.room_type, 0)
		counts[info.room_type] = previous + 1
	assert_gte(_count(counts, Room.RoomType.COMBAT), 12, "12 combat rooms to fill a floor")
	for room_type: Room.RoomType in [Room.RoomType.START, Room.RoomType.TREASURE, Room.RoomType.SHOP, Room.RoomType.NIGHTMARE]:
		assert_gte(_count(counts, room_type), 1, str(Room.RoomType.find_key(room_type)))


func test_the_pool_is_sorted_by_path() -> void:
	var paths: Array[String] = []
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		paths.append(info.path)
	var sorted: Array[String] = paths.duplicate()
	sorted.sort()
	assert_eq(paths, sorted)
	assert_gt(paths.size(), 0)


func test_the_pool_is_read_once() -> void:
	var first: Array[RoomInfo] = RoomCatalog.pool(POOL_DIR)
	var second: Array[RoomInfo] = RoomCatalog.pool(POOL_DIR)
	assert_same(first[0], second[0], "the RoomInfo are cached")


func test_the_provisional_rooms_are_what_the_floor_expects() -> void:
	var by_id: Dictionary[StringName, RoomInfo] = {}
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		by_id[info.id] = info
	assert_eq(by_id[&"onset_start_001"].room_type, Room.RoomType.START)
	assert_eq(by_id[&"onset_treasure_001"].room_type, Room.RoomType.TREASURE)
	assert_eq(by_id[&"onset_shop_001"].room_type, Room.RoomType.SHOP)
	assert_eq(by_id[&"onset_boss_001"].room_type, Room.RoomType.NIGHTMARE)


func test_a_room_that_requires_an_unlock_is_filtered_out_until_it_is_owned() -> void:
	var infos: Array[RoomInfo] = RoomCatalog.all(POOL_DIR)
	var locked: RoomInfo = infos[0]
	locked.requires_unlock = &"test_unlock"
	var without: Array[RoomInfo] = RoomCatalog.pool(POOL_DIR)
	assert_false(without.has(locked))
	assert_eq(without.size(), infos.size() - 1)
	var unlocks: Array[StringName] = [&"test_unlock"]
	assert_true(RoomCatalog.pool(POOL_DIR, unlocks).has(locked))
	assert_eq(RoomCatalog.pool(POOL_DIR, unlocks).size(), infos.size())


func test_the_real_pool_generates_a_valid_floor() -> void:
	var def: FloorDef = load("res://data/floors/onset.tres") as FloorDef
	for seed_value: int in [1, 2, 3, 4, 5]:
		var layout: FloorLayout = FloorGenerator.generate(def, RoomCatalog.pool(def.pool_dir), RunRng.new(seed_value), 0)
		assert_true(layout.valid, "seed %d: %s" % [seed_value, layout.failure])


func _count(counts: Dictionary, room_type: Room.RoomType) -> int:
	var count: int = counts.get(room_type, 0)
	return count


func test_two_rooms_with_the_same_file_name_are_one_id_and_the_first_in_path_order_wins() -> void:
	var dir: String = "res://tests/fixtures/catalog_dupes"
	var infos: Array[RoomInfo] = RoomCatalog.all(dir)
	var ids: Array[StringName] = []
	for info: RoomInfo in infos:
		ids.append(info.id)
	assert_eq(ids.size(), 2, "twin (once) and other")
	assert_eq(ids.count(&"twin"), 1, "no id twice")
	for info: RoomInfo in infos:
		if info.id == &"twin":
			assert_eq(info.path, dir + "/a/twin.tscn", "the first path in sorted order is kept")
	assert_push_error("room id twin is used by")

