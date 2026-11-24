class_name Room
extends Node2D
## A room of the game (story 4.2): playable tiles inside a closed wall frame, a fixed camera, the player's BulletManager,
## the enemy BulletManager (it hits the player's hurtbox; given to every enemy, drawn above the whole world), the
## enemies, the waves, the reinforcements, the doors. The Arena (training room of milestone A) and the pre-drawn rooms
## of epic 4 (room_base.tscn) share this logic.
## Enemies appear only through spawn_enemy() (group "room" lets debug tools find the active room); none at launch.
## The room counts them alive until they leave the tree.
## The decor is a set of TileMapLayers with fixed unique names (Floor, Walls, LowObstacles, HighObstacles, Pits), painted
## in the scene; a subclass may build it in code instead (_build_decor).
## The player is given by the Run through setup() (it is the parent of the room, not a child).
## World origin = top-left corner of the wall frame, in pixels.

## What a room is for. Only COMBAT and NIGHTMARE hold enemies.
enum RoomType { START, COMBAT, TREASURE, SHOP, NIGHTMARE }
## Footprint of a room. WIDE and TALL arrive with story 4.6.
enum SizeKind { SCREEN }

## Tile sources of the onset tileset (rooms/tilesets/onset.tres).
const TILE_FLOOR: int = 0
const TILE_WALL: int = 1
const TILE_HIGH_OBSTACLE: int = 2
const TILE_LOW_OBSTACLE: int = 3
const TILE_PIT: int = 4

## The last enemy left the tree (end of the frame it died in). Also emitted while the room is torn down: listeners must
## ignore it then (the WaveRunner does).
signal emptied

## Technical pool size of the player's shots (~11 in flight at 4/s over 36 tiles at 14 tiles/s).
const PLAYER_BULLET_CAPACITY: int = 128

## Technical pool size of the enemy bullets, same as the load test (F5).
const ENEMY_BULLET_CAPACITY: int = 512

## Placeholder Awakening ring, until epic 7: color and lifetime in seconds (visual, not GDD values).
const AWAKENING_RING_COLOR: Color = Color(0.75, 0.88, 1.0)
const AWAKENING_RING_DURATION: float = 0.35
## Placeholder Glide rings, until epic 7: radius in tiles, color, lifetime in seconds (visual, not GDD values).
const GLIDE_RING_RADIUS_TILES: float = 1.0
const GLIDE_RING_COLOR: Color = Color(0.6, 0.95, 0.85)
const GLIDE_RING_DURATION: float = 0.25
## Danger raised signal (story 3.6), placeholder until epic 7: low sound, red ring around the player, no flash.
const DANGER_RAISED_SOUND: AudioStream = preload("res://audio/sfx/sfx_danger_raised.wav")
const DANGER_RING_COLOR: Color = Color(0.9, 0.15, 0.2)
const DANGER_RING_RADIUS_TILES: float = 2.0
const DANGER_RING_DURATION: float = 0.5
## Reinforcement (story 3.7), placeholder until epic 7: the sign and the sound announcing the apparition.
const REINFORCEMENT_SOUND: AudioStream = preload("res://audio/sfx/sfx_reinforcement.wav")
const REINFORCEMENT_SIGN_COLOR: Color = Color(1.0, 0.75, 0.3)
const REINFORCEMENT_SIGN_RADIUS_TILES: float = 1.5
## Seed of the RunRng an arena makes for itself when the Run gave none (verification scenes).
const FALLBACK_RUN_SEED: int = 1
## Name of the RunRng stream that decides combat outcomes (reinforcement type and place).
const COMBAT_STREAM: StringName = &"combat"
## Name of the RunRng stream of purely visual draws (screen shake): never read by the gameplay.
const COSMETIC_STREAM: StringName = &"cosmetic"
## Ticks between two draws of the screen shake offset (technical: about 20 changes per second).
const SHAKE_STEP_TICKS: int = 3
## Rounding margin when comparing countdown ticks.
const TICK_EPSILON: float = 1e-6
## Centers closer than this (px²) have no usable direction: the push goes to the right.
const KNOCKBACK_MIN_OFFSET_SQ: float = 1e-6

## Technical margin between the playable area and a spawn position, in tiles: no body against a wall.
const SPAWN_MARGIN_TILES: int = 1
## Rounding tolerance when comparing a spawn distance to the minimal one, in pixels (exactly 3 tiles is accepted).
const SPAWN_DISTANCE_EPSILON: float = 1e-3
## Clearance kept between two bodies at spawn, in pixels: two enemies never appear touching or stacked.
const SPAWN_BODY_MARGIN: float = 1.0
## Replacement candidates around a refused request: rings of 1 to this many tiles, in the 8 directions below.
const SPAWN_RING_COUNT: int = 4
const SPAWN_RING_DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0), Vector2(0.70710678, 0.70710678), Vector2(0, 1), Vector2(-0.70710678, 0.70710678),
	Vector2(-1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0, -1), Vector2(0.70710678, -0.70710678),
]

@onready var _floor: TileMapLayer = %Floor
@onready var _walls: TileMapLayer = %Walls
@onready var _high_obstacles: TileMapLayer = %HighObstacles
@onready var _low_obstacles: TileMapLayer = %LowObstacles
## Null in the arena, which has no pits.
var _pits: TileMapLayer
var _player: Player
## Navigation grid of the enemies (story 4.5), built in _ready() once the tiles and the furniture exist.
var _nav: RoomNav

