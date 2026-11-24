extends GutTest
## A pause (or a door fade) switches the physics off and reports an exit: stacked pickups still wait for the player to
## really step off (story 5.4 review).

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const PINCH: ConsumableDef = preload("res://data/consumables/pinch.tres")
const COFFEE: ConsumableDef = preload("res://data/consumables/coffee.tres")

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	await _harness.ticks(2)


func after_each() -> void:
	_harness.release()


func test_a_pause_does_not_release_the_pickup_held_under_the_player() -> void:
	var player: Player = _harness.player
	var room: Room = _harness.room
	var spot: Vector2 = room.to_local(player.global_position + Vector2(-40, 0))
	room.add_consumable_offer(PINCH, spot)
	room.add_consumable_offer(COFFEE, spot)
	player.global_position = room.to_global(spot)
	await _harness.ticks(5)
	assert_not_null(player.carrier.loadout.consumable, "one taken")
	var held: Pickup = room.pickups()[0]
	assert_eq(room.pickups().size(), 1, "the other waits on the floor")
	_harness.run.process_mode = Node.PROCESS_MODE_DISABLED # what Main._freeze does to the active scene
	await _harness.ticks(2)
	_harness.run.process_mode = Node.PROCESS_MODE_INHERIT
	await _harness.ticks(5)
	assert_false(held.offer.taken, "still held: the player never stepped off")
	assert_eq(room.pickups().size(), 1)
