extends GutTest
## Walking onto an item takes it (story 5.1): loadout, stats, hearts, banner, bus, refusal at one heart, stock of the cell.

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const TOOTH: ItemDef = preload("res://data/items/falling_tooth.tres")
const LEGS: ItemDef = preload("res://data/items/lead_legs.tres")
const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")

var _harness: RoomHarness
var _player: Player
var _room: Room
var _requests: Array[Array] = []
var _acquired: Array[Array] = []


func before_each() -> void:
	_requests = []
	_acquired = []
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_room = _harness.room
	Events.banner_requested.connect(_on_banner)
	Events.item_acquired.connect(_on_acquired)
	await _harness.ticks(2)


func after_each() -> void:
	Events.banner_requested.disconnect(_on_banner)
	Events.item_acquired.disconnect(_on_acquired)
	_harness.release()


func _on_banner(title: StringName, bonus: StringName, cost: StringName) -> void:
	_requests.append([title, bonus, cost])


func _on_acquired(item_id: StringName, copies: int) -> void:
	_acquired.append([item_id, copies])


## Lays the item 40 px from the player and walks the player onto it.
func _lay_and_step_on(def: ItemDef) -> RoomStock.Offer:
	var spot: Vector2 = _player.global_position + Vector2(40, 0)
	var offer: RoomStock.Offer = _room.add_offer(def, _room.to_local(spot))
	await _harness.ticks(2)
	_player.global_position = spot
	await _harness.ticks(4)
	return offer


func test_a_tooth_is_taken_with_its_bonus_and_its_price() -> void:
	var damage_before: float = _player.stats.value_of(StatBlock.Stat.DAMAGE)
	var offer: RoomStock.Offer = await _lay_and_step_on(TOOTH)
	assert_true(offer.taken)
	assert_eq(_room.pickups().size(), 0, "the pickup is gone")
	assert_eq(_player.carrier.loadout.copies_of(&"falling_tooth"), 1)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.DAMAGE), damage_before * 1.3, 0.0001)
	assert_eq(_player.health.max_half_hearts, 4, "one heart paid")
	assert_eq(_player.health.half_hearts, 4)
	assert_eq(_acquired, [[&"falling_tooth", 1]])
	assert_eq(_requests, [[&"ITEM_FALLING_TOOTH_NAME", &"ITEM_FALLING_TOOTH_BONUS", &"ITEM_FALLING_TOOTH_COST"]])


func test_two_teeth_make_sixty_percent_and_cost_two_hearts_but_never_the_last() -> void:
	await _lay_and_step_on(TOOTH)
	var second: RoomStock.Offer = await _lay_and_step_on(TOOTH)
	assert_true(second.taken)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.DAMAGE), Tuning.SHOT.damage * 1.6, 0.0001)
	assert_eq(_player.health.max_half_hearts, 2, "one heart left")
	var third: RoomStock.Offer = await _lay_and_step_on(TOOTH)
	assert_false(third.taken, "refused: a third tooth would kill the owner of the last heart")
	assert_eq(_player.carrier.loadout.copies_of(&"falling_tooth"), 2)
	assert_eq(_room.pickups().size(), 1, "it stays on the floor")
	assert_lt(_room.pickups()[0].modulate.a, 1.0, "greyed")
	assert_eq(_acquired.size(), 2)


func test_a_tooth_is_greyed_from_the_start_with_one_heart_max() -> void:
	_player.health.lose_max(4)
	var offer: RoomStock.Offer = _room.add_offer(TOOTH, _room.to_local(_player.global_position + Vector2(60, 0)))
	await _harness.ticks(3)
	assert_false(offer.taken)
	assert_false(_room.pickups()[0].is_available())
	assert_lt(_room.pickups()[0].modulate.a, 1.0)


func test_lead_legs_slow_the_walk_and_clear_cleanly() -> void:
	await _lay_and_step_on(LEGS)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.MOVE_SPEED), Tuning.PLAYER.move_speed * 0.8, 0.0001)
	assert_gt(_player.stats.value_of(StatBlock.Stat.PIERCE), 0.0)
	assert_true(_player._shot_params.pierce, "the shot goes through")
	var owned: OwnedItem = _player.carrier.loadout.items()[0]
	_player.carrier.loadout.remove(owned)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.MOVE_SPEED), Tuning.PLAYER.move_speed, 0.0001)
	assert_eq(_player.stats.value_of(StatBlock.Stat.PIERCE), 0.0)
	assert_false(_player._shot_params.pierce)


func test_removing_a_tooth_gives_the_heart_back() -> void:
	await _lay_and_step_on(TOOTH)
	_player.carrier.loadout.remove(_player.carrier.loadout.items()[0])
	assert_eq(_player.health.max_half_hearts, 6)


func test_a_player_already_standing_on_the_item_when_it_appears_takes_it() -> void:
	var offer: RoomStock.Offer = _room.add_offer(LEGS, _room.to_local(_player.global_position))
	await _harness.ticks(4)
	assert_true(offer.taken)