@onready var _camera: Camera2D = %Camera
@onready var _enemies: Node2D = %Enemies
var _player_bullets: BulletManager
var _enemy_bullets: BulletManager
var _alive: int = 0
## Spawns of this room so far: names the next enemy <id>_<n>, never reused (a refused spawn may lose a number).
var _spawn_serial: int = 0
var _wave_runner: WaveRunner
## A nightmare room (epic 6) calls no reinforcement.
@export var is_nightmare: bool = false
## What this room is for (read by the floor generator and the validator).
@export var room_type: RoomType = RoomType.COMBAT
## Phase of the night the room belongs to.
@export var phase: StringName = &"onset"
@export var size_kind: SizeKind = SizeKind.SCREEN
## The doors, found in the Doors node on entry.
var _doors: Array[Door] = []
## Set once end_room() has run: the room is cleared for good.
var _cleared: bool = false

## One reinforcement announced and not yet appeared.
class PendingReinforcement extends RefCounted:
	var def: EnemyDef
	var position: Vector2 # room coordinates
	var ticks_left: float = 0.0
	var sign: ReinforcementSign

var _rng: RunRng
## Enemies planned for the current wave, dead ones included (null-free): decides the type of the reinforcement.
var _wave_defs: Array[EnemyDef] = []
## True from begin_room() with a planned wave until the room is emptied (or the run ends).
var _wave_active: bool = false
## One reinforcement per wave: set when it is scheduled, cleared by begin_room().
var _reinforcement_used: bool = false
var _pending: Array[PendingReinforcement] = []
## Screen shake (story 3.8): ticks left (FX group scale), ticks until the next draw, amplitude in pixels.
var _shake_ticks_left: float = 0.0
var _shake_next_draw: float = 0.0
var _shake_amplitude: int = 0
## What the room tier does to the enemies (story 3.6): one object, mutated in place, given to every enemy.
var danger: DangerProfile = DangerProfile.new()


## Playable tiles of a room of this footprint, walls excluded.
static func playable_tiles_of(kind: SizeKind) -> Vector2i:
	match kind:
		SizeKind.SCREEN:
			return Const.ROOM_TILES
	return Const.ROOM_TILES


## Playable tiles of this room, walls excluded.
func playable_tiles() -> Vector2i:
	return playable_tiles_of(size_kind)


## The doors of the room (children of the Doors node).
func doors() -> Array[Door]:
	var found: Array[Door] = []
	var container: Node = get_node_or_null("Doors")
	if container != null:
		for child: Node in container.get_children():
			var door: Door = child as Door
			if door != null:
				found.append(door)
	return found


## Dependency injection: call before add_child().
## rng: the run's streams; without it the room makes a fixed one (verification scenes).
func setup(player: Player, rng: RunRng = null) -> void:
	_player = player
	_rng = rng


func _ready() -> void:
	add_to_group(Const.GROUP_ROOM)
	if _rng == null:
		_rng = RunRng.new(FALLBACK_RUN_SEED)
	Events.run_ended.connect(_on_events_run_ended)
	if _player == null:
		Log.error("room", "room added without setup()")
		assert(false, "Room.setup() must be called before add_child()")
	if OS.is_debug_build():
		_check_screen_layout()
	var frame_cells: Vector2i = playable_tiles() + Vector2i(2, 2)
	var frame_px: Vector2 = Vector2(frame_cells * Const.TILE_SIZE)

	_floor.z_index = Const.Z_INDEX_DECOR
	_walls.z_index = Const.Z_INDEX_DECOR
	_high_obstacles.z_index = Const.Z_INDEX_DECOR
	_low_obstacles.z_index = Const.Z_INDEX_DECOR
	_pits = get_node_or_null("%Pits") as TileMapLayer
	if _pits != null:
		_pits.z_index = Const.Z_INDEX_DECOR
	_build_decor(frame_cells)
	_setup_doors(frame_cells)
	if _player != null:
		_player.enter_room(self) # the player reads the pits through this room
	_setup_player_bullets() # after the tiles: the BulletManager needs Walls to have a TileSet
	_setup_enemy_bullets() # drawn above the player's shots
	_setup_furniture_and_triggers() # after both BulletManagers: their hurtboxes register with them
	_nav = RoomNav.from_room(self) # after the tiles, the doors and the furniture
	_setup_damage_numbers() # after the bullets: drawn above them
	_setup_lucidity_fx(frame_px)

	# Fixed camera: centered on the room, shifted up by half the HUD band so the band stays free at the top.
	_camera.position = frame_px / 2.0 - Vector2(0.0, Const.HUD_BAND_HEIGHT / 2.0)
	_camera.reset_physics_interpolation()

	if _waves_wanted():
		_setup_waves() # last: spawns need the bullets and the player
		_close_doors() # a fight starts on entry: begin_room() shuts them again (no effect)

	Log.info("room", "%s ready playable=%s tiles" % [_log_name(), playable_tiles()])


