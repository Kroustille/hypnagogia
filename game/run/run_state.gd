class_name RunState
extends RefCounted
## What a run is about, apart from its nodes (story 4.7): the seed, whether the player chose it, the floor being played.
## Carried by the Run; the generator and the menus read it. Only the Run writes it (the shards, since story 5.4).

## The seed of the run (40 bits, see RunRng).
var run_seed: int = 0
## True when the seed was given (shared code, F1 panel) instead of drawn: such a run does not count for progression.
var seeded: bool = false
## Index of the floor being played; only the first floor exists for now.
var floor_index: int = 0
## Shards held (story 5.4): never negative. Run keeps the bus (Events.shards_changed) in step with it.
var shards: int = 0
## The time of the wake-up (story 6.6), in minutes from the evening midnight (see WakeClock); -1 until the run ends.
var wake_minute: int = -1


func add_shards(amount: int) -> void:
	if amount > 0:
		shards += amount


## Pays this many shards. False, and nothing changes, when there are not enough (or the amount is negative).
func spend_shards(amount: int) -> bool:
	if amount < 0 or amount > shards:
		return false
	shards -= amount
	return true
