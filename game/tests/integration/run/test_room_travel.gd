extends GutTest
## Walking from room to room (story 4.8): the door sends the player to the neighbour, one room at a time, the old
## room is released, a won fight stays won, nothing leaks over many trips.

const SEED: int = 20260524
const TRIP_COUNT: int = 10
const MAX_TICKS: int = 30

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
	Input.action_release(&"move_right")
	_harness.release()


## The side of the start room that leads to a combat room (the generator links the start to at least one).
func _side_to_combat() -> int:
	var layout: FloorLayout = _run.floor_layout
	for side: int in layout.door_sides(layout.start):
		var cell: Vector2i = layout.start + FloorLayout.SIDE_STEPS[side]
		if layout.cells[cell].room_type == Room.RoomType.COMBAT:
			return side
	return -1


func _room_count() -> int:
	return _run.get_node("RoomSlot").get_child_count()


func test_the_floor_run_starts_in_the_start_room_alone() -> void:
	var layout: FloorLayout = _run.floor_layout
	assert_true(layout.valid)
	assert_eq(_run.current_cell(), layout.start)
	assert_eq(_run.current_room().room_type, Room.RoomType.START)
	assert_eq(_room_count(), 1)
	assert_eq(get_tree().get_nodes_in_group(Const.GROUP_ROOM).size(), 1)
	assert_true(_run.floor_map.is_visited(layout.start))
	assert_true(_run.floor_map.is_cleared(layout.start), "a start room holds no fight")
	assert_eq(_run.current_room().alive_enemy_count(), 0)


func test_the_doors_without_neighbour_are_sealed_and_the_others_open() -> void:
	var layout: FloorLayout = _run.floor_layout
	var linked: Array[int] = layout.door_sides(layout.start)
	for door: Door in _run.current_room().doors():
		if linked.has(door.side):
			assert_eq(door.state, Door.State.OPEN, "door %d leads somewhere" % door.side)
		else:
			assert_eq(door.state, Door.State.SEALED, "door %d opens on nothing" % door.side)


func test_walking_into_an_open_door_enters_the_neighbour_by_the_opposite_door() -> void:
	var side: int = _side_to_combat()
	assert_ne(side, -1, "the start room touches a combat room")
	var start_room: Room = _run.current_room()
	var door: Door = _door_of(start_room, side)
	_player.global_position = start_room.to_global(door.position) # in the doorway
	var start_cell: Vector2i = _run.current_cell()
	assert_true(await _harness.until(func() -> bool: return _run.current_cell() != start_cell, MAX_TICKS), "the trip happens")
	var neighbor: Vector2i = _run.floor_layout.start + FloorLayout.SIDE_STEPS[side]
	var entered: Room = _run.current_room()
	assert_eq(_run.current_cell(), neighbor)
	assert_eq(_room_count(), 1, "one room in the slot")
	assert_eq(get_tree().get_nodes_in_group(Const.GROUP_ROOM).size(), 1, "one room in the group")
	var opposite: int = (side + 2) % 4
	assert_eq(_player.global_position, entered.entry_position(opposite as Door.Side), "inside the opposite door")
	assert_eq(_run.floor_map.current, neighbor)
	assert_false(is_instance_valid(start_room), "the room left is freed")
	assert_false(_run.is_traveling())
	assert_eq(_player.process_mode, Node.PROCESS_MODE_INHERIT)


func test_a_fight_room_closes_its_doors_and_a_won_one_stays_open_and_empty() -> void:
	var side: int = _side_to_combat()
	_run.travel(side)
	var fight: Room = _run.current_room()
	var fight_cell: Vector2i = _run.current_cell()
	assert_true(fight.has_fight())
	for door: Door in fight.doors():
		assert_ne(door.state, Door.State.OPEN, "closed on entry: no way back")
	assert_false(_run.floor_map.is_cleared(fight_cell))
	# Win it: the runner ends the room and announces it on the bus.
	fight.end_room()
	Events.room_cleared.emit(fight, 0)
	assert_true(_run.floor_map.is_cleared(fight_cell))
	for door: Door in fight.doors():
		assert_ne(door.state, Door.State.CLOSED)
	_run.travel(((side + 2) % 4)) # back to the start room
	assert_eq(_run.current_cell(), _run.floor_layout.start)
	_run.travel(side) # and again
	var again: Room = _run.current_room()
	assert_eq(_run.current_cell(), fight_cell)
	assert_ne(again, fight, "a new instance")
	assert_false(again.has_fight(), "no fight again")
	assert_eq(again.alive_enemy_count(), 0)
	assert_true(again.is_cleared())
	for door: Door in again.doors():
		assert_ne(door.state, Door.State.CLOSED, "open from the start")
	var cleared_events: Array[int] = [0]
	Events.room_cleared.connect(func(_room: Node, _tier: int) -> void: cleared_events[0] += 1)
	await _harness.ticks(90) # past the first wave delay
	assert_eq(again.alive_enemy_count(), 0, "nobody appears")
	assert_eq(cleared_events[0], 0, "no new room_cleared")