## Spawns an enemy: the only way (architecture, "Création d'entités"). requested: room coordinates (the room
## sits at the world origin). Closer than Tuning.COMBAT.min_spawn_distance to the player, outside the playable
## area, or on top of a living enemy: replaced by the nearest valid position (deterministic, no RNG before epic 4).
## Returns null when it cannot spawn (Log.error).
func spawn_enemy(def: EnemyDef, requested: Vector2) -> Enemy:
	if not is_node_ready():
		Log.error("room", "spawn_enemy called before the room is ready")
		_assert_failed("spawn_enemy() before the room is ready")
		return null
	if def == null or def.scene == null or _player == null:
		Log.error("room", "spawn_enemy needs a def with a scene and a player")
		_assert_failed("spawn_enemy() without def, scene or player")
		return null
	var position_px: Vector2 = _resolve_spawn_position(def, requested)
	if not is_finite(position_px.x) or not is_finite(position_px.y):
		Log.error("room", "no valid spawn position for %s" % def.id)
		_assert_failed("spawn_enemy() found no valid position")
		return null
	var node: Node = def.scene.instantiate()
	var enemy: Enemy = node as Enemy
	if enemy == null:
		node.free() # never leak a refused instance
		Log.error("room", "scene of %s is not an Enemy" % def.id)
		_assert_failed("EnemyDef.scene must have an Enemy root")
		return null
	enemy.setup(def, _player, _player.hurtbox, _enemy_bullets, danger, _nav) # before add_child()
	enemy.position = position_px
	_spawn_serial += 1
	enemy.name = "%s_%d" % [_enemy_base_name(def), _spawn_serial] # readable and unique: never a generated "@" name
	_enemies.add_child(enemy)
	if enemy.hurtbox == null or enemy.process_mode == Node.PROCESS_MODE_DISABLED:
		# Its _ready() failed: never counted, registered nor left visible and hittable.
		Log.error("room", "spawn of %s refused: enemy setup failed" % def.id)
		_enemies.remove_child(enemy) # no named node left in Enemies until the end of the frame
		enemy.queue_free()
		_assert_failed("enemy setup failed")
		return null
	enemy.reset_physics_interpolation() # it does not trail from (0, 0)
	if _player_bullets != null:
		_player_bullets.register_hurtbox(enemy.hurtbox)
	_alive += 1
	enemy.tree_exited.connect(_on_enemy_tree_exited, CONNECT_ONE_SHOT)
	Log.debug("room", "spawned %s at %s alive=%d node=%s" % [def.id, position_px, _alive, enemy.name])
	return enemy


## True when the cell under this global position holds a pit tile.
func is_pit_at(global_pos: Vector2) -> bool:
	var pits: TileMapLayer = get_node_or_null("%Pits") as TileMapLayer
	return pits != null and pits.get_cell_source_id(pits.local_to_map(pits.to_local(global_pos))) != -1


## True when the cell under this global position holds a floor tile.
func is_floor_at(global_pos: Vector2) -> bool:
	return _floor.get_cell_source_id(_floor.local_to_map(_floor.to_local(global_pos))) != -1


## Global position of the center of the cell under this global position.
func cell_center_at(global_pos: Vector2) -> Vector2:
	var cell: Vector2i = _floor.local_to_map(_floor.to_local(global_pos))
	return _floor.to_global(_floor.map_to_local(cell))


func _exit_tree() -> void:
	if is_instance_valid(_player):
		_player.leave_room(self)
	_clear_pending() # a room torn down never spawns


func _physics_process(_delta: float) -> void:
	_process_shake()
	if _pending.is_empty():
		return
	var step: float = GameClock.scale(GameClock.Group.ENEMIES)
	if step <= 0.0:
		return
	var due: Array[PendingReinforcement] = []
	for reinforcement: PendingReinforcement in _pending:
		reinforcement.ticks_left -= step
		if reinforcement.ticks_left <= TICK_EPSILON:
			due.append(reinforcement)
	for reinforcement: PendingReinforcement in due:
		_appear(reinforcement)


## Enemies spawned by this room and still in the tree (dead ones leave at the end of their frame).
func alive_enemy_count() -> int:
	return _alive


## Kills every living enemy as a lethal hit would (debug tools). Returns how many it killed.
func kill_all_enemies() -> int:
	var killed: int = 0
	for child: Node in _enemies.get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and not enemy.is_dead():
			enemy.kill()
			killed += 1
	return killed


## Start of the fight, or of a wave of the looping arena (called by WaveRunner before the apparitions): per-wave counters
## of the player start again and the room danger follows the room tier, which is the live tier of this moment.
## wave_defs: the enemies planned for the wave (one def per enemy); it rearms the reinforcement, which comes at once
## when the wave starts in Abandon. The doors shut.
func begin_room(wave_defs: Array[EnemyDef] = []) -> void:
	_clear_pending()
	_close_doors()
	_wave_defs = wave_defs.duplicate()
	_wave_active = not _wave_defs.is_empty()
	_reinforcement_used = false
	if _player != null and _player.lucidity != null:
		_player.lucidity.begin_room()
		danger.apply_tier(_player.lucidity.room_tier, Tuning.LUCIDITY)
	_maybe_schedule_reinforcement()


## A following wave of the same fight (pre-drawn rooms): only the enemies planned for the reinforcement type change.
## The room lucidity counters and the reinforcement are left as they are.
func begin_wave(wave_defs: Array[EnemyDef]) -> void:
	_wave_defs = wave_defs.duplicate()
	_wave_active = not _wave_defs.is_empty()
	_maybe_schedule_reinforcement()


## The last wave is cleared (called by WaveRunner): the doors open.
func end_room() -> void:
	_cleared = true
	for door: Door in _doors:
		door.open()


## True once the fight of a pre-drawn room is won.
func is_cleared() -> bool:
	return _cleared


