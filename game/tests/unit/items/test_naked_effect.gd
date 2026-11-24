extends GutTest
## Naked in public (story 5.9): the armor goes at once and cannot come back while the item is held.

const NAKED: ItemDef = preload("res://data/items/naked_in_public.tres")

var _player: Player


func before_each() -> void:
	_player = PlayerFactory.make(self)


func after_each() -> void:
	_player.free()


func test_the_armor_is_lost_on_taking_it_without_a_hit() -> void:
	assert_true(_player.health.add_armor(2))
	watch_signals(Events)
	var changes: Array[int] = [0]
	_player.health.changed.connect(func() -> void: changes[0] += 1)
	_player.carrier.acquire(NAKED)
	assert_eq(_player.health.armor, 0)
	assert_eq(changes[0], 1, "the health changed once")
	assert_signal_not_emitted(Events, "player_hit")
	assert_false(_player.health.is_hit_invulnerable(), "not a hit: no invulnerability")


func test_no_armor_can_be_gained_while_held_and_it_comes_back_after() -> void:
	var owned: OwnedItem = _player.carrier.acquire(NAKED)
	assert_true(_player.health.armor_blocked)
	assert_false(_player.health.add_armor(1))
	assert_false(_player.health.can_add_armor())
	assert_eq(_player.health.armor, 0)
	_player.carrier.loadout.remove(owned)
	assert_false(_player.health.armor_blocked)
	assert_true(_player.health.add_armor(1))


func test_leaving_and_entering_the_tree_does_not_empty_the_armor_again() -> void:
	_player.carrier.acquire(NAKED)
	var parent: Node = _player.get_parent()
	parent.remove_child(_player)
	assert_false(_player.health.armor_blocked, "detached with the carrier")
	parent.add_child(_player)
	assert_true(_player.health.armor_blocked, "attached again")


func test_the_hold_lasts_ninety_ticks() -> void:
	assert_eq(NAKED.params[&"hold_seconds"] * Engine.physics_ticks_per_second, 90.0)
