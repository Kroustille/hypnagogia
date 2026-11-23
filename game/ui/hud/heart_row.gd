class_name HeartRow
extends Control
## Hearts and armor of the HUD, drawn in code from a pixel mask (placeholder look until epic 7). Display only:
## the HUD gives it the numbers, it never reads the game. Counted in half-hearts like Health: a heart container is
## 2 half-hearts, an armor point is one blue half-heart (two make a whole blue heart).

const HEART_MASK: PackedStringArray = [
	".##..##.",
	"########",
	"########",
	"########",
	".######.",
	"..####..",
	"...##...",
]
const ICON_SIZE: Vector2i = Vector2i(8, 7)
const ICON_GAP: int = 1
## Icons never exceed the cap of the GDD (12 hearts, armor included).
const MAX_ICONS: int = 12
const COLOR_HEART: Color = Color(0.9, 0.2, 0.25)
const COLOR_ARMOR: Color = Color(0.35, 0.55, 1.0)
const COLOR_EMPTY: Color = Color(0.2, 0.15, 0.25)
const COLOR_FLASH: Color = Color(1.0, 1.0, 1.0)
## How long the row flashes after a hit, in seconds (display only, real time).
const FLASH_SECONDS: float = 0.25

var _half_hearts: int = 0
var _max_half_hearts: int = 0
var _armor: int = 0
var _flash_left: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(MAX_ICONS * (ICON_SIZE.x + ICON_GAP), ICON_SIZE.y)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_state(half_hearts: int, max_half_hearts: int, armor: int) -> void:
	_half_hearts = half_hearts
	_max_half_hearts = max_half_hearts
	_armor = armor
	queue_redraw()


## Hearts, then armor, as (fill, color) per icon: fill 2 = whole, 1 = half, 0 = empty.
func icons() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	@warning_ignore("integer_division")
	var containers: int = (_max_half_hearts + 1) / 2
	for i: int in containers:
		result.append(Vector2i(clampi(_half_hearts - i * 2, 0, 2), 0))
	@warning_ignore("integer_division")
	var armor_icons: int = (_armor + 1) / 2
	for i: int in armor_icons:
		result.append(Vector2i(clampi(_armor - i * 2, 0, 2), 1))
	if result.size() > MAX_ICONS:
		result.resize(MAX_ICONS)
	return result


func is_flashing() -> bool:
	return _flash_left > 0.0


## Bright flash of the whole row: a hit just landed.
func flash() -> void:
	_flash_left = FLASH_SECONDS
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_flash_left = maxf(_flash_left - delta, 0.0)
	if _flash_left <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var x: int = 0
	for icon: Vector2i in icons():
		_draw_icon(x, icon.x, COLOR_ARMOR if icon.y == 1 else COLOR_HEART)
		x += ICON_SIZE.x + ICON_GAP


func _draw_icon(x: int, fill: int, color: Color) -> void:
	@warning_ignore("integer_division")
	var half_width: int = ICON_SIZE.x / 2
	for row: int in HEART_MASK.size():
		var line: String = HEART_MASK[row]
		for col: int in line.length():
			if line[col] != "#":
				continue
			var filled: bool = fill == 2 or (fill == 1 and col < half_width)
			var pixel: Color = color if filled else COLOR_EMPTY
			if is_flashing() and filled:
				pixel = COLOR_FLASH
			draw_rect(Rect2(x + col, row, 1, 1), pixel)
