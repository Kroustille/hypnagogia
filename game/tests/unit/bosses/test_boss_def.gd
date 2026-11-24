extends GutTest
## BossDef, BossPhase and BossAttack (story 6.1): the Professor's data, and what BossAttack.validate() refuses.

const PROFESSOR: BossDef = preload("res://data/bosses/professor.tres")


func _row() -> BossAttack:
	var attack: BossAttack = BossAttack.new()
	attack.kind = BossAttack.Kind.ROW
	attack.interval = 2.0
	attack.telegraph = 0.5
	attack.bullet_speed = 5.0
	attack.spacing_tiles = 0.75
	attack.gap_tiles = 5.0
	attack.max_gap_shift_tiles = 10.0
	return attack


func test_the_professor_has_the_gdd_values() -> void:
	assert_eq(PROFESSOR.id, &"professor")
	assert_eq(PROFESSOR.max_hp, 2500.0)
	assert_eq(PROFESSOR.body_size, Vector2(2.0, 2.0))
	assert_eq(PROFESSOR.hurtbox_size, Vector2(2.5, 2.5))
	assert_gt(PROFESSOR.contact_size.x, PROFESSOR.body_size.x + 0.125, "the contact reaches past the body (deferred: contact zones)")
	assert_not_null(PROFESSOR.scene)
	assert_eq(PROFESSOR.announce_duration, 1.5)


func test_the_phases_are_sorted_by_decreasing_share_and_the_first_applies_from_the_start() -> void:
	assert_gte(PROFESSOR.phases.size(), 1)
	assert_eq(PROFESSOR.phases[0].hp_from, 1.0)
	for i: int in range(1, PROFESSOR.phases.size()):
		assert_lt(PROFESSOR.phases[i].hp_from, PROFESSOR.phases[i - 1].hp_from)


func test_the_dictee_is_one_valid_row() -> void:
	var attacks: Array[BossAttack] = PROFESSOR.phases[0].attacks()
	assert_eq(PROFESSOR.phases[0].title_key, &"BOSS_PROFESSOR_PHASE_1")
	assert_eq(attacks.size(), 1)
	assert_eq(attacks[0].kind, BossAttack.Kind.ROW)
	assert_eq(attacks[0].validate(), "")
	assert_eq(attacks[0].interval, 2.0)
	assert_eq(attacks[0].bullet_speed, 5.0)
	assert_eq(attacks[0].gap_tiles, 5.0)
	assert_eq(attacks[0].max_gap_shift_tiles, 10.0)
	assert_gte(attacks[0].telegraph, Tuning.COMBAT.min_telegraph)


func test_the_kind_values_are_explicit() -> void:
	assert_eq(BossAttack.Kind.ROW, 0, "serialized in .tres files: never renumbered")


func test_a_valid_row_validates() -> void:
	assert_eq(_row().validate(), "")


func test_validate_refuses_the_impossible_values() -> void:
	var cases: Dictionary = {
		"interval": [0.0, -1.0, NAN, INF],
		"bullet_speed": [0.0, -2.0, NAN, INF, 60.0],
		"spacing_tiles": [0.0, -0.5, NAN, INF],
		"gap_tiles": [0.0, -5.0, NAN, INF],
		"max_gap_shift_tiles": [0.0, -1.0, NAN, INF],
		"telegraph": [0.0, 0.39, -0.5, NAN, INF],
	}
	for field: String in cases:
		for value: float in cases[field]:
			var attack: BossAttack = _row()
			attack.set(field, value)
			assert_ne(attack.validate(), "", "%s = %s is refused" % [field, value])


func test_validate_refuses_a_telegraph_longer_than_the_interval_and_an_unknown_kind() -> void:
	var attack: BossAttack = _row()
	attack.telegraph = 2.5
	assert_ne(attack.validate(), "")
	attack = _row()
	attack.kind = 99 as BossAttack.Kind
	assert_ne(attack.validate(), "")


func test_the_runner_factory_gives_a_row_runner_and_refuses_an_unknown_kind() -> void:
	assert_true(AttackRunner.make(_row()) is RowRunner)
	var attack: BossAttack = _row()
	attack.kind = 99 as BossAttack.Kind
	assert_null(AttackRunner.make(attack))
	assert_null(AttackRunner.make(null))
	assert_push_error_count(2)


func test_the_telegraph_rule_is_shared() -> void:
	assert_eq(Telegraph.duration_for(0.5, 1.0), 0.5)
	assert_eq(Telegraph.duration_for(0.5, 0.85), 0.5 * 0.85)
	assert_eq(Telegraph.duration_for(0.5, 0.5), Tuning.COMBAT.min_telegraph, "the minimum wins")
	assert_eq(Telegraph.duration_for(NAN, 1.0), Tuning.COMBAT.min_telegraph)


func test_a_ruler_that_could_skip_the_player_is_refused() -> void:
	var ruler: BossAttack = BossAttack.new()
	ruler.kind = BossAttack.Kind.RULER
	ruler.interval = 4.0
	ruler.telegraph = 0.5
	ruler.bullet_speed = 5.0
	ruler.thickness_tiles = 0.5
	ruler.sweep_speed = 12.0
	assert_eq(ruler.validate(), "")
	ruler.sweep_speed = 30.0 # 0.5 tile per tick
	assert_ne(ruler.validate(), "")
	ruler.sweep_speed = 29.5
	assert_eq(ruler.validate(), "")


func test_the_professor_pays_ten_shards() -> void:
	assert_eq(PROFESSOR.reward_shards, 10)