## Drops the reinforcement announced and not yet appeared (a wave that could not appear brings none).
func cancel_pending_reinforcements() -> void:
	var dropped: bool = not _pending.is_empty()
	_clear_pending()
	if dropped:
		_reinforcement_used = false # the one reinforcement of the room was not consumed by an announcement that never appeared
	_wave_active = false


## The room tier (Lucidity.Tier as an int): the deepest tier reached since the wave began. Lucid without a player.
func room_tier() -> int:
	if _player == null or _player.lucidity == null:
		return Lucidity.Tier.LUCID
	return _player.lucidity.room_tier


## The gauge pulled the live tier below the room tier: the danger follows at once, with a sound and a red ring only
## when the profile actually changed (Lucid -> Floating keeps the same danger).
func _on_room_danger_raised(tier: Lucidity.Tier, _previous: Lucidity.Tier) -> void:
	var changed: bool = danger.apply_tier(tier, Tuning.LUCIDITY)
	_maybe_schedule_reinforcement()
	if not changed:
		Log.debug("combat", "room danger unchanged at tier=%d, no signal" % tier)
		return
	Audio.play_sfx(DANGER_RAISED_SOUND, 1)
	_add_ring(_player.global_position, DANGER_RING_RADIUS_TILES * Const.TILE_SIZE, DANGER_RING_COLOR, DANGER_RING_DURATION)
	Log.debug("combat", "room danger raised tier=%d bullet x%.2f telegraph x%.2f" % [tier, danger.enemy_bullet_speed_mult, danger.telegraph_mult])


## Announces one extra enemy when the room danger calls for it and none came yet in this wave: a copy of the most
## present type of the wave, at a marker 3 tiles or more from the player (drawn now; spawn_enemy() rechecks the
## distance when it appears, as the player moves meanwhile). Both choices come from the run's "combat" stream.
func _maybe_schedule_reinforcement() -> void:
	if is_nightmare or room_type == RoomType.NIGHTMARE or _reinforcement_used or not _wave_active or not danger.reinforcement or _player == null:
		return
	var def: EnemyDef = _pick_reinforcement_def()
	if def == null:
		return
	_reinforcement_used = true
	var reinforcement: PendingReinforcement = PendingReinforcement.new()
	reinforcement.def = def
	reinforcement.position = _pick_reinforcement_position()
	reinforcement.ticks_left = Tuning.LUCIDITY.reinforcement_warning * Engine.physics_ticks_per_second
	var announced: ReinforcementSign = ReinforcementSign.new()
	announced.setup(REINFORCEMENT_SIGN_RADIUS_TILES * Const.TILE_SIZE, REINFORCEMENT_SIGN_COLOR, Tuning.LUCIDITY.reinforcement_warning)
	announced.position = reinforcement.position
	add_child(announced)
	reinforcement.sign = announced
	_pending.append(reinforcement)
	Audio.play_sfx(REINFORCEMENT_SOUND, 1)
	Log.info("room", "reinforcement %s announced at %s in %.1fs" % [def.id, reinforcement.position, Tuning.LUCIDITY.reinforcement_warning])


## The def present most often in the wave plan (dead ones included). A tie is broken by the combat stream, over the
## tied ids in alphabetical order; no draw without a tie.
func _pick_reinforcement_def() -> EnemyDef:
	var counts: Dictionary = {}
	var by_id: Dictionary = {}
	for def: EnemyDef in _wave_defs:
		var previous: int = counts.get(def.id, 0)
		counts[def.id] = previous + 1
		by_id[def.id] = def
	var best: int = 0
	for count: int in counts.values():
		best = maxi(best, count)
	var tied: Array[StringName] = []
	for id: StringName in counts:
		if counts[id] == best:
			tied.append(id)
	if tied.is_empty():
		return null
	tied.sort()
	if tied.size() == 1:
		return by_id[tied[0]]
	return by_id[tied[_rng.stream(COMBAT_STREAM).randi_range(0, tied.size() - 1)]]


## A marker (room coordinates) at least min_spawn_distance from the player, drawn in the combat stream (always one
## draw). When none is far enough, the farthest one: a reinforcement is never lost, spawn_enemy() fixes the distance.
func _pick_reinforcement_position() -> Vector2:
	var markers: Array[Vector2] = []
	var spawns: Node = get_node_or_null("ReinforcementSpawns")
	if spawns != null:
		for child: Node in spawns.get_children():
			var marker: Marker2D = child as Marker2D
			if marker != null:
				markers.append(to_local(marker.global_position))
	var player_pos: Vector2 = to_local(_player.global_position)
	if markers.is_empty():
		Log.error("room", "room has no reinforcement marker")
		_assert_failed("Room needs ReinforcementSpawns markers")
		return Vector2(_spawn_bounds().get_center())
	var min_px: float = Tuning.COMBAT.min_spawn_distance * Const.TILE_SIZE
	var far: Array[Vector2] = []
	var farthest: Vector2 = markers[0]
	for marker_pos: Vector2 in markers:
		if marker_pos.distance_to(player_pos) >= min_px - SPAWN_DISTANCE_EPSILON:
			far.append(marker_pos)
		if marker_pos.distance_to(player_pos) > farthest.distance_to(player_pos):
			farthest = marker_pos
	if far.is_empty():
		far.append(farthest)
	return far[_rng.stream(COMBAT_STREAM).randi_range(0, far.size() - 1)]


