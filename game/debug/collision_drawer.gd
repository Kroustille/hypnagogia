class_name CollisionDrawer
extends Node2D
## F2 debug overlay: outlines every CollisionShape2D of the Const.GROUP_DEBUG_SHAPES group.
## Instantiated by Main in debug builds only. Knows no game class: hitboxes and hurtboxes just join the group.
## Technical debug drawing: it intentionally bypasses tr() and uses hard-coded colors.
## This exemption only applies to debug/.

const OUTLINE_COLOR: Color = Color(1.0, 0.2, 0.2)
const CIRCLE_SEGMENTS: int = 16


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_collisions"):
		visible = not visible
		queue_redraw()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	# The canvas transform maps world to screen. Node2D has no get_global_transform_interpolated() in 4.7.2:
	# the outline follows the physics position, so it can lead the interpolated sprite by under one tick.
	var canvas: Transform2D = get_viewport().get_canvas_transform()
	for node: Node in get_tree().get_nodes_in_group(Const.GROUP_DEBUG_SHAPES):
		var shape_node: CollisionShape2D = node as CollisionShape2D
		if shape_node == null or shape_node.shape == null or not shape_node.is_inside_tree():
			continue
		var to_screen: Transform2D = canvas * shape_node.global_transform
		var rectangle: RectangleShape2D = shape_node.shape as RectangleShape2D
		if rectangle != null:
			_draw_rectangle(rectangle, to_screen)
			continue
		var circle: CircleShape2D = shape_node.shape as CircleShape2D
		if circle != null:
			_draw_circle_outline(circle, to_screen)


func _draw_rectangle(rectangle: RectangleShape2D, to_screen: Transform2D) -> void:
	var half: Vector2 = rectangle.size / 2.0
	var corners: PackedVector2Array = PackedVector2Array([
		to_screen * Vector2(-half.x, -half.y),
		to_screen * Vector2(half.x, -half.y),
		to_screen * Vector2(half.x, half.y),
		to_screen * Vector2(-half.x, half.y),
	])
	corners.append(corners[0])
	draw_polyline(corners, OUTLINE_COLOR, 1.0)


func _draw_circle_outline(circle: CircleShape2D, to_screen: Transform2D) -> void:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in CIRCLE_SEGMENTS + 1:
		var angle: float = TAU * i / CIRCLE_SEGMENTS
		points.append(to_screen * (Vector2.from_angle(angle) * circle.radius))
	draw_polyline(points, OUTLINE_COLOR, 1.0)
