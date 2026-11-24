extends GutTest
## Every combat room of the real pool is playable (story 4.10, AC 9): all its waves appear (no refused spawn), the room
## is cleared once and its doors open.

const POOL_DIR: String = "res://rooms/pool/onset"
## Ceiling, in ticks, to wait for a wave: the first comes after 1 s and each following one 2 s after the previous is cleared.
const WAVE_TICKS: int = 400

var _harness: RoomHarness


func after_each() -> void:
	if _harness != null:
		_harness.release()


func test_every_combat_room_plays_through() -> void:
	var played: int = 0
	watch_signals(Events)
	for info: RoomInfo in RoomCatalog.pool(POOL_DIR):
		if info.room_type != Room.RoomType.COMBAT:
			continue
		await _play(info)
		played += 1
	assert_gte(played, 30, "all the combat rooms were played")


func _cleared_count() -> int:
	var count: int = get_signal_emit_count(Events, "room_cleared")
	return count


func _play(info: RoomInfo) -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(info.path)
	var planned: Dictionary[int, int] = {}
	for spawn: EnemySpawn in _harness.room.enemy_spawns():
		planned[spawn.wave] = planned.get(spawn.wave, 0) + 1
	var waves: Array = planned.keys()
	waves.sort()
	var cleared_before: int = _cleared_count()
	for wave: int in waves:
		var appeared: bool = await _harness.until(func() -> bool: return _harness.living_enemies().size() >= planned[wave], WAVE_TICKS)
		assert_true(appeared, "%s wave %d: its %d markers each produced an enemy (%d)" % [info.id, wave, planned[wave], _harness.living_enemies().size()])
		_harness.room.kill_all_enemies()
		await _harness.ticks(2)
	await _harness.until(func() -> bool: return _cleared_count() > cleared_before, WAVE_TICKS)
	assert_eq(_cleared_count() - cleared_before, 1, "%s: cleared once" % info.id)
	for door: Door in _harness.room.doors():
		assert_true(_harness.door_is_open(door), "%s: the %s door opens" % [info.id, Door.Side.find_key(door.side)])
	_harness.release()
	_harness = null
	await get_tree().process_frame