## The countdown is over: the enemy appears through spawn_enemy(). A refusal that leaves the room empty ends the wave.
func _appear(reinforcement: PendingReinforcement) -> void:
	_pending.erase(reinforcement)
	if is_instance_valid(reinforcement.sign):
		reinforcement.sign.queue_free()
	var enemy: Enemy = spawn_enemy(reinforcement.def, reinforcement.position)
	Log.info("room", "reinforcement %s %s" % [reinforcement.def.id, "appeared" if enemy != null else "failed to appear"])
	if enemy == null:
		_emit_emptied_if_done()


func _clear_pending() -> void:
	for reinforcement: PendingReinforcement in _pending:
		if is_instance_valid(reinforcement.sign):
			reinforcement.sign.queue_free()
	_pending.clear()


func _on_events_run_ended(_outcome: int) -> void:
	_clear_pending() # a finished run brings nothing more
	_wave_active = false


## Reinforcements announced and not yet appeared.
func pending_reinforcement_count() -> int:
	return _pending.size()


## The player's BulletManager (checks).
func player_bullets() -> BulletManager:
	return _player_bullets


## The enemy BulletManager (checks).
func enemy_bullets() -> BulletManager:
	return _enemy_bullets


## The wave runner, or null when waves are disabled (verification tools).
func wave_runner() -> WaveRunner:
	return _wave_runner


## Where the player enters the room (center of the playable area), in global coordinates.
func player_spawn_position() -> Vector2:
	var frame_px: Vector2 = Vector2((playable_tiles() + Vector2i(2, 2)) * Const.TILE_SIZE)
	return to_global(frame_px / 2.0)


## Hook: how the room is named in the log.
func _log_name() -> String:
	return "room"


## Hook: paints or builds the decor layers. The pre-drawn rooms are painted in their scene: nothing to do.
func _build_decor(_frame_cells: Vector2i) -> void:
	pass


## Hook: true when the room runs waves on entry. A pre-drawn room does when it has enemy markers.
func _waves_wanted() -> bool:
	return not enemy_spawns().is_empty()


## Hook: the waves of this room. The pre-drawn rooms read their EnemySpawn markers, in tree order: a wave is the
## markers sharing a `wave` value (waves in increasing order) and its slots are those markers, in tiles. The list does
## not loop: the fight ends after the last wave.
func _make_wave_list() -> WaveList:
	var spawns: Array[EnemySpawn] = enemy_spawns()
	var by_wave: Dictionary = {}
	for spawn: EnemySpawn in spawns:
		var members: Array = by_wave.get_or_add(spawn.wave, [])
		members.append(spawn)
	var wave_numbers: Array = by_wave.keys()
	wave_numbers.sort()
	var list: WaveList = WaveList.new()
	list.loop = false
	list.start_delay = Tuning.ROOM.first_wave_delay
	list.pause_duration = Tuning.ROOM.wave_pause
	for wave_number: int in wave_numbers:
		var wave: WaveDef = WaveDef.new()
		for member: EnemySpawn in by_wave[wave_number]:
			if member.enemy == null or member.enemy.scene == null:
				continue # no entry and no slot: the slots of the other markers stay aligned
			var entry: WaveEntry = WaveEntry.new()
			entry.enemy = member.enemy
			entry.count = 1
			wave.entries.append(entry)
			list.spawn_slots.append(to_local(member.global_position) / Const.TILE_SIZE)
		if not wave.entries.is_empty():
			list.waves.append(wave)
	return list


## Hook: hurtboxes present in the scene (not enemies) that the player's shots must hit.
func _register_static_hurtboxes(_bullets: BulletManager) -> void:
	pass


## The pieces of furniture of the room, in tree order (an arena has none), destroyed ones included.
func furnitures() -> Array[Furniture]:
	var found: Array[Furniture] = []
	var container: Node = get_node_or_null("Furnitures")
	if container != null:
		for child: Node in container.get_children():
			var piece: Furniture = child as Furniture
			if piece != null:
				found.append(piece)
	return found


## The triggers of the room, in tree order.
func triggers() -> Array[Trigger]:
	var found: Array[Trigger] = []
	var container: Node = get_node_or_null("Triggers")
	if container != null:
		for child: Node in container.get_children():
			var element: Trigger = child as Trigger
			if element != null:
				found.append(element)
	return found


## The living enemies of the room whose center is at most radius_px from the point (global), center to center.
## Enemies that have not appeared yet (a reinforcement still announced) are not in the room: never reached.
func enemies_within(point: Vector2, radius_px: float) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for child: Node in _enemies.get_children():
		var enemy: Enemy = child as Enemy
		if enemy != null and not enemy.is_dead() and not enemy.is_queued_for_deletion() \
				and enemy.global_position.distance_to(point) <= radius_px:
			found.append(enemy)
	return found


## The EnemySpawn markers, in tree order (an arena has none).
func enemy_spawns() -> Array[EnemySpawn]:
	var found: Array[EnemySpawn] = []
	var container: Node = get_node_or_null("EnemySpawns")
	if container != null:
		for child: Node in container.get_children():
			var spawn: EnemySpawn = child as EnemySpawn
			if spawn != null:
				found.append(spawn)
	return found


## Gives every piece of furniture and every trigger its place in the BulletManagers (they exist by now).
func _setup_furniture_and_triggers() -> void:
	for piece: Furniture in furnitures():
		piece.register_hurtboxes(_player_bullets, _enemy_bullets)
	for element: Trigger in triggers():
		element.register(_player_bullets, self)


