class_name ScaleTestPattern
extends Node2D
## Debug-only sharpness test pattern (story 1.1): 1 px frame, 16 px grid, 1 px checkerboard.
## Any interpolation shows up at once as blurry lines or a gray checkerboard.
## Replaced by the arena in story 1.3. Hard-coded colors are fine here (debug tool).

const FRAME_COLOR: Color = Color(1.0, 1.0, 1.0)
const GRID_COLOR: Color = Color(0.25, 0.25, 0.4)
const CHECKER_COLOR: Color = Color(1.0, 1.0, 1.0)
const BACKGROUND_COLOR: Color = Color(0.05, 0.05, 0.1)
const CHECKER_SIZE: int = 32


func _draw() -> void:
	var w: int = Const.VIEWPORT.x
	var h: int = Const.VIEWPORT.y
	draw_rect(Rect2(0, 0, w, h), BACKGROUND_COLOR)

	for x: int in range(Const.TILE_SIZE, w, Const.TILE_SIZE):
		draw_rect(Rect2(x, 0, 1, h), GRID_COLOR)
	for y: int in range(Const.TILE_SIZE, h, Const.TILE_SIZE):
		draw_rect(Rect2(0, y, w, 1), GRID_COLOR)

	for cy: int in CHECKER_SIZE:
		for cx: int in CHECKER_SIZE:
			if (cx + cy) % 2 == 0:
				draw_rect(Rect2(8 + cx, 8 + cy, 1, 1), CHECKER_COLOR)

	draw_rect(Rect2(0, 0, w, 1), FRAME_COLOR)
	draw_rect(Rect2(0, h - 1, w, 1), FRAME_COLOR)
	draw_rect(Rect2(0, 0, 1, h), FRAME_COLOR)
	draw_rect(Rect2(w - 1, 0, 1, h), FRAME_COLOR)
