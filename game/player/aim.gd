class_name Aim
extends RefCounted
## Pure aim logic of the player: no node, no scene. One update() per physics tick.
## Provisional source switch until story 1.7 (device switching): the right stick takes over as soon as it
## leaves the dead zone, the mouse takes it back as soon as it moves. A still mouse never overrides the stick.

enum Source { MOUSE, STICK }

## Below this squared distance (px²) the cursor is on the player: the aim is kept.
const MIN_CURSOR_DISTANCE_SQ: float = 0.01

## Unit vector, never zero: the last valid aim.
var direction: Vector2 = Vector2.RIGHT
var source: Source = Source.MOUSE

var _stick_active: bool = false


## origin and mouse_world in world coordinates. stick comes from Input.get_vector(), dead zone applied.
func update(origin: Vector2, mouse_world: Vector2, mouse_moved: bool, stick: Vector2) -> void:
	if stick != Vector2.ZERO:
		source = Source.STICK
		direction = stick.normalized()
		_stick_active = true
		return
	_stick_active = false
	if mouse_moved:
		source = Source.MOUSE
	if source == Source.MOUSE:
		# Follows the cursor even when the mouse is still: the player moves, the cursor stays in the world.
		var to_cursor: Vector2 = mouse_world - origin
		if to_cursor.length_squared() > MIN_CURSOR_DISTANCE_SQ:
			direction = to_cursor.normalized()
	# STICK released: direction is kept (RT fires along the last aim).


## The stick was beyond the dead zone on the last update(): it fires on its own.
func is_stick_active() -> bool:
	return _stick_active