func _setup_doors(frame_cells: Vector2i) -> void:
	_doors = doors()
	for door: Door in _doors:
		door.attach(_walls, frame_cells)


func _close_doors() -> void:
	for door: Door in _doors:
		door.close()


func _setup_waves() -> void:
	var list: WaveList = _make_wave_list()
	var runner: WaveRunner = WaveRunner.new()
	_wave_runner = runner
	runner.name = "WaveRunner"
	runner.setup(self, list) # before add_child()
	add_child(runner)


## The player's BulletManager, at the room origin like Walls. Added last: drawn above the player (Combat layer).
func _setup_player_bullets() -> void:
	var bullets: BulletManager = BulletManager.new()
	_player_bullets = bullets
	bullets.name = "PlayerBullets"
	bullets.camp = BulletManager.Camp.PLAYER
	bullets.capacity = PLAYER_BULLET_CAPACITY
	var solid_layers: Array[TileMapLayer] = [_walls, _high_obstacles] # low obstacles let shots pass
	bullets.setup(solid_layers) # before add_child()
	add_child(bullets)
	# Static hurtboxes do not need the player: register them even when setup() was skipped.
	_register_static_hurtboxes(bullets)
	if _player != null:
		_player.equip_bullets(bullets)


## The enemy BulletManager, at the room origin, kept to give to every enemy. It has no look: the first shooter adds
## EnemyBulletLook.texture(), the next ones get the same index. Drawn above everything else in the world, damage
## numbers included (NFR8).
func _setup_enemy_bullets() -> void:
	var bullets: BulletManager = BulletManager.new()
	_enemy_bullets = bullets
	bullets.name = "EnemyBullets"
	bullets.z_index = Const.Z_INDEX_ENEMY_BULLETS
	bullets.camp = BulletManager.Camp.ENEMY
	bullets.capacity = ENEMY_BULLET_CAPACITY
	var solid_layers: Array[TileMapLayer] = [_walls, _high_obstacles] # low obstacles let shots pass
	bullets.setup(solid_layers) # before add_child()
	add_child(bullets)
	if _player != null:
		bullets.register_hurtbox(_player.hurtbox)
		bullets.enable_graze(_player.hurtbox, Tuning.LUCIDITY.graze_radius)
		bullets.grazed.connect(_player.on_bullet_grazed)
		bullets.dodged.connect(_player.on_bullet_dodged)
		_player.lucidity.room_danger_raised.connect(_on_room_danger_raised)
		_player.awakening_used.connect(_on_awakening_used)
		_player.glided.connect(_on_player_glided)


## Awakening (story 3.3): wipes the enemy bullets, pushes the close enemies back, shows a ring. origin: global.
func _on_awakening_used(origin: Vector2) -> void:
	var tuning: AwakeningTuning = Tuning.AWAKENING
	var cleared: int = _enemy_bullets.clear_all()
	var radius_px: float = tuning.effect_radius * Const.TILE_SIZE
	var push_px: float = tuning.knockback_distance * Const.TILE_SIZE
	var pushed: int = 0
	# Farthest first, so a close enemy is never blocked by a farther one that has not moved yet.
	var in_range: Array[Enemy] = []
	for child: Node in _enemies.get_children():
		var enemy: Enemy = child as Enemy
		if enemy == null or enemy.is_dead():
			continue
		if enemy.global_position.distance_to(origin) < radius_px:
			in_range.append(enemy)
	in_range.sort_custom(func(a: Enemy, b: Enemy) -> bool: return a.global_position.distance_squared_to(origin) > b.global_position.distance_squared_to(origin))
	# A body moved by the physics server is only seen at its new place on the next physics step: the enemies already
	# pushed the full distance are ignored by the next ones (they are farther out, so nothing is crossed).
	var moved_full: Array[Enemy] = []
	for enemy: Enemy in in_range:
		var offset: Vector2 = enemy.global_position - origin
		var direction: Vector2 = offset.normalized() if offset.length_squared() >= KNOCKBACK_MIN_OFFSET_SQ else Vector2.RIGHT
		for moved: Enemy in moved_full:
			enemy.add_collision_exception_with(moved)
		var covered: float = enemy.knock_back(direction, push_px)
		if covered > 0.0:
			pushed += 1
		if covered >= push_px - 0.01:
			moved_full.append(enemy)
	for enemy: Enemy in in_range:
		for moved: Enemy in moved_full:
			enemy.remove_collision_exception_with(moved)
	_add_ring(origin, radius_px, AWAKENING_RING_COLOR, AWAKENING_RING_DURATION)
	shake(Tuning.LUCIDITY.shake_pixels, Tuning.LUCIDITY.shake_duration)
	Log.debug("combat", "awakening cleared=%d pushed=%d" % [cleared, pushed])


## Glide (story 3.4): a ring at the departure and at the arrival. from, to: global.
func _on_player_glided(from: Vector2, to: Vector2) -> void:
	var radius_px: float = GLIDE_RING_RADIUS_TILES * Const.TILE_SIZE
	_add_ring(from, radius_px, GLIDE_RING_COLOR, GLIDE_RING_DURATION)
	_add_ring(to, radius_px, GLIDE_RING_COLOR, GLIDE_RING_DURATION)


func _add_ring(origin: Vector2, radius_px: float, color: Color, duration: float) -> void:
	var ring: RingPulse = RingPulse.new()
	ring.setup(radius_px, color, duration)
	ring.position = to_local(origin)
	add_child(ring)


