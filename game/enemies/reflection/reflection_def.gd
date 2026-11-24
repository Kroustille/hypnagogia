class_name ReflectionDef
extends ShooterDef
## The hostile reflection of the Mirror (story 5.10, FR52), on top of the shooter values. Distances in tiles, speed in
## tiles per second. Everything the playtest may tune lives in reflection.tres: how it moves, how far it stays, how fast
## it walks and how often it fires (fire_interval, from ShooterDef).

## How the reflection moves between two volleys.
enum Movement {
	## It stands where it appeared.
	STILL,
	## It keeps preferred_distance from the player: closer, it walks away, farther, it walks closer.
	KEEP_DISTANCE,
	## It stands at the point opposite the player through the center of the room.
	MIRROR_PLAYER,
}

@export var movement: Movement = Movement.KEEP_DISTANCE
## Distance it keeps from the player for KEEP_DISTANCE (center to center).
@export_range(0.0, 30.0, 0.5, "or_greater") var preferred_distance: float = 0.0
## Base walking speed, before the modifiers of the items it copies (Lead legs: -20 %).
@export_range(0.0, 20.0, 0.1, "or_greater") var move_speed: float = 0.0