func test_ten_round_trips_leak_neither_nodes_nor_connections() -> void:
	var side: int = _side_to_combat()
	var back: int = (side + 2) % 4
	_run.travel(side)
	_run.travel(back)
	await _harness.ticks(3) # the first rooms freed
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var awakening: int = _player.awakening_used.get_connections().size()
	var glided: int = _player.glided.get_connections().size()
	var danger: int = _player.lucidity.room_danger_raised.get_connections().size()
	var exiting: int = _player.hurtbox.tree_exiting.get_connections().size()
	var cleared: int = Events.room_cleared.get_connections().size()
	var run_ended: int = Events.run_ended.get_connections().size()
	for i: int in TRIP_COUNT:
		_run.travel(side)
		_run.travel(back)
		await _harness.ticks(2)
	assert_eq(_room_count(), 1)
	assert_eq(get_tree().get_nodes_in_group(Const.GROUP_ROOM).size(), 1)
	assert_eq(int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), nodes, "no node left behind")
	assert_eq(_player.awakening_used.get_connections().size(), awakening)
	assert_eq(_player.glided.get_connections().size(), glided)
	assert_eq(_player.lucidity.room_danger_raised.get_connections().size(), danger)
	assert_eq(_player.hurtbox.tree_exiting.get_connections().size(), exiting, "the hurtbox is registered once")
	assert_eq(Events.room_cleared.get_connections().size(), cleared)
	assert_eq(Events.run_ended.get_connections().size(), run_ended)
	assert_eq(get_tree().get_nodes_in_group(Const.GROUP_BULLET_MANAGERS).size(), 2, "the managers of the room in play only")


func test_the_player_is_equipped_by_the_room_it_is_in() -> void:
	var side: int = _side_to_combat()
	_run.travel(side)
	var room: Room = _run.current_room()
	assert_same(_player._bullets, room.player_bullets())
	assert_true(room.enemy_bullets().has_hurtbox(_player.hurtbox))
	assert_same(_player._room, room)


func test_the_room_tier_starts_again_with_each_room() -> void:
	_player.lucidity.set_value(0)
	assert_eq(_player.lucidity.room_tier, Lucidity.Tier.TOTAL_ABANDON)
	_player.lucidity.set_value(Tuning.LUCIDITY.max_value)
	assert_eq(_player.lucidity.room_tier, Lucidity.Tier.TOTAL_ABANDON, "the tier of the last fight stays until a new room")
	_run.travel(_side_to_combat())
	assert_eq(_player.lucidity.room_tier, _player.lucidity.live_tier)


func test_the_player_enters_facing_the_inside_and_without_a_dash_in_flight() -> void:
	var side: int = _side_to_combat()
	Input.action_press(&"move_right")
	await _harness.ticks(1)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	Input.action_release(&"move_right")
	assert_true(_player.is_dashing())
	_run.travel(side)
	assert_false(_player.is_dashing())
	assert_eq(_player.velocity, Vector2.ZERO)


func test_the_trip_goes_through_the_fade_and_freezes_the_player() -> void:
	var transition: Transition = Transition.new()
	add_child_autofree(transition)
	var side: int = _side_to_combat()
	var start_room: Room = _run.current_room()
	_run.travel(side)
	assert_true(_run.is_traveling())
	assert_eq(_player.process_mode, Node.PROCESS_MODE_DISABLED, "no move, no hit during the fade")
	assert_eq(_run.current_room(), start_room, "still the old room before the black")
	assert_true(await _harness.until(func() -> bool: return transition.is_black(), MAX_TICKS), "the screen goes black")
	assert_ne(_run.current_room(), start_room, "the swap happens under the black")
	assert_true(await _harness.until(func() -> bool: return not _run.is_traveling(), MAX_TICKS), "and comes back")
	assert_eq(_player.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_false(transition.is_playing())


func test_a_door_never_closes_on_the_player() -> void:
	_harness.release()
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start("res://rooms/pool/onset/onset_combat_003.tscn")
	var room: Room = _harness.room
	room.end_room()
	var door: Door = _door_of(room, Door.Side.N)
	assert_eq(door.state, Door.State.OPEN)
	_harness.player.global_position = room.to_global(door.position) # standing in the doorway
	room.begin_room()
	assert_eq(door.state, Door.State.CLOSED)
	assert_eq(_harness.player.global_position, room.entry_position(Door.Side.N), "put back inside the room")
	assert_true(_harness.door_is_wall(door))


func test_a_run_that_ends_in_a_later_room_frees_everything() -> void:
	_run.travel(_side_to_combat())
	var ended: Array[int] = [0]
	Events.run_ended.connect(func(_outcome: int) -> void: ended[0] += 1)
	_player.health.set_forced_invulnerability(false)
	var info: DamageInfo = DamageInfo.new()
	info.amount = 99.0
	info.source = DamageInfo.Source.DEBUG
	_player.hurtbox.receive(info)
	assert_eq(ended[0], 1, "run_ended works in any room")


func _door_of(room: Room, side: int) -> Door:
	for door: Door in room.doors():
		if door.side == side:
			return door
	return null
