extends GutTest
## The shards of RunState (story 5.4): never negative, a refused payment changes nothing.


func test_shards_add_up_and_a_payment_takes_them_back() -> void:
	var state: RunState = RunState.new()
	state.add_shards(5)
	state.add_shards(2)
	assert_eq(state.shards, 7)
	assert_true(state.spend_shards(3))
	assert_eq(state.shards, 4)


func test_a_payment_beyond_the_balance_is_refused_and_changes_nothing() -> void:
	var state: RunState = RunState.new()
	state.add_shards(2)
	assert_false(state.spend_shards(3))
	assert_eq(state.shards, 2)
	assert_true(state.spend_shards(2))
	assert_eq(state.shards, 0)


func test_negative_amounts_never_make_the_balance_move() -> void:
	var state: RunState = RunState.new()
	state.add_shards(4)
	state.add_shards(-10)
	assert_eq(state.shards, 4)
	assert_false(state.spend_shards(-1))
	assert_eq(state.shards, 4)
