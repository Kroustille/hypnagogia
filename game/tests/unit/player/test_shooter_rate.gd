extends GutTest
## Shooter.set_fire_rate (story 5.3): the period follows the rate, no free shot, no longer wait.

var _shooter: Shooter


func before_each() -> void:
	_shooter = Shooter.new(Tuning.SHOT)


func _shots_in(ticks: int) -> int:
	var shots: int = 0
	for i: int in ticks:
		if _shooter.tick(1.0, true, false):
			shots += 1
	return shots


func test_a_faster_rate_gives_more_shots() -> void:
	var base: int = _shots_in(600)
	_shooter = Shooter.new(Tuning.SHOT)
	_shooter.set_fire_rate(Tuning.SHOT.fire_rate * 2.0)
	assert_between(_shots_in(600), base * 2 - 1, base * 2 + 1)


func test_a_slower_rate_gives_fewer_shots() -> void:
	_shooter.set_fire_rate(Tuning.SHOT.fire_rate * 0.5)
	assert_between(_shots_in(600), int(Tuning.SHOT.fire_rate * 5.0) - 1, int(Tuning.SHOT.fire_rate * 5.0) + 1)


func test_a_cooldown_in_progress_is_not_made_longer() -> void:
	assert_true(_shooter.tick(1.0, true, false), "first shot")
	_shooter.set_fire_rate(Tuning.SHOT.fire_rate * 0.25) # a much longer period
	var waited: int = 0
	while not _shooter.tick(1.0, true, false) and waited < 600:
		waited += 1
	var old_period: float = Engine.physics_ticks_per_second / Tuning.SHOT.fire_rate
	assert_lte(float(waited), old_period, "the shot due under the old period still comes on time")


func test_no_free_shot_when_the_rate_rises() -> void:
	assert_true(_shooter.tick(1.0, true, false))
	_shooter.set_fire_rate(Tuning.SHOT.fire_rate * 3.0)
	assert_false(_shooter.tick(1.0, true, false), "the next shot is not immediate")
