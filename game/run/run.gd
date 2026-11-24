class_name Run
extends Node
## One night: the player and the active room (RoomSlot). Destroyed and recreated by Main on restart (AR20).
## Holds the run state (RunState: seed, floor index) and whether the run has ended. Notifies the end of the run on Events.run_ended.
## In FLOOR mode it plays the generated floor (story 4.8): one room at a time in the RoomSlot, the player walks from
## one to the next through the open doors, behind a fade to black.

## How a run ended. Values are explicit because they travel as ints on Events.run_ended:
## new outcomes are appended at the end (VICTORY: story 6.4).
enum Outcome { DEATH = 0 }

## Kept in the resource cache for the whole session: Main preloads run.tscn, which preloads this (AC 3).
const ARENA_SCENE: PackedScene = preload("res://rooms/arena/arena.tscn")
## The controls help of the start room of the first floor (story 4.8).
const TUTORIAL_SCENE: PackedScene = preload("res://ui/tutorial/controls_tutorial.tscn")

## The items a treasure room may offer (story 5.2).
const TREASURE_POOL_PATH: String = "res://data/pools/treasure_pool.tres"
## The items a shop may offer (story 5.5).
const SHOP_POOL_PATH: String = "res://data/pools/shop_pool.tres"
const FLOOR_DEF_PATH: String = "res://data/floors/onset.tres"

## The floor definition played (a variable so that a check can point it at a missing file).
var floor_def_path: String = FLOOR_DEF_PATH
var _ended: bool = false
var _options: RunOptions = RunOptions.new()
## The random streams of this run (D8): a new one for every run.
var rng: RunRng
## The seed, the floor index (story 4.7).
var state: RunState = RunState.new()
## The generated floor (story 4.7): generated in FLOOR mode, or on demand by the F1 map (log_floor_map).
var floor_layout: FloorLayout
## Where the player has been on the floor (story 4.8); read by the map (4.9).
var floor_map: FloorMap = FloorMap.new()
## What lies in the rooms of the floor, by cell (story 5.1): an item left on the ground is there on the next visit.
var stocks: Dictionary[Vector2i, RoomStock] = {}

## The room of the RoomSlot, null while one is being swapped for the next.
var _room: Room
## The cell of the room on the floor.
var _cell: Vector2i = Vector2i.ZERO
var _loader: RoomLoader
## True from the moment a door was taken until the player controls the new room.
var _traveling: bool = false

@onready var _player: Player = %Player
@onready var _room_slot: Node = %RoomSlot


## Dependency injection: call before add_child(). Without it the run plays the arena.
func setup(options: RunOptions) -> void:
	_options = options


func _ready() -> void:
	add_to_group(Const.GROUP_RUN)
	state.seeded = _options.seeded and _options.seed_value >= 0
	rng = RunRng.new(_options.seed_value if state.seeded else RunRng.draw_seed())
	state.run_seed = rng.run_seed # masked to the bits the generator keeps
	# First, so that the end of the run is notified even when the room below fails to load (AR28).
	_player.died.connect(_on_player_died)
	Events.room_cleared.connect(_on_events_room_cleared)
	Events.shards_collected.connect(_on_events_shards_collected)
	var playing_floor: bool = _options.mode == RunOptions.Mode.FLOOR and _start_floor()
	if not playing_floor and not _start_single_room():
		if _options.mode != RunOptions.Mode.ROOM:
			return
		# A room that cannot be played (bad path, root that is not a Room) must not leave the game empty, nor be
		# replayed by every restart: the arena takes over and Main reads the options actually played.
		Log.error("run", "room of the options cannot be played: playing the arena")
		_options = RunOptions.new()
		if not _start_single_room():
			return
	Log.info("run", "run started seed=%s seeded=%s" % [rng.seed_code(), state.seeded])
	Events.run_started.emit()
	Events.run_seeded.emit(rng.seed_code(), state.seeded) # after run_started: the telemetry run exists
	Events.shards_changed.emit(state.shards) # 0: the HUD and the telemetry start the run from it
	if playing_floor:
		_announce_room() # after run_started: the telemetry session exists


func _exit_tree() -> void:
	if _traveling:
		var transition: Transition = _find_transition()
		if transition != null:
			transition.cancel() # the swap it holds belongs to a run that is leaving
	if _loader != null:
		_loader.drain() # no background request left behind
		_loader = null


## What this run really plays: the options it was given, or the arena options when its room could not be played.
func played_options() -> RunOptions:
	return _options


## The stock of a cell of the floor, made on the first request.
func stock_of(cell: Vector2i) -> RoomStock:
	if not stocks.has(cell):
		stocks[cell] = RoomStock.new()
	return stocks[cell]


