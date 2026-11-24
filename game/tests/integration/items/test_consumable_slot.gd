extends GutTest
## The consumable slot (story 5.3): pick up, replace (the old one drops, armed once the player stepped off), use, HUD.

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const PINCH: ConsumableDef = preload("res://data/consumables/pinch.tres")
const COFFEE: ConsumableDef = preload("res://data/consumables/coffee.tres")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var _harness: RoomHarness
var _player: Player
var _room: Room
var _changes: Array[Array] = []


func before_each() -> void:
	_changes = []
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_room = _harness.room
	Events.consumable_changed.connect(_on_changed)
	await _harness.ticks(2)


func after_each() -> void:
	Events.consumable_changed.disconnect(_on_changed)
	Input.action_release(&"use_consumable")
	_harness.release()


func _on_changed(id: StringName, name_key: StringName) -> void:
	_changes.append([id, name_key])


## Lays the consumable 40 px to the left of the player (the pit band is on the right) and walks the player onto it.
func _step_on(def: ConsumableDef) -> RoomStock.Offer:
	var spot: Vector2 = _player.global_position + Vector2(-40, 0)
	var offer: RoomStock.Offer = _room.add_consumable_offer(def, _room.to_local(spot))
	await _harness.ticks(2)
	_player.global_position = spot
	await _harness.ticks(4)
	return offer


func _carried() -> StringName:
	var def: ConsumableDef = _player.carrier.loadout.consumable
	return def.id if def != null else &""


func test_walking_onto_a_consumable_takes_it_and_tells_the_bus() -> void:
	var requests: Array[Array] = []
	var listener: Callable = func(title: StringName, bonus: StringName, cost: StringName) -> void: requests.append([title, bonus, cost])
	Events.banner_requested.connect(listener)
	var offer: RoomStock.Offer = await _step_on(PINCH)
	Events.banner_requested.disconnect(listener)
	assert_true(offer.taken)
	assert_eq(_carried(), &"pinch")
	assert_eq(_changes, [[&"pinch", &"CONSUMABLE_PINCH_NAME"]])
	assert_eq(requests, [[&"CONSUMABLE_PINCH_NAME", &"CONSUMABLE_PINCH_BONUS", &"CONSUMABLE_PINCH_COST"]])
	assert_eq(_room.pickups().size(), 0)


func test_a_second_consumable_drops_the_first_which_is_not_taken_back_before_the_player_steps_off() -> void:
	await _step_on(PINCH)
	await _step_on(COFFEE)
	assert_eq(_carried(), &"coffee")
	var pickups: Array[Pickup] = _room.pickups()
	assert_eq(pickups.size(), 1, "the pinch lies on the floor")
	assert_eq(pickups[0].offer.consumable, PINCH)
	assert_false(pickups[0].offer.armed)
	assert_lt(pickups[0].global_position.distance_to(_player.global_position), 1.0, "where the player stands")
	await _harness.ticks(20)
	assert_eq(_carried(), &"coffee", "still standing on it: nothing is swapped back")
	assert_eq(_room.pickups().size(), 1)
	# Steps off, then back on: now it is armed and the two swap.
	_player.global_position += Vector2(0, 60)
	await _harness.ticks(6)
	assert_true(_room.pickups()[0].offer.armed)
	_player.global_position -= Vector2(0, 60)
	await _harness.ticks(6)
	assert_eq(_carried(), &"pinch")
	assert_eq(_room.pickups()[0].offer.consumable, COFFEE, "the coffee lies there now")


func test_using_the_consumable_empties_the_slot() -> void:
	await _step_on(PINCH)
	_changes = []
	Input.action_press(&"use_consumable")
	await _harness.ticks(2)
	Input.action_release(&"use_consumable")
	assert_eq(_carried(), &"")
	assert_eq(_changes, [[&"", &""]])


func test_the_key_does_nothing_without_a_consumable() -> void:
	Input.action_press(&"use_consumable")
	await _harness.ticks(2)
	Input.action_release(&"use_consumable")
	assert_eq(_changes.size(), 0)
	assert_eq(_player.health.half_hearts, _player.health.max_half_hearts)


func test_a_refused_use_keeps_the_consumable() -> void:
	await _step_on(PINCH)
	_player.health.lose_half_hearts_unarmored(_player.health.half_hearts - 1)
	Input.action_press(&"use_consumable")
	await _harness.ticks(2)
	Input.action_release(&"use_consumable")
	assert_eq(_carried(), &"pinch")


func test_a_dropped_consumable_never_lands_in_a_pit() -> void:
	var pit: Vector2 = Vector2.ZERO
	var found: bool = false
	for cell_y: int in _room.nav().size_cells().y:
		for cell_x: int in _room.nav().size_cells().x:
			if _room.nav().is_blocked(Vector2i(cell_x, cell_y)) and not found:
				pit = _room.nav().center_of(Vector2i(cell_x, cell_y))
				found = true
	assert_true(found, "the room has a blocked cell")
	var offer: RoomStock.Offer = _room.add_consumable_offer(PINCH, pit, false)
	assert_false(_room.nav().is_blocked(_room.nav().cell_of(offer.position)), "moved to a free cell")


func test_the_hud_shows_and_clears_the_carried_consumable() -> void:
	var hud: Hud = HUD_SCENE.instantiate() as Hud
	add_child_autofree(hud)
	var slot: HudSlot = hud.item_slots()[1]
	assert_false(slot.has_content())
	await _step_on(COFFEE)
	assert_true(slot.has_content())
	assert_eq(slot.content_label(), tr(&"CONSUMABLE_COFFEE_NAME").left(1))
	Input.action_press(&"use_consumable")
	await _harness.ticks(2)
	Input.action_release(&"use_consumable")
	assert_false(slot.has_content())


func test_a_disarmed_consumable_the_player_never_touched_arms_itself() -> void:
	var offer: RoomStock.Offer = _room.add_consumable_offer(PINCH, _room.to_local(_player.global_position + Vector2(-100, 0)), false)
	await _harness.ticks(6)
	assert_true(offer.armed, "a room visited again does not keep it dead")
