class_name ShotPattern
extends RefCounted
## The directions of one shot (story 5.10), shared by the player and the Reflection of the Mirror: pure, no node. Only the
## number and the directions are part of the pattern; piercing, speed and damage stay with the bullet parameters of each
## shooter (a hostile bullet never pierces).


## The directions of a shot aimed along aim (unit vector): the front one first, then the rear one when the stats give
## REAR_SHOT. A zero aim gives no direction.
static func directions(aim: Vector2, stats: StatBlock) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if aim.length_squared() < 1e-6:
		return found
	found.append(aim)
	if stats != null and stats.value_of(StatBlock.Stat.REAR_SHOT) > 0.0:
		found.append(-aim)
	return found