## The room that is active now, null between two rooms.
func current_room() -> Room:
	return _room


## The cell of the active room on the floor.
func current_cell() -> Vector2i:
	return _cell


## True from the moment the player took a door until they control the next room.
func is_traveling() -> bool:
	return _traveling


## The loader of the floor's rooms (checks).
func room_loader() -> RoomLoader:
	return _loader


## Plays the floor: asks for every room in the background, enters the start room at once. False (the run falls back to
## the arena, AR28) when the floor is invalid or the start room does not load.
func _start_floor() -> bool:
	var layout: FloorLayout = ensure_floor()
	if not layout.valid:
		Log.error("run", "floor is invalid (%s, seed=%s): playing the arena" % [layout.failure, rng.seed_code()])
		floor_layout = null
		floor_map.layout = null
		return false
	var start_path: String = layout.cells[layout.start].info.path
	var others: PackedStringArray = PackedStringArray()
	for cell: Vector2i in layout.sorted_cells():
		var path: String = layout.cells[cell].info.path
		if path != start_path and not others.has(path):
			others.append(path)
	floor_map.layout = layout
	_loader = RoomLoader.new()
	_loader.scene_for(start_path) # on the spot, before the background requests start: nothing is loading yet
	_loader.request_all(others)
	if _enter_cell(layout.start, -1):
		return true
	Log.error("run", "start room cannot be entered (seed=%s): playing the arena" % rng.seed_code())
	_loader.drain()
	_loader = null
	floor_map.layout = null # the map must not show a floor that is not played
	return false


## Enters the room of a cell: loads it, sets it up for its place on the floor, puts the player at its entry point.
## entry_side: the Door.Side the player comes through, -1 for the middle of the room. False when it cannot be done.
func _enter_cell(cell: Vector2i, entry_side: int) -> bool:
	var placement: FloorLayout.Placement = floor_layout.cells[cell]
	var scene: PackedScene = _loader.scene_for(placement.info.path)
	if scene == null:
		return false
	var node: Node = scene.instantiate()
	var room: Room = node as Room
	if room == null:
		Log.error("run", "scene %s has no Room root" % placement.info.path)
		if node != null:
			node.free() # never entered the tree
		return false
	var options: RoomOptions = RoomOptions.new()
	options.cell = cell
	options.use_links = true
	options.link_sides = floor_layout.door_sides(cell)
	options.already_cleared = floor_map.is_cleared(cell)
	options.entry_side = entry_side
	var first_visit: bool = not stocks.has(cell)
	options.stock = stock_of(cell)
	if first_visit and placement.room_type == Room.RoomType.TREASURE:
		_stock_treasure(room, options.stock)
	if first_visit and placement.room_type == Room.RoomType.SHOP:
		_stock_shop(room, options.stock)
	room.setup(_player, rng, state.floor_index, options) # before add_child()
	_place_player(room)
	if state.floor_index == 0 and placement.room_type == Room.RoomType.START:
		room.add_child(TUTORIAL_SCENE.instantiate())
	_room_slot.add_child(room)
	room.door_taken.connect(_on_room_door_taken)
	_room = room
	_cell = cell
	floor_map.mark_entered(cell)
	if not room.has_fight():
		floor_map.mark_cleared(cell) # nothing to win here: start, treasure, shop
	room.snap_camera() # the camera starts on the player
	return true


## The item of a treasure room, drawn once on the first entry (the loadout of that moment counts) and kept in the stock
## of the cell: a later visit shows the same offer, or none when it was taken. The stream is the treasure one of this floor.
func _stock_treasure(room: Room, stock: RoomStock) -> void:
	var spot: PickupSpot = null
	for candidate: PickupSpot in room.pickup_spots():
		if candidate.slot == PickupSpot.Slot.ITEM:
			spot = candidate
			break
	if spot == null:
		Log.warn("economy", "treasure room without an item pedestal")
		return
	var pool: ItemPoolDef = load(TREASURE_POOL_PATH) as ItemPoolDef
	var def: ItemDef = ItemPicker.draw(pool, _player.carrier.loadout.owned_ids(), _player.health.max_half_hearts,
			rng.stream(RunRng.TREASURE, state.floor_index))
	if def == null:
		Log.warn("economy", "treasure pool is empty after the exclusions: no item in this room")
		return
	stock.add_item(def, spot.position)
	Log.info("economy", "treasure item %s" % def.id)


