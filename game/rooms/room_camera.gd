class_name RoomCamera
extends RefCounted
## Where the camera of a room stands (story 4.6). Pure: no node is read. A room that fits the screen gets a fixed,
## centered camera; a larger room follows the player on its long axis and never shows anything outside the frame
## (walls included), except the strip of the frame's top that the HUD band covers.


## Camera center in room pixels. player_pos: the player in room coordinates; frame_px: the wall frame; viewport: the
## screen in pixels; band_px: height of the HUD band (the view may reach that far above the frame). Whole pixels.
static func target(player_pos: Vector2, frame_px: Vector2, viewport: Vector2, band_px: float) -> Vector2:
	return Vector2(
		_axis(player_pos.x, 0.0, frame_px.x, viewport.x),
		_axis(player_pos.y, band_px, frame_px.y, viewport.y))


## One axis: the view [c - view / 2, c + view / 2] stays within [-lead, frame]. When it cannot (the frame, plus the
## lead, is shorter than the view) the camera sits in the middle of the allowed interval, whatever the player does.
static func _axis(player: float, lead: float, frame: float, view: float) -> int:
	var low: float = view / 2.0 - lead
	var high: float = frame - view / 2.0
	if low >= high:
		return roundi((low + high) / 2.0)
	return roundi(clampf(player, low, high))
