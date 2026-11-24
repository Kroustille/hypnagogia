extends GutTest
## Every night starts from nothing (story 6.5, AC 3): nothing leaks from a destroyed Run.

const MAIN_SCENE: PackedScene = preload("res://main/main.tscn")
const ITEM: ItemDef = preload("res://data/items/lead_legs.tres")
const ACTIVE: ItemDef = preload("res://data/items/broken_alarm.tres")
const CONSUMABLE: ConsumableDef = preload("res://data/consumables/coffee.tres")

var _main: Main


func before_each() -> void:
	Main.start_in_bedroom = false
	_main = MAIN_SCENE.instantiate() as Main
	add_child(_main)
	await wait_physics_frames(2)


func after_each() -> void:
	RoomLoader.collect_orphans(true)
	remove_child(_main)
	_main.queue_free()


func _run() -> Run:
	return get_tree().get_first_node_in_group(Const.GROUP_RUN) as Run


func _player() -> Player:
	return get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player


func _assert_fresh() -> void:
	var player: Player = _player()
	assert_eq(player.health.half_hearts, 6, "3 hearts")
	assert_eq(player.health.armor, 0)
	assert_eq(player.lucidity.value, 100)
	assert_eq(_run().state.shards, 0)
	assert_eq(player.carrier.loadout.count(), 0)
	assert_null(player.carrier.loadout.consumable)
	assert_null(player.carrier.loadout.active)


func test_the_next_run_after_a_death_starts_from_nothing() -> void:
	var player: Player = _player()
	player.carrier.acquire(ITEM)
	player.carrier.acquire(ACTIVE)
	player.carrier.acquire_consumable(CONSUMABLE)
	_run().state.add_shards(40)
	player.health.half_hearts = 1
	player.lucidity.value = 20
	assert_gt(player.carrier.loadout.count(), 0, "the run before had objects")
	Events.run_ended.emit(Run.Outcome.DEATH)
	await wait_physics_frames(25)
	(_wake().get_node("%BedroomButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	assert_null(_run())
	assert_null(_player(), "nothing of the old player in the bedroom")
	Events.run_requested.emit(RunOptions.Mode.FLOOR, -1, false, "")
	await wait_physics_frames(2)
	_assert_fresh()


func test_a_quick_restart_starts_from_nothing_too() -> void:
	var player: Player = _player()
	player.carrier.acquire(ITEM)
	_run().state.add_shards(7)
	player.health.half_hearts = 2
	Events.run_ended.emit(Run.Outcome.VICTORY)
	await wait_physics_frames(25)
	(_wake().get_node("%RestartButton") as Button).pressed.emit()
	await wait_physics_frames(2)
	_assert_fresh()


func _wake() -> WakeScreen:
	return _main.find_children("*", "WakeScreen", true, false)[0] as WakeScreen
