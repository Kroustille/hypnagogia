class_name LucidityGauge
extends Control
## The lucidity gauge of the HUD (story 3.1), drawn in code over the framed place HudSlot reserves (placeholder
## look until epic 7). Display only: the HUD gives it the value and the tier, it never reads the game.
## Tier limits come from Tuning.LUCIDITY (read-only).

## Fill color of each tier, in the order of Lucidity.Tier: cold and bright when lucid, dark red in abandon.
const TIER_COLORS: Array[Color] = [
	Color(0.55, 0.85, 1.0),
	Color(0.55, 0.7, 0.95),
	Color(0.7, 0.55, 0.9),
	Color(0.9, 0.45, 0.6),
	Color(0.8, 0.2, 0.25),
]
const BACK_COLOR: Color = Color(0.1, 0.08, 0.18)
const LIMIT_COLOR: Color = Color(0.04, 0.035, 0.08)
const FLASH_COLOR: Color = Color(1.0, 1.0, 1.0)
## How long the gauge flashes when the tier changes, in seconds (display only, real time; small surface).
const FLASH_SECONDS: float = 0.3

var _value: int = 0
var _tier: int = 0
var _flash_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


## Sets what to show. Never flashes: the HUD calls flash() on a real tier change.
func set_state(value: int, tier: int) -> void:
	_value = value
	_tier = tier
	queue_redraw()


## Starts the tier-change flash.
func flash() -> void:
	_flash_left = FLASH_SECONDS
	set_process(true)
	queue_redraw()


## Width in pixels of the filled part, inside the 1 px frame, never more than the inner width.
func fill_width() -> int:
	var inner: int = int(size.x) - 2
	return clampi(roundi(float(inner) * _value / Tuning.LUCIDITY.max_value), 0, inner)


## X of each limit line between two tiers, inside the gauge (the floor of a tier minus one is the top of the next).
func limit_positions() -> Array[int]:
	var inner: int = int(size.x) - 2
	var result: Array[int] = []
	for floor_value: int in Tuning.LUCIDITY.tier_floors:
		if floor_value > 1:
			result.append(1 + roundi(float(inner) * (floor_value - 1) / Tuning.LUCIDITY.max_value))
	return result


func fill_color() -> Color:
	return TIER_COLORS[clampi(_tier, 0, TIER_COLORS.size() - 1)]


func is_flashing() -> bool:
	return _flash_left > 0.0


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _flash_left <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var inner_height: int = int(size.y) - 2
	draw_rect(Rect2(1, 1, size.x - 2, inner_height), BACK_COLOR)
	var color: Color = fill_color()
	if _flash_left > 0.0:
		color = color.lerp(FLASH_COLOR, _flash_left / FLASH_SECONDS)
	draw_rect(Rect2(1, 1, fill_width(), inner_height), color)
	for x: int in limit_positions():
		draw_rect(Rect2(x, 1, 1, inner_height), LIMIT_COLOR)
