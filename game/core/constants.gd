class_name Const
## Project-wide constants. No gameplay balancing values here (those live in Tuning resources).

const TILE_SIZE: int = 16
const VIEWPORT: Vector2i = Vector2i(640, 360)

## Height in pixels of the HUD band above the room (empty until story 2.7).
const HUD_BAND_HEIGHT: int = 24
## Playable tiles of a one-screen room, walls excluded.
const ROOM_TILES: Vector2i = Vector2i(36, 19)

## Node group of every BulletManager, read by the F3 overlay.
const GROUP_BULLET_MANAGERS: StringName = &"bullet_managers"
## Node group of every CollisionShape2D shown by the F2 debug overlay.
const GROUP_DEBUG_SHAPES: StringName = &"debug_shapes"

## Integer scale factor the engine applies to a window of this size (0 when the window is smaller than the viewport, e.g. minimized).
@warning_ignore("integer_division")
static func integer_scale(window_size: Vector2i) -> int:
	return mini(window_size.x / VIEWPORT.x, window_size.y / VIEWPORT.y)


## Physics layer bitmasks. Must stay aligned with [layer_names] in project.godot.
const LAYER_WALLS: int = 1 << 0
const LAYER_HIGH_OBSTACLES: int = 1 << 1
const LAYER_LOW_OBSTACLES: int = 1 << 2
const LAYER_FURNITURE: int = 1 << 3
const LAYER_PLAYER: int = 1 << 4
const LAYER_ENEMIES: int = 1 << 5
const LAYER_PLAYER_HURTBOX: int = 1 << 6
const LAYER_ENEMY_HURTBOX: int = 1 << 7
const LAYER_PICKUPS: int = 1 << 8
const LAYER_TRIGGERS: int = 1 << 9

## Layer name expected in project settings for each layer number (1-based), used by Main's debug check.
const LAYER_NAMES: Array[String] = [
	"walls",
	"high_obstacles",
	"low_obstacles",
	"furniture",
	"player",
	"enemies",
	"player_hurtbox",
	"enemy_hurtbox",
	"pickups",
	"triggers",
]

## Color reserved for the player's shots (NFR8): no other entity uses it. Final value set by story 7.2.
const COLOR_PLAYER_SHOT: Color = Color(0.55, 0.95, 1.0)

## Node group of the player, found by debug tools without a node path.
const GROUP_PLAYER: StringName = &"player"

## z_index of the decor layers (floor, walls): drawn below the entities whatever their place in the tree.
## The player lives in Run, outside the room (story 2.2); entities, bullets and the HUD stay at 0 or above (AR19).
const Z_INDEX_DECOR: int = -1

## Physics tick priority of every BulletManager: they tick after the entities (priority 0), whatever their place
## in the tree, so hit tests read this tick's state of the hurtboxes (story 2.1).
const PHYSICS_PRIORITY_BULLETS: int = 100

## Physics tick priority of the contact Hitboxes: they tick after the entities (0) and before the BulletManagers
## (100): they read this tick's positions and invulnerabilities (story 2.3).
const PHYSICS_PRIORITY_HITBOXES: int = 50

## Node group of the active room, one at a time (D14): found by debug tools without a node path.
const GROUP_ROOM: StringName = &"room"
