extends GutTest
## ShotPattern (story 5.10, AC 1 and 4): the directions of a shot, from the stats alone.


func _stats(rear: float, pierce: float = 0.0) -> StatBlock:
	var stats: StatBlock = StatBlock.new()
	stats.set_base(StatBlock.Stat.REAR_SHOT, rear)
	stats.set_base(StatBlock.Stat.PIERCE, pierce)
	return stats


func test_without_the_mirror_a_shot_has_one_direction() -> void:
	var found: Array[Vector2] = ShotPattern.directions(Vector2.RIGHT, _stats(0.0))
	assert_eq(found, [Vector2.RIGHT] as Array[Vector2])


func test_with_the_mirror_a_second_shot_goes_the_opposite_way() -> void:
	var aim: Vector2 = Vector2(0.6, 0.8)
	var found: Array[Vector2] = ShotPattern.directions(aim, _stats(1.0))
	assert_eq(found, [aim, -aim] as Array[Vector2], "front first, then behind")


func test_piercing_is_not_part_of_the_pattern() -> void:
	var plain: Array[Vector2] = ShotPattern.directions(Vector2.UP, _stats(1.0, 0.0))
	var piercing: Array[Vector2] = ShotPattern.directions(Vector2.UP, _stats(1.0, 1.0))
	assert_eq(piercing, plain, "the same number and directions: a hostile bullet never pierces")


func test_no_aim_gives_no_shot() -> void:
	assert_eq(ShotPattern.directions(Vector2.ZERO, _stats(1.0)).size(), 0)
