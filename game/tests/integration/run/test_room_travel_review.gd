extends GutTest
## Edge cases of the room trips found by the code review of story 4.8: the fade, the end of the run, a restart in
## the middle of a trip, the pause, the Glide through a door, the fallback to the arena, the F1 keys, the telemetry.

const SEED: int = 20260524
const MAX_TICKS: int = 40
const ROOM_A: String = "res://rooms/pool/onset/onset_combat_002.tscn"
const ROOM_C: String = "res://rooms/pool/onset/onset_combat_003.tscn"

var _harness: RoomHarness
var _run: Run
var _player: Player


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start_floor(SEED)
	_run = _harness.run
	_player = _harness.player


func after_each() -> void:
	GameClock.paused = false
	Input.action_release(&"move_right")
	Input.action_release(&"dash")
	if is_instance_valid(_harness):
		_harness.release()


func _side_to_combat() -> int:
	var layout: FloorLayout = _run.floor_layout
	for side: int in layout.door_sides(layout.start):
		var cell: Vector2i = layout.start + FloorLayout.SIDE_STEPS[side]
		if layout.cells[cell].room_type == Room.RoomType.COMBAT:
			return side
	return -1


func _door_of(room: Room, side: int) -> Door:
	for door: Door in room.doors():
		if door.side == side:
			return door
	return null


func test_the_room_left_stops_during_the_fade() -> void:
	var transition: Transition = Transition.new()
	add_child_autofree(transition)
	var start_room: Room = _run.current_room()
	_run.travel(_side_to_combat())
	assert_eq(start_room.process_mode, Node.PROCESS_MODE_DISABLED, "its bullets cannot reach the frozen player")
	assert_true(await _harness.until(func() -> bool: return not _run.is_traveling(), MAX_TICKS))
	assert_eq(_run.current_room().process_mode, Node.PROCESS_MODE_INHERIT, "the new room runs")


func test_a_trip_after_the_end_of_the_run_is_ignored() -> void:
	var start_room: Room = _run.current_room()
	_run._on_player_died()
	_run.travel(_side_to_combat())
	assert_eq(_run.current_room(), start_room, "the room does not change under the awakening screen")
	assert_false(_run.is_traveling())
	assert_ne(_player.process_mode, Node.PROCESS_MODE_DISABLED)


func test_a_restart_at_the_black_frame_drops_the_trip_without_error() -> void:
	var transition: Transition = Transition.new()
	add_child_autofree(transition)
	_run.travel(_side_to_combat())
	assert_true(await _harness.until(func() -> bool: return transition.is_black(), MAX_TICKS))
	_harness.release() # the run leaves the tree, as Main does on a restart
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_false(transition.is_playing(), "the fade is cancelled")
	assert_false((transition.get_node("Veil") as ColorRect).visible)


func test_cancel_forgets_the_callables() -> void:
	var transition: Transition = Transition.new()
	add_child_autofree(transition)
	var calls: Array[int] = [0]
	transition.play(func() -> void: calls[0] += 1, func() -> void: calls[0] += 1)
	transition.cancel()
	assert_false(transition.is_playing())
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(calls[0], 0)
	var again: Array[int] = [0]
	transition.play(func() -> void: again[0] += 1, func() -> void: again[0] += 1)
	assert_true(transition.is_playing(), "a new fade can start at once")


func test_the_veil_is_hidden_while_the_game_is_paused() -> void:
	var transition: Transition = Transition.new()
	add_child_autofree(transition)
	transition.play(func() -> void: pass, func() -> void: pass)
	var veil: ColorRect = transition.get_node("Veil") as ColorRect
	await get_tree().physics_frame
	assert_true(veil.visible)
	GameClock.paused = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_false(veil.visible, "no veil over the pause menu")
	GameClock.paused = false
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(veil.visible, "back with the game")


func test_the_exit_zone_reaches_beyond_a_glide_through_an_open_door() -> void:
	var side: int = _side_to_combat()
	var room: Room = _run.current_room()
	var door: Door = _door_of(room, side)
	var outward: Vector2 = Vector2(FloorLayout.SIDE_STEPS[side])
	var glide_end: Vector2 = door.global_position + outward * Tuning.GLIDE.max_distance * Const.TILE_SIZE
	var zone: Area2D = door.get_node("ExitZone") as Area2D
	var shape_node: CollisionShape2D = zone.get_child(0) as CollisionShape2D
	var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
	var local: Vector2 = zone.to_local(glide_end) - shape_node.position
	assert_lt(absf(local.x), rect.size.x / 2.0, "the landing point is inside the zone (x)")
	assert_lt(absf(local.y), rect.size.y / 2.0, "the landing point is inside the zone (y)")


func test_landing_far_outside_an_open_door_still_takes_it() -> void:
	var side: int = _side_to_combat()
	var room: Room = _run.current_room()
	var door: Door = _door_of(room, side)
	var start_cell: Vector2i = _run.current_cell()
	var outward: Vector2 = Vector2(FloorLayout.SIDE_STEPS[side])
	_player.global_position = door.global_position + outward * (Tuning.GLIDE.max_distance * Const.TILE_SIZE)
	assert_true(await _harness.until(func() -> bool: return _run.current_cell() != start_cell, MAX_TICKS), "the trip happens")


func test_the_arena_fallback_cleans_the_loader_the_dash_and_the_layout() -> void:
	Input.action_press(&"move_right")
	await _harness.ticks(1)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_right")
	assert_true(_player.is_dashing())
	assert_not_null(_run.room_loader())
	_run._fall_back_to_arena("check")
	assert_push_error("check: playing the arena")
	assert_null(_run.room_loader(), "no loader, no pending request")
	assert_null(_run.floor_layout)
	assert_false(_player.is_dashing())
	assert_true(_run.current_room() is Arena)
	assert_null(_run.floor_map.layout, "the map shows nothing over the arena")


func test_a_loader_load_waits_for_the_pending_requests_first() -> void:
	var loader: RoomLoader = RoomLoader.new()
	loader.request_all(PackedStringArray([ROOM_A]))
	assert_not_null(loader.scene_for(ROOM_C), "never requested: loaded on the spot")
	assert_eq(loader.pending_count(), 0, "after the pending requests were collected")
	assert_true(loader.is_ready(ROOM_A))
	assert_not_null(loader.scene_for(ROOM_A))


func test_the_debug_arena_key_is_not_a_movement_key() -> void:
	var panel: DebugPanel = (load("res://debug/debug_panel.tscn") as PackedScene).instantiate() as DebugPanel
	add_child_autofree(panel)
	panel.visible = true
	var requests: Array[int] = []
	var on_request: Callable = func(mode: int, _a: int, _b: bool, _c: String) -> void: requests.append(mode)
	Events.run_requested.connect(on_request)
	for code: Key in [KEY_A, KEY_B]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.pressed = true
		panel._unhandled_input(event)
	Events.run_requested.disconnect(on_request)
	assert_eq(requests, [RunOptions.Mode.ARENA as int], "only B restarts in the arena")


func test_the_telemetry_records_the_rooms_entered() -> void:
	var before: int = Telemetry._session.events.size()
	Events.room_entered.emit(&"onset_combat_002", 3, 4)
	var event: Dictionary = Telemetry._session.events.back()
	assert_eq(Telemetry._session.events.size(), before + 1)
	var type: String = event["type"]
	var room_id: String = event["room_id"]
	var cell: Array = event["cell"]
	assert_eq(type, "room_entered")
	assert_eq(room_id, "onset_combat_002")
	assert_eq(cell, [3, 4])
