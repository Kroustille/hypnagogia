extends GutTest
## The Professor's phases and the length of the fight (story 6.2, AC1, AC6, AC7).

const PROFESSOR: BossDef = preload("res://data/bosses/professor.tres")


func test_the_three_phases_start_at_the_thresholds_of_the_gdd() -> void:
	assert_eq(PROFESSOR.phases.size(), 3)
	assert_eq(PROFESSOR.phases[0].hp_from, 1.0)
	assert_eq(PROFESSOR.phases[1].hp_from, 0.66)
	assert_eq(PROFESSOR.phases[2].hp_from, 0.33)
	assert_eq(PROFESSOR.phases[1].title_key, &"BOSS_PROFESSOR_PHASE_2")
	assert_eq(PROFESSOR.phases[2].title_key, &"BOSS_PROFESSOR_PHASE_3")


func test_every_phase_and_attack_of_the_professor_is_valid() -> void:
	for phase: BossPhase in PROFESSOR.phases:
		assert_eq(phase.validate(), "", "phase %s" % phase.title_key)


func test_calcul_mental_has_a_four_arm_spiral_and_a_three_chalk_fan() -> void:
	var attacks: Array[BossAttack] = PROFESSOR.phases[1].attacks()
	assert_eq(attacks.size(), 2)
	var spiral: BossAttack = attacks[0]
	assert_eq(spiral.kind, BossAttack.Kind.SPIRAL)
	assert_eq(spiral.arms, 4)
	assert_eq(spiral.rotation_deg_per_s, 60.0)
	assert_eq(spiral.emit_interval, 0.2)
	assert_eq(spiral.bullet_speed, 5.0)
	assert_eq(spiral.telegraph, 0.5)
	var aimed: BossAttack = attacks[1]
	assert_eq(aimed.kind, BossAttack.Kind.AIMED)
	assert_eq(aimed.bullet_count, 3)
	assert_eq(aimed.spread_deg, 20.0)
	assert_eq(aimed.interval, 3.0)
	assert_eq(aimed.telegraph, 0.5)
	assert_false(PROFESSOR.phases[1].alternates())


func test_the_examen_final_alternates_the_dictee_and_the_calcul_mental_and_adds_the_ruler() -> void:
	var phase: BossPhase = PROFESSOR.phases[2]
	assert_true(phase.alternates())
	assert_eq(phase.alternate_seconds, 8.0)
	assert_eq(phase.groups.size(), 2)
	assert_eq(phase.group_attacks(0)[0].kind, BossAttack.Kind.ROW, "starts with the Dictée")
	assert_eq(phase.group_attacks(1)[0].kind, BossAttack.Kind.SPIRAL)
	assert_eq(phase.extras.size(), 1)
	var ruler: BossAttack = phase.extras[0]
	assert_eq(ruler.kind, BossAttack.Kind.RULER)
	assert_eq(ruler.interval, 7.0)
	assert_eq(ruler.telegraph, 0.8)
	assert_eq(ruler.thickness_tiles, 1.0)
	assert_eq(ruler.sweep_speed, 8.0)
	assert_eq(PROFESSOR.phases[0].extras.size(), 0)
	assert_eq(PROFESSOR.phases[1].extras.size(), 0, "no ruler before the Examen final")


func test_the_ruler_telegraph_stays_above_the_floor_under_every_danger_factor() -> void:
	var ruler: BossAttack = PROFESSOR.phases[2].extras[0]
	assert_gte(Telegraph.duration_for(ruler.telegraph, 0.85), 0.4, "Abandon")
	assert_gte(Telegraph.duration_for(ruler.telegraph, 0.1), Tuning.COMBAT.min_telegraph)


func test_the_reference_build_kills_the_professor_in_about_seventy_five_seconds() -> void:
	var dps: float = Tuning.SHOT.damage * 1.3 * Tuning.SHOT.fire_rate * 0.7 # +30 %, 70 % of the shots land
	var shooting: float = PROFESSOR.max_hp / dps
	var total: float = shooting + (PROFESSOR.phases.size() - 1) * PROFESSOR.announce_duration
	assert_between(total, 65.0, 85.0, "theoretical duration %.1f s" % total)


func test_a_new_kind_never_renumbers_the_old_ones() -> void:
	assert_eq(BossAttack.Kind.ROW, 0)
	assert_eq(BossAttack.Kind.SPIRAL, 1)
	assert_eq(BossAttack.Kind.AIMED, 2)
	assert_eq(BossAttack.Kind.RULER, 3)
	assert_eq(DamageInfo.Source.RULER, 6)
	assert_eq(str(DamageInfo.Source.find_key(6)), "RULER", "the telemetry cause is read from the enum")


func test_validate_refuses_bad_new_fields() -> void:
	var spiral: BossAttack = BossAttack.new()
	spiral.kind = BossAttack.Kind.SPIRAL
	spiral.telegraph = 0.5
	spiral.bullet_speed = 5.0
	spiral.arms = 4
	spiral.rotation_deg_per_s = 60.0
	spiral.emit_interval = 0.2
	assert_eq(spiral.validate(), "")
	spiral.arms = 0
	assert_ne(spiral.validate(), "")
	spiral.arms = 4
	spiral.emit_interval = 0.0
	assert_ne(spiral.validate(), "")
	var aimed: BossAttack = BossAttack.new()
	aimed.kind = BossAttack.Kind.AIMED
	aimed.interval = 3.0
	aimed.telegraph = 0.5
	aimed.bullet_speed = 6.0
	aimed.bullet_count = 3
	aimed.spread_deg = 20.0
	assert_eq(aimed.validate(), "")
	aimed.bullet_count = 0
	assert_ne(aimed.validate(), "")
	aimed.bullet_count = 3
	aimed.spread_deg = 200.0
	assert_ne(aimed.validate(), "")
	var ruler: BossAttack = PROFESSOR.phases[2].extras[0].duplicate() as BossAttack
	assert_eq(ruler.validate(), "")
	ruler.sweep_speed = 0.0
	assert_ne(ruler.validate(), "")
	ruler.sweep_speed = 8.0
	ruler.thickness_tiles = 0.0
	assert_ne(ruler.validate(), "")
	ruler.thickness_tiles = 1.0
	ruler.telegraph = 0.1
	assert_ne(ruler.validate(), "", "under the minimum telegraph")


func test_a_phase_that_alternates_needs_two_groups() -> void:
	var phase: BossPhase = BossPhase.new()
	phase.alternate_seconds = 8.0
	assert_ne(phase.validate(), "")
	phase.alternate_seconds = NAN
	assert_ne(phase.validate(), "")
