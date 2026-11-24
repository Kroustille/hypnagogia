extends GutTest
## The active item (story 5.8): charge, recharge, cap, replacement with charge, refusals that spend nothing.

const ALARM: ItemDef = preload("res://data/items/broken_alarm.tres")
const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")

var _player: Player
var _changes: Array[Array] = []


func before_each() -> void:
	_player = PlayerFactory.make(self)
	_changes.clear()
	Events.active_item_changed.connect(_on_changed)


func after_each() -> void:
	Events.active_item_changed.disconnect(_on_changed)
	GameClock.reset_slows()
	_player.free()


func _on_changed(id: StringName, charge: int, charge_max: int) -> void:
	_changes.append([id, charge, charge_max])


func _clear_room() -> void:
	_player.carrier.room_cleared.emit(null, 0)


func test_a_new_active_item_is_charged_and_announced() -> void:
	var owned: OwnedItem = _player.carrier.acquire(ALARM)
	assert_eq(_player.carrier.loadout.active, owned)
	assert_eq(owned.charge, 3)
	assert_eq(owned.charge_max, 3)
	var last: Array = _changes[_changes.size() - 1]
	assert_eq(last, [&"broken_alarm", 3, 3])


func test_use_spends_fifteen_empties_the_charge_and_slows() -> void:
	_player.carrier.acquire(ALARM)
	var before: int = _player.lucidity.value
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.USED)
	assert_eq(_player.lucidity.value, before - 15)
	assert_eq(_player.carrier.loadout.active.charge, 0)
	assert_almost_eq(GameClock.scale(GameClock.Group.ENEMIES), 0.5, 0.0001)
	assert_eq(GameClock.scale(GameClock.Group.PLAYER), 1.0)
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.REFUSED, "not charged any more, even while slowed")
	assert_eq(_player.lucidity.value, before - 15)


func test_three_cleared_rooms_recharge_and_the_charge_is_capped() -> void:
	_player.carrier.acquire(ALARM)
	_player.carrier.use_active()
	_clear_room()
	_clear_room()
	assert_eq(_player.carrier.loadout.active.charge, 2)
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.REFUSED)
	_clear_room()
	assert_eq(_player.carrier.loadout.active.charge, 3)
	_clear_room()
	assert_eq(_player.carrier.loadout.active.charge, 3, "capped")


func test_a_short_gauge_refuses_and_keeps_the_charge() -> void:
	_player.carrier.acquire(ALARM)
	_player.lucidity.set_value(14)
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.REFUSED)
	assert_eq(_player.lucidity.value, 14)
	assert_eq(_player.carrier.loadout.active.charge, 3)
	assert_eq(GameClock.slow_count(), 0)


func test_exactly_fifteen_is_enough() -> void:
	_player.carrier.acquire(ALARM)
	_player.lucidity.set_value(15)
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.USED)
	assert_eq(_player.lucidity.value, 0)


func test_nothing_without_an_item_and_a_refusal_when_dead() -> void:
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.NONE)
	_player.carrier.acquire(ALARM)
	var info: DamageInfo = DamageInfo.new()
	info.amount = 99.0
	info.source = DamageInfo.Source.ENEMY_BULLET
	_player.health.apply_damage(info)
	assert_true(_player.health.is_dead())
	assert_eq(_player.carrier.use_active(), BuildCarrier.UseResult.REFUSED)
	assert_eq(_player.carrier.loadout.active.charge, 3)


func test_replacing_returns_the_old_item_with_its_charge() -> void:
	var loadout: Loadout = _player.carrier.loadout
	loadout.set_active(ALARM)
	loadout.set_charge(1)
	var other: ItemDef = ALARM.duplicate() as ItemDef
	other.id = &"other_alarm"
	var previous: OwnedItem = loadout.set_active(other)
	assert_eq(previous.def, ALARM)
	assert_eq(previous.charge, 1)
	assert_eq(loadout.active.def, other)
	assert_eq(loadout.active.charge, 3, "a new item is charged")
	assert_eq(loadout.copies_of(&"broken_alarm"), 0)
	assert_eq(loadout.count(), 1)


func test_taking_it_again_with_a_charge_keeps_that_charge() -> void:
	var owned: OwnedItem = _player.carrier.acquire(ALARM, 2)
	assert_eq(owned.charge, 2)
	var last: Array = _changes[_changes.size() - 1]
	assert_eq(last, [&"broken_alarm", 2, 3])


func test_a_plain_item_is_not_the_active_item() -> void:
	_player.carrier.acquire(TOOTH)
	assert_null(_player.carrier.loadout.active)
