class_name Unlocks
extends RefCounted
## What the profile has unlocked (story 6.7). Nothing at the MVP: the list stays empty until the act 1 unlocks.
## Feeds RoomCatalog.pool (requires_unlock) through RunOptions.unlocks.


static func is_unlocked(profile: Profile, id: StringName) -> bool:
	return profile != null and profile.unlocks.has(id)


## A copy of the unlocked ids, for a run.
static func ids_of(profile: Profile) -> Array[StringName]:
	var ids: Array[StringName] = []
	if profile != null:
		ids.assign(profile.unlocks)
	return ids
