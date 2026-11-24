extends GutTest
## The death of The Professor (story 6.4): the chalks go, the reward comes once, the room opens, the bar hides.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const APPEAR_TICKS: int = 120
const ANNOUNCE_TICKS: int = 90

var _harness: RoomHarness
var _defeated: Array[StringName] = []
var _shards: int = 0


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_defeated.clear()
	_shards = 0
	Events.boss_defeated.connect(_on_defeated)
	Events.shards_collected.connect(_on_shards)


func after_each() -> void:
	Events.boss_defeated.disconnect(_on_defeated)
	Events.shards_collected.disconnect(_on_shards)
	_harness.release()


func _on_defeated(id: StringName) -> void:
	_defeated.append(id)


func _on_shards(amount: int) -> void:
	_shards += amount


func _boss() -> Boss:
	for enemy: Enemy in _harness.living_enemies():
		if enemy is Boss:
			return enemy as Boss
	return null


func _fighting_boss() -> Boss:
	_harness.start(BOSS_ROOM)
	await _harness.until(func() -> bool: return _boss() != null, APPEAR_TICKS)
	var boss: Boss = _boss()
	await _harness.until(func() -> bool: return boss.is_fighting(), ANNOUNCE_TICKS + 30)
	return boss


func _lethal_hit(boss: Boss) -> void:
	boss.debug_set_hp_fraction(0.001)
	boss._on_hurtbox_damage_received(DamageInfo.from_bullet(250.0, Vector2.DOWN, DamageInfo.Source.PLAYER_SHOT))


func test_a_lethal_hit_clears_the_chalks_and_pays_ten_shards_once() -> void:
	var boss: Boss = await _fighting_boss()
	await _harness.until(func() -> bool: return _harness.room.enemy_bullets().active_count > 0, 300)
	assert_gt(_harness.room.enemy_bullets().active_count, 0, "there are chalks to clear")
	watch_signals(Events)
	_lethal_hit(boss)
	assert_true(boss.is_dead())
	assert_eq(_harness.room.enemy_bullets().active_count, 0)
	assert_eq(_shards, 10)
	assert_eq(_defeated, [&"professor"] as Array[StringName])
	assert_signal_emitted_with_parameters(Events, "boss_health_changed", [0.0, 2500.0])
	assert_true(boss.runners().is_empty())


func test_killing_twice_changes_nothing() -> void:
	var boss: Boss = await _fighting_boss()
	boss.kill()
	boss.kill()
	_lethal_hit(boss)
	assert_eq(_shards, 10)
	assert_eq(_defeated.size(), 1)


func test_the_room_is_cleared_and_its_doors_open_without_loot() -> void:
	var boss: Boss = await _fighting_boss()
	var shards_before: int = _harness.run.state.shards
	_lethal_hit(boss)
	await _harness.until(func() -> bool: return _harness.room.is_cleared(), 120)
	assert_true(_harness.room.is_cleared())
	assert_eq(_harness.run.state.shards, shards_before + 10, "the reward only, no room loot")
	assert_eq(_harness.room.alive_enemy_count(), 0)
