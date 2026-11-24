class_name Reticle
extends Node2D
## Aim reticle. Follows the cursor with the mouse, or sits at a fixed distance along the aim with the stick.
## Moved in _process (presentation only: every gameplay decision stays in _physics_process), so physics
## interpolation is off. Hides the system cursor while it is in the tree and shows it again when it leaves.
## While the game is paused (an ancestor disabled), it hides itself and shows the cursor.
## Placeholder drawing until epic 7; stays in the world, drawn below the HUD band (story 2.7).

## Length of each of the 4 branches, in pixels (visual).
const BRANCH_LENGTH: int = 3
## Empty pixels between the center pixel and each branch (visual).
const CENTER_GAP: int = 1
const COLOR: Color = Color(1.0, 1.0, 1.0, 0.85)
## Above the room and the bullets (visual).
const Z_INDEX: int = 100
## Distance from the player with the stick, in tiles. Visual only, not a shot range.
const STICK_RETICLE_DISTANCE: float = 4.0

var _player: Player


## Dependency injection: call before add_child().
func setup(player: Player) -> void:
	_player = player


## On every entry, not only the first (_ready() runs once): a reticle moved to another parent hides it again.
func _enter_tree() -> void:
	if _player != null:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _ready() -> void:
	top_level = true
	process_priority = 1 # after the room camera (0): the canvas transform read in _process is this frame's, not the previous one
	z_index = Z_INDEX
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if _player == null:
		Log.error("ui", "Reticle added without setup()")
		assert(false, "Reticle.setup() must be called before add_child()")
		set_process(false)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DISABLED:
			visible = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		NOTIFICATION_ENABLED:
			visible = true
			if _player != null:
				Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _process(_delta: float) -> void:
	var target: Vector2
	if _player.aim_source() == Aim.Source.STICK:
		target = _player.global_position + _player.aim_direction() * STICK_RETICLE_DISTANCE * Const.TILE_SIZE
	else:
		target = get_global_mouse_position()
	# the whole reticle stays below the HUD band (display only: aim is unchanged)
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	var screen: Vector2 = canvas * target
	screen.y = maxf(screen.y, Const.HUD_BAND_HEIGHT + CENTER_GAP + BRANCH_LENGTH)
	target = canvas.affine_inverse() * screen
	# The center pixel covers [floor, floor + 1): the reticle stays on whole pixels.
	global_position = target.floor()


func _draw() -> void:
	# 1 px wide rectangles around the center pixel (0, 0): crisp at any integer scale.
	var start: int = 1 + CENTER_GAP
	draw_rect(Rect2(start, 0, BRANCH_LENGTH, 1), COLOR)
	draw_rect(Rect2(-start - BRANCH_LENGTH + 1, 0, BRANCH_LENGTH, 1), COLOR)
	draw_rect(Rect2(0, start, 1, BRANCH_LENGTH), COLOR)
	draw_rect(Rect2(0, -start - BRANCH_LENGTH + 1, 1, BRANCH_LENGTH), COLOR)
