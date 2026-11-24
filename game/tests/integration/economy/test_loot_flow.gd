extends GutTest
## A cleared combat room pays shards and may leave a drop (story 5.4), through a real Run.

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"

var _harness: RoomHarness
var _player: Player
var _room: Room
var _totals: Array[int] = []


func before_each() -> void:
	_totals = []
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_room = _harness.room
	_room.room_type = Room.RoomType.COMBAT # the fixture is a start room
	Events.shards_changed.connect(_on_shards)
	await _harness.ticks(2)


func after_each() -> void:
	Events.shards_changed.disconnect(_on_shards)
	_harness.release()


func _on_shards(total: int) -> void:
	_totals.append(total)


func _clear(tier: int = 0) -> void:
	Events.room_cleared.emit(_room, tier)
	await _harness.ticks(2) # the drop is laid on the idle moment


func test_the_total_is_announced_as_zero_when_the_run_starts() -> void:
	var late: Array[int] = []
	var fresh: RoomHarness = RoomHarness.new()
	add_child(fresh)
	var listener: Callable = func(total: int) -> void: late.append(total)
	Events.shards_changed.connect(listener)
	fresh.start(ROOM)
	Events.shards_changed.disconnect(listener)
	assert_eq(late, [0])
	fresh.release()


func test_clearing_a_combat_room_adds_shards_and_tells_the_bus() -> void:
	await _clear(0)
	assert_between(_totals[0], 1, 3) # the first announcement: a shards drop lying on the floor may add to the state later
	assert_true(_harness.run.state.shards >= _totals[0])


func test_deeper_tiers_pay_more_on_the_same_seed() -> void:
	var reference: RunRng = RunRng.new(_harness.run.rng.run_seed)
	var base: int = reference.stream(RunRng.DROPS, 0).randi_range(1, 3)
	await _clear(4)
	assert_eq(_totals[0], base * 2)


func test_a_treasure_room_gives_nothing() -> void:
	_room.room_type = Room.RoomType.TREASURE
	await _clear(0)
	assert_eq(_harness.run.state.shards, 0)
	assert_eq(_room.pickups().size(), 0)


func test_a_nightmare_room_gives_nothing() -> void:
	_room.room_type = Room.RoomType.NIGHTMARE
	await _clear(0)
	assert_eq(_harness.run.state.shards, 0)


func test_the_drop_stream_advances_by_the_same_amount_every_room() -> void:
	await _clear(0)
	var rng: RunRng = _harness.run.rng
	var parallel: RunRng = RunRng.new(rng.run_seed)
	Loot.roll(0, parallel.stream(RunRng.DROPS, 0), Tuning.LUCIDITY, Tuning.ECONOMY)
	assert_eq(rng.stream(RunRng.DROPS, 0).randi(), parallel.stream(RunRng.DROPS, 0).randi())


func _force_drop(kind: Drops.Kind) -> void:
	Drops.spawn(_room, kind, Vector2(60, 60), 0)
	await _harness.ticks(2)


func test_a_drop_is_laid_without_a_busy_parent_and_in_a_free_cell() -> void:
	_player.global_position = Vector2(-500, -500) # far away: nothing is taken
	await _force_drop(Drops.Kind.SHARDS_3)
	assert_eq(_room.pickups().size(), 1)
	assert_eq(_room.pickups()[0].offer.kind, RoomStock.Kind.SHARDS)


func test_a_drop_asked_for_a_room_that_left_the_tree_is_not_laid() -> void:
	var slot: Node = _room.get_parent()
	Drops.spawn(_room, Drops.Kind.SHARDS_3, Vector2(60, 60), 0)
	slot.remove_child(_room)
	await _harness.ticks(2)
	assert_eq(_room.pickups().size(), 0)
	slot.add_child(_room) # back in the tree for the harness cleanup


func test_shards_on_the_floor_are_taken() -> void:
	await _force_drop(Drops.Kind.SHARDS_3)
	_player.global_position = _room.to_global(_room.pickups()[0].position)
	await _harness.ticks(4)
	assert_eq(_harness.run.state.shards, 3)
	var last: int = _totals[_totals.size() - 1]
	assert_eq(last, 3)
	assert_eq(_room.pickups().size(), 0)


