class_name Const
## Project-wide constants. No gameplay balancing values here (those live in Tuning resources).

const TILE_SIZE: int = 16
const VIEWPORT: Vector2i = Vector2i(640, 360)

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