## Playable area in pixels (cells 1 to 36 by 1 to 19), shrunk by SPAWN_MARGIN_TILES so a body never appears
## against a wall.
func _spawn_bounds() -> Rect2:
	var margin: float = (1 + SPAWN_MARGIN_TILES) * Const.TILE_SIZE
	var playable: Vector2 = Vector2(playable_tiles() * Const.TILE_SIZE)
	return Rect2(Vector2.ONE * margin, playable - Vector2.ONE * SPAWN_MARGIN_TILES * 2.0 * Const.TILE_SIZE)


## requested if valid (inside the bounds, at least min_spawn_distance from the player, clear of living bodies), else
## the valid candidate nearest to it. Candidates, in this order (a tie keeps the earlier one): the request clamped to
## the bounds, that point pushed out to the minimal distance, rings of 1 to 4 tiles around it (8 directions), the
## player-centered point pushed out toward the request, the corners of the bounds.
## A request that is not finite is refused (Log.error + assert) and treated as "to the right of the player": the
## candidates keep their order, no distance is computed.
## Returns Vector2(INF, INF) when no candidate is valid.
func _resolve_spawn_position(def: EnemyDef, requested: Vector2) -> Vector2:
	var bounds: Rect2 = _spawn_bounds()
	var player_pos: Vector2 = to_local(_player.global_position)
	var min_px: float = Tuning.COMBAT.min_spawn_distance * Const.TILE_SIZE
	var body_px: Vector2 = def.body_size * Const.TILE_SIZE
	var request_finite: bool = is_finite(requested.x) and is_finite(requested.y)
	var anchor: Vector2 = requested
	if not request_finite:
		Log.error("room", "spawn request %s is not finite, treated as refused" % requested)
		_assert_failed("spawn_enemy() needs a finite position")
		anchor = player_pos + Vector2.RIGHT * min_px
	if request_finite and _is_valid_spawn(requested, bounds, player_pos, min_px, body_px):
		return requested
	var clamped: Vector2 = anchor.clamp(bounds.position, bounds.end)
	var candidates: Array[Vector2] = [clamped, _pushed_from_player(clamped, player_pos, min_px)]
	for ring: int in range(1, SPAWN_RING_COUNT + 1):
		for direction: Vector2 in SPAWN_RING_DIRECTIONS:
			candidates.append(clamped + direction * ring * Const.TILE_SIZE)
	candidates.append(_pushed_from_player(anchor, player_pos, min_px))
	candidates.append(bounds.position)
	candidates.append(Vector2(bounds.end.x, bounds.position.y))
	candidates.append(Vector2(bounds.position.x, bounds.end.y))
	candidates.append(bounds.end)
	var best: Vector2 = Vector2(INF, INF)
	var best_distance: float = INF
	for candidate: Vector2 in candidates:
		if not _is_valid_spawn(candidate, bounds, player_pos, min_px, body_px):
			continue
		if not request_finite:
			best = candidate # list order
			break
		var distance: float = candidate.distance_to(requested)
		if distance < best_distance:
			best = candidate
			best_distance = distance
	if is_finite(best.x):
		Log.debug("room", "spawn at %s refused (too close, outside or occupied), moved to %s" % [requested, best])
	return best


## The point moved radially away from the player until it is min_px from it (unchanged when already far enough).
func _pushed_from_player(point: Vector2, player_pos: Vector2, min_px: float) -> Vector2:
	var away: Vector2 = point - player_pos
	if away.length() >= min_px:
		return point
	var direction: Vector2 = away.normalized() if away.length_squared() > 1e-6 else Vector2.RIGHT
	return player_pos + direction * min_px


func _is_valid_spawn(point: Vector2, bounds: Rect2, player_pos: Vector2, min_px: float, body_px: Vector2) -> bool:
	var inside: bool = point.x >= bounds.position.x and point.x <= bounds.end.x \
		and point.y >= bounds.position.y and point.y <= bounds.end.y # inclusive: the corners are valid
	if not inside or point.distance_to(player_pos) < min_px - SPAWN_DISTANCE_EPSILON:
		return false
	var rect: Rect2 = Rect2(point - body_px / 2.0, body_px).grow(SPAWN_BODY_MARGIN)
	return not _overlaps_obstacle(rect) and not _overlaps_living_enemy(rect)


## True when the rectangle (room coordinates) touches a cell of a wall, a pit or a low or high obstacle.
func _overlaps_obstacle(rect: Rect2) -> bool:
	var first: Vector2i = Vector2i((rect.position / Const.TILE_SIZE).floor())
	var last: Vector2i = Vector2i((rect.end / Const.TILE_SIZE).floor())
	for y: int in range(first.y, last.y + 1):
		for x: int in range(first.x, last.x + 1):
			var cell: Vector2i = Vector2i(x, y)
			if _high_obstacles.get_cell_source_id(cell) != -1 or _low_obstacles.get_cell_source_id(cell) != -1 \
					or _walls.get_cell_source_id(cell) != -1 or (_pits != null and _pits.get_cell_source_id(cell) != -1):
				return true
	for piece: Furniture in furnitures():
		if not piece.is_destroyed():
			var piece_rect: Rect2 = piece.footprint_rect()
			piece_rect.position = to_local(piece_rect.position)
			if rect.intersects(piece_rect):
				return true
	return false


