class_name RoomHarness
extends Node
## Test aid (story 4.2): plays a pre-drawn room through a real Run, tick by tick.
## Add it to the test tree first (add_child), then start(); finish with release() in after_each: autofree would free it
## from inside its own `ticked` emission (a locked object). `await ticks(n)` resumes at the end of the n-th next
## physics tick, after the entities (priority 0), the hitboxes (50) and the bullet managers (100), like the scratch
## harness: what a test reads is the final state of that tick.

const RUN_SCENE: PackedScene = preload("res://run/run.tscn")

signal ticked

var run: Run
var room: Room
var player: Player
var tick_count: int = 0


func _init() -> void:
	process_physics_priority = 200


func _physics_process(_delta: float) -> void:
	tick_count += 1
	ticked.emit()


## Starts a Run in ROOM mode on the scene. The player cannot be hit (tests are about the room, not the player's death).
func start(room_path: String) -> void:
	var options: RunOptions = RunOptions.new()
	options.mode = RunOptions.Mode.ROOM
	options.room_path = room_path
	run = RUN_SCENE.instantiate() as Run
	run.setup(options) # before add_child()
	add_child(run)
	room = run.get_node("RoomSlot").get_child(0) as Room # not the group: a room freed this frame may still be in it
	player = run.get_node("Player") as Player
	player.health.set_forced_invulnerability(true)


## Takes the run out of the tree at once (its groups stop counting) and frees it at the end of the frame.
func release() -> void:
	if get_parent() != null:
		get_parent().remove_child(self)
	queue_free()


func ticks(count: int) -> void:
	for i: int in count:
		await ticked


## Waits at most max_ticks ticks for the condition. Returns whether it became true.
func until(condition: Callable, max_ticks: int) -> bool:
	for i: int in max_ticks:
		if condition.call():
			return true
		await ticked
	return condition.call()


## The enemies of the room still alive, in the order of the tree.
func living_enemies() -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in room.get_node("Enemies").get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and not enemy.is_dead() and not enemy.is_queued_for_deletion():
			found.append(enemy)
	return found


## Names of the living enemies, in tree order.
func living_names() -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for enemy: Enemy in living_enemies():
		names.append(String(enemy.name))
	return names


## True when the Walls layer holds a tile on every cell of the door.
func door_is_wall(door: Door) -> bool:
	var walls: TileMapLayer = room.get_node("Walls") as TileMapLayer
	for cell: Vector2i in door.cells():
		if walls.get_cell_source_id(cell) == -1:
			return false
	return true


## True when the Walls layer holds no tile on any cell of the door.
func door_is_open(door: Door) -> bool:
	var walls: TileMapLayer = room.get_node("Walls") as TileMapLayer
	for cell: Vector2i in door.cells():
		if walls.get_cell_source_id(cell) != -1:
			return false
	return true


func door_on(side: Door.Side) -> Door:
	for door: Door in room.doors():
		if door.side == side:
			return door
	return null


## Fires one shot of a bullet manager of the room. Tiles per second; the shot lives long enough to cross the room.
func fire_shot(manager: BulletManager, origin: Vector2, direction: Vector2, speed_tiles: float = 10.0) -> bool:
	var params: BulletParams = BulletParams.new()
	params.speed = speed_tiles
	params.radius = 0.25
	params.lifetime = 10.0
	params.damage = 1.0
	params.appearance = manager.add_appearance(ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
	return manager.fire(params, origin, direction)
