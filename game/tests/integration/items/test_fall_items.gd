extends GutTest
## Paper wings and free fall in a real room (story 5.6). Room: a pit band on frame cells 21 and 22 (x 336 to 368 px).

const ROOM: String = "res://tests/fixtures/rooms/pit_band.tscn"
const WINGS: ItemDef = preload("res://data/items/paper_wings.tres")
const FREE_FALL: ItemDef = preload("res://data/items/free_fall.tres")
const ROW_Y: float = 168.0
const CELL_20_X: float = 328.0
const OVER_PIT_X: float = 344.0

var _harness: RoomHarness
var _player: Player


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	_player = _harness.player
	_player.health.set_forced_invulnerability(false)


func after_each() -> void:
	_harness.release()


func _hit(source: DamageInfo.Source = DamageInfo.Source.ENEMY_BULLET, amount: float = 2.0) -> bool:
	var info: DamageInfo = DamageInfo.new()
	info.amount = amount
	info.source = source
	return _player.hurtbox.receive(info)


func _fly_over_the_pit() -> void:
	_player.global_position = Vector2(CELL_20_X, ROW_Y)
	await _harness.ticks(2)
	_player.global_position = Vector2(OVER_PIT_X, ROW_Y)
	_player.velocity = Vector2.ZERO
	await _harness.ticks(2)


func test_wings_carry_the_player_over_the_pit() -> void:
	_player.carrier.acquire(WINGS)
	var hearts: int = _player.health.half_hearts
	await _fly_over_the_pit()
	assert_almost_eq(_player.global_position.x, OVER_PIT_X, 1.0, "still above the pit")
	assert_eq(_player.health.half_hearts, hearts)


func test_a_hit_over_the_pit_drops_the_player_back_for_that_hit_only() -> void:
	_player.carrier.acquire(WINGS)
	await _fly_over_the_pit()
	var hearts: int = _player.health.half_hearts
	assert_true(_hit(DamageInfo.Source.ENEMY_BULLET, 1.0))
	assert_eq(_player.health.half_hearts, hearts - 1, "the hit, and no fall damage")
	assert_lt(_player.global_position.x, 336.0, "back on the last safe cell")
	assert_almost_eq(_player.global_position.x, CELL_20_X, 1.0)
	await _harness.ticks(3)
	assert_eq(_player.health.half_hearts, hearts - 1)


func test_the_flight_comes_back_after_three_seconds() -> void:
	_player.carrier.acquire(WINGS)
	_hit()
	assert_false(_player.can_fly_over_pits())
	await _harness.ticks(185)
	assert_true(_player.can_fly_over_pits())


func test_losing_the_wings_over_a_pit_makes_the_player_fall_normally() -> void:
	var owned: OwnedItem = _player.carrier.acquire(WINGS)
	await _fly_over_the_pit()
	var hearts: int = _player.health.half_hearts
	_player.carrier.loadout.remove(owned)
	await _harness.ticks(3)
	assert_lt(_player.global_position.x, 336.0, "fell back")
	assert_eq(_player.health.half_hearts, hearts - 1, "the fall hit")


func test_free_fall_bonus_reaches_the_shots_and_a_real_hit_costs_half_a_heart_more() -> void:
	_player.carrier.acquire(FREE_FALL)
	var base: float = _player.stats.base_of(StatBlock.Stat.DAMAGE)
	await _harness.ticks(125)
	assert_almost_eq(_player._shot_params.damage, base * 1.10, 0.001)
	var hearts: int = _player.health.half_hearts
	_hit(DamageInfo.Source.ENEMY_BULLET, 1.0)
	assert_eq(_player.health.half_hearts, hearts - 2)
	assert_almost_eq(_player._shot_params.damage, base, 0.001, "back to zero")


func test_free_fall_extra_goes_through_the_armor_first() -> void:
	_player.carrier.acquire(FREE_FALL)
	await _harness.ticks(65)
	_player.health.add_armor(2)
	var hearts: int = _player.health.half_hearts
	_hit(DamageInfo.Source.ENEMY_BULLET, 1.0)
	assert_eq(_player.health.armor, 0)
	assert_eq(_player.health.half_hearts, hearts)


func test_the_fall_into_a_pit_counts_as_a_hit_for_free_fall() -> void:
	_player.carrier.acquire(FREE_FALL)
	_player.global_position = Vector2(CELL_20_X, ROW_Y)
	await _harness.ticks(125)
	var hearts: int = _player.health.half_hearts
	_player.global_position = Vector2(OVER_PIT_X, ROW_Y)
	await _harness.ticks(2)
	assert_eq(_player.health.half_hearts, hearts - 2, "the fall hit plus the extra half-heart")
	assert_eq(_player.stats.value_of(StatBlock.Stat.DAMAGE), _player.stats.base_of(StatBlock.Stat.DAMAGE))


func test_a_refused_hit_costs_nothing_and_keeps_the_bonus() -> void:
	_player.carrier.acquire(FREE_FALL)
	await _harness.ticks(65)
	_player.health.set_forced_invulnerability(true)
	assert_false(_hit())
	_player.health.set_forced_invulnerability(false)
	var info: DamageInfo = DamageInfo.new()
	info.amount = 1.0
	_player.carrier.hit_incoming.emit(info)
	assert_eq(info.amount, 2.0, "the bonus survived the refused hit")


func test_an_effect_that_cancels_the_hit_refuses_it_cleanly() -> void:
	var canceller: Callable = func(info: DamageInfo) -> void: info.amount = 0.0
	_player.carrier.hit_incoming.connect(canceller)
	var hearts: int = _player.health.half_hearts
	assert_false(_hit(DamageInfo.Source.ENEMY_BULLET, 1.0))
	assert_eq(_player.health.half_hearts, hearts)
	assert_false(_player.health.is_hit_invulnerable())
	_player.carrier.hit_incoming.disconnect(canceller)


func test_the_wings_fall_costs_nothing_on_a_vulnerable_player() -> void:
	var owned: OwnedItem = _player.carrier.acquire(WINGS)
	await _fly_over_the_pit()
	assert_false(_player.health.is_invulnerable(), "no hit before: nothing protects the player")
	var hearts: int = _player.health.half_hearts
	var hits: Array[int] = []
	var on_hit: Callable = func(lost: int, _source: int) -> void: hits.append(lost)
	Events.player_hit.connect(on_hit)
	_player.stats.clear_modifier(owned.effect.modifier_source(), StatBlock.Stat.CAN_FLY_OVER_PITS)
	assert_true(_player.fall_if_over_pit())
	Events.player_hit.disconnect(on_hit)
	assert_almost_eq(_player.global_position.x, CELL_20_X, 1.0, "back on the last safe cell")
	assert_eq(_player.health.half_hearts, hearts, "the free fall costs no heart")
	assert_true(hits.is_empty(), "no player_hit")