## The stalls of a shop, drawn once on the first entry on the shop stream of this floor and kept in the stock of the cell:
## a later visit shows what was not bought. Each offer goes on the first free PickupSpot of its slot.
func _stock_shop(room: Room, stock: RoomStock) -> void:
	var pool: ItemPoolDef = load(SHOP_POOL_PATH) as ItemPoolDef
	var offers: Array[RoomStock.Offer] = ShopStock.draw(pool, ConsumableCatalog.all(), _player.carrier.loadout.owned_ids(),
			_player.health.max_half_hearts, rng.stream(RunRng.SHOP, state.floor_index), Tuning.ECONOMY)
	var free_spots: Array[PickupSpot] = room.pickup_spots()
	for offer: RoomStock.Offer in offers:
		var spot: PickupSpot = _take_spot(free_spots, _slot_of(offer.kind))
		if spot == null:
			Log.warn("economy", "shop without a free spot for %s" % offer.id())
			continue
		stock.add_offer(offer, spot.position)
	Log.info("economy", "shop stalls %s" % [offers.map(func(offer: RoomStock.Offer) -> StringName: return offer.id())])


static func _slot_of(kind: RoomStock.Kind) -> PickupSpot.Slot:
	match kind:
		RoomStock.Kind.CONSUMABLE:
			return PickupSpot.Slot.CONSUMABLE
		RoomStock.Kind.HEART:
			return PickupSpot.Slot.HEART
		RoomStock.Kind.ARMOR:
			return PickupSpot.Slot.ARMOR
	return PickupSpot.Slot.ITEM


## Removes and returns the first spot of the slot, null when none is left.
static func _take_spot(spots: Array[PickupSpot], slot: PickupSpot.Slot) -> PickupSpot:
	for spot: PickupSpot in spots:
		if spot.slot == slot:
			spots.erase(spot)
			return spot
	return null


## Tells the journal and the bus that the player came into the active room of the floor.
func _announce_room() -> void:
	var id: StringName = floor_layout.cells[_cell].info.id
	Log.info("run", "room entered %s cell=%s" % [id, _cell])
	Events.room_entered.emit(id, _cell.x, _cell.y)


## The player at the entry point of the room, facing the inside, with nothing left of the motion it had in the last room.
## Before the room enters the tree: its doors close around a player who already stands inside.
func _place_player(room: Room) -> void:
	_player.global_position = room.player_spawn_position()
	_player.stop_motion()
	_player.reset_physics_interpolation() # the player does not trail from where it was
	_player.face(room.frame_px() / 2.0 - room.to_local(_player.global_position))


## The arena (default, a room of the options, or the fallback of a floor that cannot be played). False when the room
## cannot be made (the run then has no room: the error is logged).
func _start_single_room() -> bool:
	var room: Room = _make_room()
	if room == null:
		return false
	room.setup(_player, rng, state.floor_index) # before add_child()
	_room_slot.add_child(room)
	_room = room
	_player.global_position = room.player_spawn_position()
	_player.reset_physics_interpolation() # the player does not trail from (0, 0)
	room.snap_camera() # and the camera starts on the player
	return true


## The room of the run: the arena, or the pre-drawn room of the options. Null (and an error) when it cannot load.
func _make_room() -> Room:
	var scene: PackedScene = ARENA_SCENE
	if _options.mode == RunOptions.Mode.ROOM:
		RoomLoader.collect_orphans(true) # the room may be one a past run still loads
		scene = load(_options.room_path) as PackedScene
		if scene == null:
			Log.error("run", "room scene %s cannot be loaded" % _options.room_path)
			return null
	var node: Node = scene.instantiate()
	var room: Room = node as Room
	if room == null:
		Log.error("run", "room scene root is not a Room")
		if node != null:
			node.free() # never entered the tree
	return room


func _on_player_died() -> void:
	if _ended:
		return
	_ended = true
	Log.info("run", "run ended outcome=death")
	Events.run_ended.emit(Outcome.DEATH)


## A door was taken (a physics callback): the room is not touched here, the trip starts on the next idle moment.
func _on_room_door_taken(side: int) -> void:
	if _traveling or _ended or floor_layout == null:
		return
	_traveling = true
	travel.call_deferred(side)


## Walks through the door of this side of the active room: fade to black, the old room is released, the neighbour
## replaces it, the player appears inside the opposite door, fade back. Called by the door signal, deferred.
func travel(side: int) -> void:
	if _ended:
		_traveling = false # the player died on the very frame of the door
		return
	_traveling = true
	var neighbor: Vector2i = _cell + FloorLayout.SIDE_STEPS[side]
	if _room == null or floor_layout == null or not floor_layout.are_connected(_cell, neighbor):
		Log.error("run", "no room behind the door of side %d" % side)
		_traveling = false
		return
	_player.process_mode = Node.PROCESS_MODE_DISABLED # no move, no shot, no hit during the fade
	_room.process_mode = Node.PROCESS_MODE_DISABLED # the room left stops too: no bullet in flight reaches the frozen player
	var transition: Transition = _find_transition()
	if transition == null:
		_swap_room(neighbor, (side + 2) % 4)
		_end_travel()
	else:
		transition.play(_swap_room.bind(neighbor, (side + 2) % 4), _end_travel)