## True when the rectangle (room coordinates) touches the body of an enemy that is alive and not being freed.
func _overlaps_living_enemy(rect: Rect2) -> bool:
	for child: Node in _enemies.get_children():
		var other: Enemy = child as Enemy
		if other == null or other.is_dead() or other.is_queued_for_deletion():
			continue
		var other_rect: Rect2 = other.body_world_rect()
		other_rect.position = to_local(other_rect.position)
		if rect.intersects(other_rect):
			return true
	return false


func _on_enemy_tree_exited() -> void:
	_alive = maxi(_alive - 1, 0)
	_emit_emptied_if_done()


## Emptied: nobody alive and no reinforcement still to come (the wave is not over before the last one appeared).
func _emit_emptied_if_done() -> void:
	if _alive == 0 and _pending.is_empty():
		_wave_active = false
		emptied.emit()


## A failed assert aborts the function it is in (debug builds): kept apart so the caller carries on (AR28).
func _assert_failed(message: String) -> void:
	assert(false, message)


## Distortion and music filter following the live lucidity tier (story 3.8).
func _setup_lucidity_fx(frame_px: Vector2) -> void:
	if _player == null:
		return
	var fx: LucidityFx = LucidityFx.new()
	fx.name = "LucidityFx"
	fx.setup(_player, frame_px) # before add_child()
	add_child(fx)


## Shakes the camera by whole pixels for duration seconds (story 3.8). pixels: the largest offset per axis, before the
## shake setting; nothing happens when the setting is 0, in photosensitivity mode, or when the result rounds to 0 px.
## The offsets come from the cosmetic stream of the run and the camera comes back exactly to zero.
func shake(pixels: int, duration: float) -> void:
	var amplitude: int = roundi(pixels * Settings.shake_intensity)
	if Settings.photosensitive or amplitude <= 0 or duration <= 0.0:
		return
	_shake_amplitude = amplitude
	_shake_ticks_left = duration * Engine.physics_ticks_per_second
	_shake_next_draw = 0.0


## The camera's current shake offset in pixels (checks).
func shake_offset() -> Vector2:
	return _camera.offset


func _process_shake() -> void:
	if _shake_ticks_left <= 0.0:
		return
	if Settings.photosensitive or Settings.shake_intensity <= 0.0:
		_shake_ticks_left = 0.0 # setting changed during a frozen shake
		_camera.offset = Vector2.ZERO
		return
	var step: float = GameClock.scale(GameClock.Group.FX)
	if step <= 0.0:
		return # paused: the shake is frozen where it is
	_shake_ticks_left -= step
	if _shake_ticks_left <= TICK_EPSILON:
		_shake_ticks_left = 0.0
		_camera.offset = Vector2.ZERO
		return
	_shake_next_draw -= step
	if _shake_next_draw <= TICK_EPSILON:
		_shake_next_draw = SHAKE_STEP_TICKS
		_camera.offset = Vector2(_shake_axis(), _shake_axis())


## One axis of a shake offset: a whole number of pixels from 1 to the amplitude, in a random direction (cosmetic stream).
func _shake_axis() -> int:
	var magnitude: int = _rng.stream(COSMETIC_STREAM).randi_range(1, _shake_amplitude)
	var negative: int = _rng.stream(COSMETIC_STREAM).randi_range(0, 1)
	return -magnitude if negative == 1 else magnitude


## Damage numbers layer, at the room origin. Added after PlayerBullets: drawn above the shots.
func _setup_damage_numbers() -> void:
	var numbers: DamageNumbers = DamageNumbers.new()
	numbers.name = "DamageNumbers"
	add_child(numbers)


## The room (walls included) plus the HUD band must fit the viewport exactly in height, with a margin in width.
func _check_screen_layout() -> void:
	var tiles: Vector2i = playable_tiles()
	var height_ok: bool = Const.VIEWPORT.y - Const.HUD_BAND_HEIGHT == (tiles.y + 2) * Const.TILE_SIZE
	var width_margin: int = Const.VIEWPORT.x - (tiles.x + 2) * Const.TILE_SIZE
	if not height_ok or width_margin < 0:
		Log.error("room", "room does not fit the viewport (height_ok=%s width_margin=%d)" % [height_ok, width_margin])
		assert(false, "Room layout out of sync with Const")



## The def id as a valid node name ("enemy" when the id is empty).
func _enemy_base_name(def: EnemyDef) -> String:
	var base: String = String(def.id).validate_node_name()
	return base if not base.is_empty() else "enemy"


## The navigation grid of the enemies (null before the room is ready).
func nav() -> RoomNav:
	return _nav


## Cells (room coordinates) the enemies cannot walk on: walls, obstacles, pits and door cells (a door is a wall
## while the fight lasts and nobody crosses it before the room is cleared). Living furniture is added by RoomNav.
func solid_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for layer: TileMapLayer in [_walls, _high_obstacles, _low_obstacles, _pits]:
		if layer != null:
			cells.append_array(layer.get_used_cells())
	for door: Door in _doors:
		cells.append_array(door.cells())
	return cells


## The cells (room coordinates) covered by a piece of furniture.
func furniture_cells(piece: Furniture) -> Array[Vector2i]:
	var rect: Rect2 = piece.footprint_rect()
	rect.position = to_local(rect.position)
	var first: Vector2i = Vector2i((rect.position / Const.TILE_SIZE).round())
	var count: Vector2i = Vector2i((rect.size / Const.TILE_SIZE).round())
	var cells: Array[Vector2i] = []
	for y: int in count.y:
		for x: int in count.x:
			cells.append(first + Vector2i(x, y))
	return cells
