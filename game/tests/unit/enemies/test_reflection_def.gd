extends GutTest
## reflection.tres (story 5.10, AC 3 and 6): valid data, the behavior read from it, the 3.5 contact rule.

const DEF: ReflectionDef = preload("res://data/enemies/reflection.tres")
const ONSET: FloorDef = preload("res://data/floors/onset.tres")
const CONTACT_MARGIN_TILES: float = 0.125


func test_the_definition_is_a_valid_shooter() -> void:
	assert_not_null(DEF)
	assert_not_null(DEF.scene)
	assert_eq(DEF.id, &"reflection")
	assert_eq(DEF.max_hp, 60.0)
	assert_gte(DEF.bullet_count, 1)
	assert_gt(DEF.bullet_speed, 0.0)
	assert_gt(DEF.fire_interval, 0.0)


func test_the_behavior_comes_from_the_data() -> void:
	assert_eq(DEF.movement, ReflectionDef.Movement.KEEP_DISTANCE)
	assert_gt(DEF.preferred_distance, 0.0)
	assert_gt(DEF.move_speed, 0.0)


func test_the_contact_zone_exceeds_the_body_by_the_margin() -> void:
	assert_gt(DEF.contact_size.x, DEF.body_size.x + CONTACT_MARGIN_TILES)
	assert_gt(DEF.contact_size.y, DEF.body_size.y + CONTACT_MARGIN_TILES)


func test_its_telegraph_is_at_least_the_minimum() -> void:
	assert_gte(DEF.telegraph_duration, Tuning.COMBAT.min_telegraph)


func test_the_first_floor_factor_is_one() -> void:
	assert_eq(ONSET.hp_factor, 1.0)