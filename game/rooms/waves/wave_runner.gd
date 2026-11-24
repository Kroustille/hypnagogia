class_name WaveRunner
extends Node
## Chains the waves of a room (story 2.6, FR32): waits, spawns a wave through room.spawn_enemy(), and when the room
## has no enemy left emits Events.room_cleared, pauses, then spawns the next wave. The list loops after its last wave.
## Child of the Arena, created by it. setup() before add_child(). Reads the WaveList only, never writes it.
## The countdown runs in physics ticks scaled by GameClock (frozen on pause and wake screen, slowed by F4).

enum State { IDLE, WAITING, FIGHTING }

## Technical ceiling of one wave (enemies at once): keeps the enemy bullet pool (512) and the screen readable.
const MAX_WAVE_ENEMIES: int = 12

var _room: Arena
var _list: WaveList
var _state: State = State.IDLE
var _ticks_left: float = 0.0
## Index of the next wave in the list.
var _next_index: int = 0
## Waves spawned so far, loops included (1 = the first one while it is running).
var _wave_number: int = 0
## Next spawn slot: walked through across waves, never reset.
var _slot_cursor: int = 0
## The valid waves of the list: [[EnemyDef, ...] one entry per enemy, truncated to MAX_WAVE_ENEMIES].
var _waves: Array[Array] = []


## Dependency injection: call before add_child().
func setup(room: Arena, list: WaveList) -> void:
	_room = room
	_list = list


func _ready() -> void:
	if _room == null or _list == null:
		Log.error("room", "wave runner added without setup()")
		assert(false, "WaveRunner.setup() must be called before add_child()")
		return
	_validate()
	if _waves.is_empty():
		Log.error("room", "wave list has no enemy: no wave will appear")
		_assert_failed("WaveList needs at least one wave with an enemy")
		return
	if _list.spawn_slots.is_empty():
		Log.error("room", "wave list has no spawn slot: no wave will appear")
		_assert_failed("WaveList needs at least one spawn slot")
		_waves.clear()
		return
	_room.emptied.connect(_on_room_emptied)
	Events.run_ended.connect(_on_events_run_ended)
	_wait(_list.start_delay)


func _exit_tree() -> void:
	_state = State.IDLE # a room torn down (restart) emits nothing


func _on_events_run_ended(_outcome: int) -> void:
	_state = State.IDLE # a finished run clears no room and spawns no wave


## 1 for the first wave while it runs; 0 before it; keeps counting after the list loops.
func wave_number() -> int:
	return _wave_number


func state_name() -> String:
	return State.keys()[_state]


## Debug (F1): kills every enemy without clearing the room, then spawns the next wave at once.
func force_next_wave() -> void:
	if _state == State.IDLE:
		return
	_room.kill_all_enemies()
	_start_next_wave()


func _physics_process(_delta: float) -> void:
	if _state != State.WAITING:
		return
	var step: float = GameClock.scale(GameClock.Group.ENEMIES)
	if step <= 0.0:
		return
	_ticks_left -= step
	if _ticks_left <= 1e-6:
		_start_next_wave()


func _wait(seconds: float) -> void:
	_state = State.WAITING
	_ticks_left = seconds * Engine.physics_ticks_per_second


func _on_room_emptied() -> void:
	if _state != State.FIGHTING:
		return # pause, debug spawns or teardown
	Log.debug("room", "wave %d cleared" % _wave_number)
	# state first: a listener that re-enters or tears the room down must see WAITING (or IDLE)
	_wait(_list.pause_duration)
	Events.room_cleared.emit(_room, _room.room_tier())


## Spawns the next valid wave. Nothing could appear: the wave is skipped and the pause starts (never a stuck room).
func _start_next_wave() -> void:
	var defs: Array = _waves[_next_index % _waves.size()]
	_next_index = (_next_index + 1) % _waves.size()
	_wave_number += 1
	_room.begin_room() # before the apparitions
	var spawned: int = 0
	for def: EnemyDef in defs:
		var slot: Vector2 = _list.spawn_slots[_slot_cursor % _list.spawn_slots.size()] * Const.TILE_SIZE
		_slot_cursor += 1
		if _room.spawn_enemy(def, slot) != null:
			spawned += 1
	Log.debug("room", "wave %d spawned %d/%d enemies" % [_wave_number, spawned, defs.size()])
	if spawned == 0:
		_wait(_list.pause_duration)
	else:
		_state = State.FIGHTING


## Keeps the valid enemies of each wave (one EnemyDef per enemy). Invalid entries are reported and ignored.
func _validate() -> void:
	_waves.clear()
	for index: int in _list.waves.size():
		var wave: WaveDef = _list.waves[index]
		var defs: Array[EnemyDef] = []
		if wave == null or wave.entries.is_empty():
			Log.error("room", "wave %d ignored: null or without entries" % index)
			_assert_failed("a WaveDef needs at least one entry")
			continue
		for entry: WaveEntry in wave.entries:
			if entry == null or entry.enemy == null or entry.enemy.scene == null or entry.count <= 0:
				Log.error("room", "wave entry ignored: it needs an enemy with a scene and a count above 0")
				_assert_failed("WaveEntry needs an enemy with a scene and count > 0")
				continue
			for i: int in entry.count:
				defs.append(entry.enemy)
		if defs.size() > MAX_WAVE_ENEMIES:
			Log.error("room", "wave of %d enemies truncated to %d" % [defs.size(), MAX_WAVE_ENEMIES])
			_assert_failed("a wave holds at most MAX_WAVE_ENEMIES enemies")
			defs.resize(MAX_WAVE_ENEMIES)
		if not defs.is_empty():
			_waves.append(defs)


## A failed assert aborts the function it is in (debug builds): kept apart so the caller carries on (AR28).
func _assert_failed(message: String) -> void:
	assert(false, message)
