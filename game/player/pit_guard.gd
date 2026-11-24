class_name PitGuard
extends RefCounted
## Pure pit logic of the player (story 4.3): remembers the last safe position and decides when to fall.
## No node: the Player feeds it the cell tests of the room.

## Center of the last safe cell seen, or the position given at the first observe(). ZERO until then.
var last_safe: Vector2 = Vector2.ZERO
var _has_safe: bool = false


## Remembers the position when it is safe (floor and no pit under it).
func observe(position: Vector2, is_safe: bool) -> void:
	if is_safe:
		last_safe = position
		_has_safe = true


## True once a safe position is known.
func has_safe() -> bool:
	return _has_safe


## True when the body center is in a pit and a safe position is known to return to.
func should_fall(_position: Vector2, is_pit: bool) -> bool:
	return is_pit and _has_safe
