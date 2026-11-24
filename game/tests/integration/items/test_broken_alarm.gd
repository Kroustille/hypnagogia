extends GutTest
## The Broken Alarm in a real room (story 5.8): the key, the slowed enemy bullet, the free player and player shots, the end of
## the slow, the swap on the floor, the new run.

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const ALARM: ItemDef = preload("res://data/items/broken_alarm.tres")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var _harness: RoomHarness
var _player: Player
var _room: Room


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_room = _harness.room
	await _harness.ticks(2)


func after_each() -> void:
	Input.action_release(&"use_active")
	GameClock.reset_slows()
	_harness.release()


func _press_use() -> void:
	Input.action_press(&"use_active")
	await _harness.ticks(2)
	Input.action_release(&"use_active")
	await _harness.ticks(1)


## Horizontal distance the first bullet of the manager covers in n ticks.
func _bullet_travel(manager: BulletManager, ticks: int) -> float:
	assert_true(_harness.fire_shot(manager, _player.global_position + Vector2(0, -80), Vector2.RIGHT, 6.0))
	var start: float = manager._positions[0].x
	await _harness.ticks(ticks)
	var travelled: float = manager._positions[0].x - start
	manager.clear_all()
	return travelled


func test_the_key_slows_the_enemy_bullets_but_not_the_players() -> void:
	_player.carrier.acquire(ALARM)
	var normal_enemy: float = await _bullet_travel(_room.enemy_bullets(), 10)
	var normal_player: float = await _bullet_travel(_room.player_bullets(), 10)
	var before: int = _player.lucidity.value
	await _press_use()
	assert_eq(_player.lucidity.value, before - 15)
	assert_eq(_player.carrier.loadout.active.charge, 0)
	var slowed_enemy: float = await _bullet_travel(_room.enemy_bullets(), 10)
	var slowed_player: float = await _bullet_travel(_room.player_bullets(), 10)
	assert_almost_eq(slowed_enemy, normal_enemy * 0.5, normal_enemy * 0.05)
	assert_almost_eq(slowed_player, normal_player, normal_player * 0.05)


func test_the_player_walks_at_full_speed_during_the_slow() -> void:
	_player.carrier.acquire(ALARM)
	GameClock.apply_slow(_player.carrier.loadout.active.effect, [GameClock.Group.ENEMIES] as Array[GameClock.Group], 0.5, 4.0)
	assert_eq(GameClock.scale(GameClock.Group.PLAYER), 1.0)
	assert_eq(GameClock.scale(GameClock.Group.FX), 1.0)
	assert_eq(GameClock.scale(GameClock.Group.PLAYER_BULLETS), 1.0)


func test_everything_is_back_to_one_after_four_seconds() -> void:
	_player.carrier.acquire(ALARM)
	await _press_use()
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMY_BULLETS), 0.5, 0.0001)
	await _harness.ticks(250)
	assert_eq(GameClock.scale(GameClock.Group.ENEMY_BULLETS), 1.0)
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)
	assert_eq(GameClock.scale(GameClock.Group.WORLD), 1.0)


func test_a_new_run_while_slowed_starts_at_one() -> void:
	_player.carrier.acquire(ALARM)
	await _press_use()
	Events.run_started.emit()
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)


func test_a_refusal_with_a_short_gauge_changes_nothing() -> void:
	_player.carrier.acquire(ALARM)
	_player.lucidity.set_value(10)
	await _press_use()
	assert_eq(_player.lucidity.value, 10)
	assert_eq(_player.carrier.loadout.active.charge, 3)
	assert_eq(GameClock.scale(GameClock.Group.ENEMIES), 1.0)


func test_the_hud_slot_shows_the_item_and_its_charge() -> void:
	var hud: Hud = HUD_SCENE.instantiate() as Hud
	add_child_autofree(hud)
	await _harness.ticks(1)
	_player.carrier.acquire(ALARM)
	var slot: HudSlot = hud.item_slots()[0]
	assert_true(slot.has_content())
	assert_eq(slot.charge(), 3)
	assert_eq(slot.charge_max(), 3)
	_player.carrier.use_active()
	assert_eq(slot.charge(), 0)
	Events.run_started.emit()
	assert_false(slot.has_content())


func test_a_second_active_item_lays_the_first_on_the_floor_with_its_charge() -> void:
	var other: ItemDef = ALARM.duplicate() as ItemDef
	other.id = &"other_alarm"
	_player.carrier.acquire(ALARM)
	_player.carrier.use_active()
	var spot: Vector2 = _player.global_position + Vector2(40, 0)
	_room.add_offer(other, _room.to_local(spot))
	await _harness.ticks(2)
	_player.global_position = spot
	await _harness.ticks(6)
	assert_eq(_player.carrier.loadout.active.def, other)
	assert_eq(_player.carrier.loadout.active.charge, 3)
	var laid: RoomStock.Offer = null
	for pickup: Pickup in _room.pickups():
		if pickup.offer.item == ALARM:
			laid = pickup.offer
	assert_not_null(laid, "the old one lies on the floor")
	assert_eq(laid.charge, 0)
	assert_false(laid.armed, "not taken back at once")