func test_a_half_heart_is_left_at_full_health_then_taken_after_a_hit() -> void:
	await _force_drop(Drops.Kind.HALF_HEART)
	var pickup: Pickup = _room.pickups()[0]
	_player.global_position = _room.to_global(pickup.position)
	await _harness.ticks(6)
	assert_eq(_room.pickups().size(), 1, "full health: it stays")
	_player.health.set_forced_invulnerability(false)
	_player.health.apply_damage(DamageInfo.from_bullet(1.0, Vector2.ZERO, DamageInfo.Source.DEBUG))
	await _harness.ticks(4)
	assert_eq(_room.pickups().size(), 0, "hurt while standing on it: taken")
	assert_eq(_player.health.half_hearts, _player.health.max_half_hearts, "hurt for 1, healed for 1")


func test_an_armor_drop_is_left_at_the_cap() -> void:
	var health: Health = _player.health
	health.add_armor(health.cap_half_hearts() - health.max_half_hearts - health.armor)
	await _force_drop(Drops.Kind.HALF_ARMOR)
	_player.global_position = _room.to_global(_room.pickups()[0].position)
	await _harness.ticks(6)
	assert_eq(_room.pickups().size(), 1)


func test_an_armor_drop_is_taken_under_the_cap() -> void:
	var before: int = _player.health.armor
	await _force_drop(Drops.Kind.HALF_ARMOR)
	_player.global_position = _room.to_global(_room.pickups()[0].position)
	await _harness.ticks(4)
	assert_eq(_player.health.armor, before + 1)


func test_two_consumables_under_the_player_are_not_swapped_with_each_other() -> void:
	var pinch: ConsumableDef = load("res://data/consumables/pinch.tres") as ConsumableDef
	var coffee: ConsumableDef = load("res://data/consumables/coffee.tres") as ConsumableDef
	var spot: Vector2 = _room.to_local(_player.global_position + Vector2(-40, 0))
	_room.add_consumable_offer(pinch, spot)
	_room.add_consumable_offer(coffee, spot)
	_player.global_position += Vector2(-40, 0)
	await _harness.ticks(8)
	assert_not_null(_player.carrier.loadout.consumable)
	assert_eq(_room.pickups().size(), 1, "the second waits on the floor")
	var kept: StringName = _player.carrier.loadout.consumable.id
	var left: Pickup = _room.pickups()[0]
	assert_ne(left.offer.consumable.id, kept)


func test_an_invalid_item_is_refused_by_the_room() -> void:
	var broken: ItemDef = ItemDef.new()
	assert_null(_room.add_offer(broken, Vector2(50, 50)))
	assert_push_error("add_offer() refused item")
	assert_eq(_room.pickups().size(), 0)


func test_blank_exam_adds_one_drop_laid_beside_the_first() -> void:
	_player.carrier.acquire(load("res://data/items/blank_exam.tres") as ItemDef)
	var parallel: RunRng = RunRng.new(_harness.run.rng.run_seed)
	var expected: Loot.LootResult = Loot.roll(0, parallel.stream(RunRng.DROPS, 0), Tuning.LUCIDITY, Tuning.ECONOMY, 1)
	assert_gte(expected.drops.size(), 1, "the guaranteed one")
	_player.global_position = Vector2(-500, -500)
	await _harness.ticks(2)
	await _clear(0)
	var pickups: Array[Pickup] = _room.pickups()
	assert_eq(pickups.size(), expected.drops.size())
	var cells: Dictionary = {}
	for pickup: Pickup in pickups:
		cells[_room.nav().cell_of(pickup.offer.position)] = true
	assert_eq(cells.size(), pickups.size(), "each in its own cell")
	assert_eq(_harness.run.rng.stream(RunRng.DROPS, 0).randi(), parallel.stream(RunRng.DROPS, 0).randi())