func test_an_item_left_on_the_floor_is_still_there_on_the_next_visit() -> void:
	var cell: Vector2i = _room.cell()
	var stock: RoomStock = RoomStock.new()
	stock.add_item(LEGS, Vector2(100, 100))
	var taken: RoomStock.Offer = stock.add_item(TOOTH, Vector2(120, 100))
	taken.taken = true
	assert_eq(stock.remaining().size(), 1)
	assert_eq(_harness.run.stock_of(cell), _harness.run.stock_of(cell), "one stock per cell")


func test_the_banner_shows_name_bonus_and_cost_then_goes_away() -> void:
	var hud: Hud = HUD_SCENE.instantiate() as Hud
	add_child_autofree(hud)
	await _lay_and_step_on(LEGS)
	var banner: Banner = hud.banner()
	assert_true(banner.is_showing())
	assert_eq(banner.lines()[0], tr(&"ITEM_LEAD_LEGS_NAME"))
	assert_eq(banner.lines()[1], tr(&"ITEM_LEAD_LEGS_BONUS"))
	assert_eq(banner.lines()[2], tr(&"ITEM_LEAD_LEGS_COST"))
	Events.banner_requested.emit(&"ITEM_FALLING_TOOTH_NAME", &"ITEM_FALLING_TOOTH_BONUS", &"")
	assert_eq(banner.lines()[0], tr(&"ITEM_FALLING_TOOTH_NAME"), "a new request replaces the banner")
	assert_eq(banner.lines()[2], "")
	banner._process(Banner.DURATION + 0.1)
	assert_false(banner.is_showing())


func test_the_hurtbox_follows_a_changed_base_while_lucid() -> void:
	var lucid_size: float = Tuning.LUCIDITY.lucid_hurtbox_size
	assert_eq(_player.lucidity.live_tier, Lucidity.Tier.LUCID)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.HURTBOX_SIZE), lucid_size, 0.0001)
	_player.stats.set_base(StatBlock.Stat.HURTBOX_SIZE, 0.5)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.HURTBOX_SIZE), lucid_size, 0.0001, "still the Lucid size")
	_player.lucidity.set_value(50)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.HURTBOX_SIZE), 0.5, 0.0001, "the new base once out of Lucid")


func test_the_carrier_relays_the_events_of_the_player() -> void:
	watch_signals(_player.carrier)
	_player.health.set_forced_invulnerability(false)
	var info: DamageInfo = DamageInfo.from_bullet(1.0, Vector2.ZERO, DamageInfo.Source.DEBUG)
	_player.hurtbox.receive(info)
	assert_signal_emitted(_player.carrier, "hit_incoming")
	assert_signal_emitted_with_parameters(_player.carrier, "hit_taken", [1, int(DamageInfo.Source.DEBUG)])
	Events.room_cleared.emit(_room, 0)
	assert_signal_emitted(_player.carrier, "room_cleared")
	Input.action_press(&"move_left")
	await _harness.ticks(2)
	Input.action_press(&"dash")
	await _harness.ticks(2)
	Input.action_release(&"dash")
	var ended: bool = await _harness.until(func() -> bool: return get_signal_emit_count(_player.carrier, "dash_ended") > 0, 60)
	Input.action_release(&"move_left")
	assert_true(ended, "the dash of the player reached the carrier")


func test_stat_bounds_are_set_on_the_player() -> void:
	_player.stats.set_modifier(self, StatBlock.Stat.SHOT_SPEED, StatBlock.Kind.ADD_FLAT, 500.0)
	assert_lt(_player.stats.value_of(StatBlock.Stat.SHOT_SPEED), 60.0)
	_player.stats.set_modifier(self, StatBlock.Stat.MOVE_SPEED, StatBlock.Kind.ADD_PERCENT, -5.0)
	assert_gte(_player.stats.value_of(StatBlock.Stat.MOVE_SPEED), 1.0)
	_player.stats.set_modifier(self, StatBlock.Stat.DAMAGE, StatBlock.Kind.ADD_PERCENT, -5.0)
	assert_gte(_player.stats.value_of(StatBlock.Stat.DAMAGE), 0.0)
	_player.stats.set_modifier(self, StatBlock.Stat.FIRE_RATE, StatBlock.Kind.MULTIPLY, 0.0)
	assert_gte(_player.stats.value_of(StatBlock.Stat.FIRE_RATE), 0.5)
	_player.stats.clear_source(self)


func test_damage_is_floored_above_zero_and_the_shot_stays_valid() -> void:
	var source: RefCounted = RefCounted.new()
	_player.stats.set_modifier(source, StatBlock.Stat.DAMAGE, StatBlock.Kind.ADD_FLAT, -1000.0)
	assert_almost_eq(_player.stats.value_of(StatBlock.Stat.DAMAGE), Player.MIN_DAMAGE, 0.0001)
	assert_gt(_player._shot_params.damage, 0.0, "BulletManager would refuse a 0 damage shot")
	assert_almost_eq(_player._shot_params.damage, Player.MIN_DAMAGE, 0.0001)
