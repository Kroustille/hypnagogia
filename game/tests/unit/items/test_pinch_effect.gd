extends GutTest
## Pinch yourself (story 5.3): +25 lucidity for half a heart, never the armor, refused at the last half-heart.

const PINCH: ConsumableDef = preload("res://data/consumables/pinch.tres")

var _player: Player


func before_each() -> void:
	_player = PlayerFactory.make(self)


func after_each() -> void:
	_player.free()


func _use() -> BuildCarrier.UseResult:
	_player.carrier.acquire_consumable(PINCH)
	return _player.carrier.use_consumable()


func test_it_gives_lucidity_for_half_a_heart() -> void:
	_player.lucidity.set_value(40)
	var hearts: int = _player.health.half_hearts
	assert_eq(_use(), BuildCarrier.UseResult.USED)
	assert_eq(_player.lucidity.value, 65)
	assert_eq(_player.health.half_hearts, hearts - 1)
	assert_null(_player.carrier.loadout.consumable, "used up")


func test_the_gain_is_capped_at_the_maximum() -> void:
	_player.lucidity.set_value(90)
	_use()
	assert_eq(_player.lucidity.value, Tuning.LUCIDITY.max_value)


func test_armor_is_never_touched() -> void:
	_player.health.add_armor(2)
	_use()
	assert_eq(_player.health.armor, 2)


func test_it_is_not_a_hit() -> void:
	var hits: Array[int] = []
	var listener: Callable = func(damage: int, _source: int) -> void: hits.append(damage)
	Events.player_hit.connect(listener)
	_player.health.set_forced_invulnerability(true)
	var hearts: int = _player.health.half_hearts
	_use()
	Events.player_hit.disconnect(listener)
	assert_eq(hits.size(), 0, "no player_hit")
	assert_eq(_player.health.half_hearts, hearts - 1, "not blocked by invulnerability")
	assert_false(_player.health.is_hit_invulnerable(), "no invulnerability window started")


func test_it_is_refused_at_the_last_half_heart_and_nothing_is_spent() -> void:
	_player.health.lose_half_hearts_unarmored(_player.health.half_hearts - 1)
	assert_eq(_player.health.half_hearts, 1)
	_player.lucidity.set_value(40)
	assert_eq(_use(), BuildCarrier.UseResult.REFUSED)
	assert_eq(_player.health.half_hearts, 1)
	assert_eq(_player.lucidity.value, 40)
	assert_eq(_player.carrier.loadout.consumable, PINCH, "kept")
	assert_false(_player.health.is_dead())


func test_losing_half_hearts_never_kills() -> void:
	var lost: int = _player.health.lose_half_hearts_unarmored(50)
	assert_eq(lost, _player.health.max_half_hearts - 1)
	assert_eq(_player.health.half_hearts, 1)
	assert_eq(_player.health.lose_half_hearts_unarmored(1), 0)


func test_nothing_happens_without_a_consumable() -> void:
	assert_eq(_player.carrier.use_consumable(), BuildCarrier.UseResult.NONE)