func _find_transition() -> Transition:
	return get_tree().get_first_node_in_group(Const.GROUP_TRANSITION) as Transition


## Under the black: the room left is released, the next one comes in.
func _swap_room(neighbor: Vector2i, entry_side: int) -> void:
	_release_room()
	if _enter_cell(neighbor, entry_side):
		_announce_room()
	else:
		_fall_back_to_arena("room of cell %s cannot be loaded" % neighbor)


## Out of the tree first (its groups stop counting at once, and it leaves the player), then freed.
func _release_room() -> void:
	if _room != null and is_instance_valid(_room):
		_room_slot.remove_child(_room)
		_room.queue_free()
	_room = null


func _end_travel() -> void:
	_player.process_mode = Node.PROCESS_MODE_INHERIT
	_traveling = false


## A room of the floor cannot be played: the arena of milestone A takes over, the run goes on (AR28).
func _fall_back_to_arena(reason: String) -> void:
	Log.error("run", "%s: playing the arena" % reason)
	floor_layout = null
	floor_map.layout = null
	if _loader != null:
		_loader.drain() # no pending request left for a later load()
		_loader = null
	_player.stop_motion() # a dash in flight must not carry on into the arena
	_options = RunOptions.new() # the arena
	_release_room()
	_start_single_room()


func _on_events_room_cleared(room: Node, lowest_tier: int) -> void:
	if room == null or room != _room:
		return
	floor_map.mark_cleared(_cell)
	_roll_loot(_room, lowest_tier)


## A combat room was emptied: shards, and maybe a drop (story 5.4). The draws on the drops stream are always the same ones
## (see Loot), the drop itself is laid on the next idle moment: this runs inside the emission of room_cleared.
func _roll_loot(room: Room, lowest_tier: int) -> void:
	if _ended or _player.health.is_dead() or room.room_type != Room.RoomType.COMBAT:
		return
	var result: Loot.LootResult = Loot.roll(lowest_tier, rng.stream(RunRng.DROPS, state.floor_index), Tuning.LUCIDITY,
			Tuning.ECONOMY)
	add_shards(result.shards)
	for index: int in result.drops.size():
		Drops.spawn(room, result.drops[index] as Drops.Kind, room.last_kill_position(), result.consumable_rolls[index])
	Log.info("economy", "room cleared tier=%d shards=%d drops=%s" % [lowest_tier, result.shards, result.drops])


## The shards held change (a room cleared, a pickup, later a purchase): the state and the bus.
func add_shards(amount: int) -> void:
	state.add_shards(amount)
	Events.shards_changed.emit(state.shards)


## Pays shards (story 5.5). False when there are not enough.
func spend_shards(amount: int) -> bool:
	if not state.spend_shards(amount):
		return false
	Events.shards_changed.emit(state.shards)
	return true


func _on_events_shards_collected(amount: int) -> void:
	add_shards(amount)


## The floor of this run, generated on the first request and kept: it depends on the seed only, never on the player.
## The streams used (layout, rooms) are not the ones of the fight, so asking for it changes nothing else.
func ensure_floor() -> FloorLayout:
	if floor_layout != null:
		return floor_layout
	var def: FloorDef = load(floor_def_path) as FloorDef
	if def == null:
		Log.error("gen", "floor def %s cannot be loaded" % floor_def_path)
		floor_layout = FloorLayout.new()
		floor_layout.failure = "no floor def"
		return floor_layout
	var pool: Array[RoomInfo] = RoomCatalog.pool(def.pool_dir)
	floor_layout = FloorGenerator.generate(def, pool, rng, state.floor_index)
	if floor_layout.valid:
		Log.info("gen", "floor generated seed=%s attempts=%d" % [rng.seed_code(), floor_layout.attempts])
	else:
		Log.error("gen", "floor of seed %s is invalid: %s" % [rng.seed_code(), floor_layout.failure])
	return floor_layout


## Writes the map of the floor in the journal (F1 panel). False, with an error in the journal, when the floor is invalid.
func log_floor_map() -> bool:
	var layout: FloorLayout = ensure_floor()
	if not layout.valid:
		Log.error("gen", "floor map seed=%s: invalid floor (%s)" % [rng.seed_code(), layout.failure])
		return false
	Log.info("gen", "floor map seed=%s\n%s" % [rng.seed_code(), layout.to_text()])
	return true
