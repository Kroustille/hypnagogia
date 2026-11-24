extends GutTest
## The unlocks of a profile (story 6.7). RoomCatalog.pool and requires_unlock are covered by test_room_catalog.

func test_unlocks_of_a_profile_are_a_copy() -> void:
	var profile: Profile = Profile.new()
	profile.unlocks.append(&"x")
	var ids: Array[StringName] = Unlocks.ids_of(profile)
	ids.append(&"y")
	assert_eq(profile.unlocks, [&"x"] as Array[StringName])
	assert_true(Unlocks.is_unlocked(profile, &"x"))
	assert_false(Unlocks.is_unlocked(profile, &"y"))
	assert_true(Unlocks.ids_of(null).is_empty())
