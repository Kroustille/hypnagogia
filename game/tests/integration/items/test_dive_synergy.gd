extends GutTest
## The Fall synergies in a real room (story 5.7): Piqué (2 items) and Chute sans fin (3 items).

const ROOM: String = "res://tests/fixtures/rooms/furniture_room.tscn"
const PIT_ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const ENEMY_PATH: String = "res://data/enemies/night_light.tres" # loaded at run time: preloading it here trips a script load cycle through arena_waves
const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const WINGS: ItemDef = preload("res://data/items/paper_wings.tres")
const T: float = 16.0

var _harness: RoomHarness
var _player: Player
var _banners: Array[StringName] = []


func before_each() -> void:
	_banners.clear()
	Events.banner_requested.connect(_on_banner)


func after_each() -> void:
	Events.banner_requested.disconnect(_on_banner)
	_harness.release()


func _on_banner(title: StringName, _bonus: StringName, _cost: StringName) -> void:
	_banners.append(title)


func _start(path: String) -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(path)
	_player = _harness.player
	_player.health.set_forced_invulnerability(false)


func _enemy_at(point: Vector2) -> Enemy:
	var enemy: Enemy = _harness.room.spawn_enemy(load(ENEMY_PATH) as EnemyDef, _harness.room.to_local(point))
	assert_not_null(enemy)
	return enemy


## A sheep far away, the player placed at distance_px of it, then the dash ends.
func _dash_end_near(enemy: Enemy, distance_px: float) -> void:
	_player.global_position = enemy.global_position + Vector2(distance_px, 0.0)
	_player.carrier.dash_ended.emit()


func test_one_fall_item_has_no_shockwave() -> void:
	_start(ROOM)
	_player.carrier.acquire(TOOTH)
	var enemy: Enemy = _enemy_at(Vector2(400.0, 200.0))
	_dash_end_near(enemy, T)
	assert_eq(enemy.hp.current, enemy.hp.maximum)
	assert_eq(_banners.size(), 1, "only the item banner")


func test_dive_hits_enemies_and_furniture_in_range_but_not_the_player() -> void:
	_start(ROOM)
	_player.carrier.acquire(TOOTH)
	_player.carrier.acquire(LEGS)
	assert_eq(_banners.size(), 3, "two items and the synergy")
	assert_eq(_banners[2], &"SYNERGY_FALL_2_NAME")
	var near: Enemy = _enemy_at(Vector2(400.0, 200.0))
	var far: Enemy = _enemy_at(Vector2(400.0, 260.0))
	var hearts: int = _player.health.half_hearts
	var near_hp: float = near.hp.current
	_dash_end_near(near, T)
	assert_eq(near.hp.current, near_hp - 15.0)
	assert_eq(far.hp.current, far.hp.maximum, "3+ tiles away")
	assert_eq(_player.health.half_hearts, hearts)
	var bed: Furniture = _harness.room.furnitures()[0]
	var hp_before: float = bed.hp.current
	_player.global_position = bed.footprint_rect().get_center() + Vector2(T, 0.0)
	_player.carrier.dash_ended.emit()
	assert_eq(bed.hp.current, hp_before - 15.0)
	_player.global_position = bed.footprint_rect().get_center() + Vector2(T * 4.0, 0.0)
	_player.carrier.dash_ended.emit()
	assert_eq(bed.hp.current, hp_before - 15.0, "out of the 1.5 tile radius")


func test_the_third_item_doubles_the_wave_without_adding_and_frees_the_fall() -> void:
	_start(ROOM)
	_player.carrier.acquire(TOOTH)
	_player.carrier.acquire(LEGS)
	_player.carrier.acquire(WINGS)
	assert_true(_banners.has(&"SYNERGY_FALL_3_NAME"))
	var enemy: Enemy = _enemy_at(Vector2(400.0, 200.0))
	var hp_before: float = enemy.hp.current
	_dash_end_near(enemy, T * 2.2)
	assert_eq(enemy.hp.current, hp_before - 30.0, "30 not 15 + 30, at 2.2 tiles")
	assert_eq(_player.stats.value_of(StatBlock.Stat.PIT_DAMAGE), 0.0)


func test_each_synergy_is_announced_once() -> void:
	_start(ROOM)
	_player.carrier.acquire(TOOTH)
	var legs: OwnedItem = _player.carrier.acquire(LEGS)
	_player.carrier.acquire(WINGS)
	_player.carrier.loadout.remove(legs)
	_player.carrier.loadout.remove(_player.carrier.loadout.items()[0]) # below every threshold
	assert_eq(_banners.count(&"SYNERGY_FALL_2_NAME"), 1)
	assert_eq(_banners.count(&"SYNERGY_FALL_3_NAME"), 1)
	_player.carrier.acquire(LEGS)
	_player.carrier.acquire(TOOTH)
	assert_eq(_banners.count(&"SYNERGY_FALL_2_NAME"), 1, "no new announcement")


func test_losing_the_level_stops_the_wave_and_restores_the_fall_cost() -> void:
	_start(ROOM)
	_player.carrier.acquire(TOOTH)
	var legs: OwnedItem = _player.carrier.acquire(LEGS)
	var wings: OwnedItem = _player.carrier.acquire(WINGS)
	_player.carrier.loadout.remove(wings)
	assert_eq(_player.stats.value_of(StatBlock.Stat.PIT_DAMAGE), 1.0)
	_player.carrier.loadout.remove(legs)
	var enemy: Enemy = _enemy_at(Vector2(400.0, 200.0))
	_dash_end_near(enemy, T)
	assert_eq(enemy.hp.current, enemy.hp.maximum, "no synergy left")


func test_falling_into_a_pit_costs_no_heart_with_three_items_and_still_returns_to_safety() -> void:
	_start(PIT_ROOM)
	_player.carrier.acquire(TOOTH)
	_player.carrier.acquire(LEGS)
	_player.carrier.acquire(WINGS)
	_player.carrier.loadout.remove(_player.carrier.loadout.items()[2]) # wings: they would carry the player over
	_player.carrier.acquire(preload("res://data/items/free_fall.tres"))
	var hearts: int = _player.health.half_hearts
	_player.global_position = Vector2(328.0, 168.0)
	await _harness.ticks(2)
	_player.global_position = Vector2(344.0, 168.0)
	await _harness.ticks(3)
	assert_lt(_player.global_position.x, 336.0, "back on the safe side")
	assert_eq(_player.health.half_hearts, hearts)
