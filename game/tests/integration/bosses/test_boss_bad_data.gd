extends GutTest
## A boss with faulty data stays safe (story 6.3 review): a null phase makes it inert, a null attack is skipped.
## The boss is a LenientProfessor: its asserts are muted (the data error is still logged), so the test sees the aftermath.

const BOSS_ROOM: String = "res://rooms/pool/onset/onset_boss_001.tscn"
const PROFESSOR: BossDef = preload("res://data/bosses/professor.tres")

var _harness: RoomHarness


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(BOSS_ROOM)


func after_each() -> void:
	_harness.release()


## A boss of the def, put in the room like Room.spawn_enemy() would (without its refusal assert).
func _make_boss(def: BossDef) -> Boss:
	var node: Node = PROFESSOR.scene.instantiate()
	node.set_script(LenientProfessor)
	var boss: Boss = node as Boss
	var room: Room = _harness.room
	boss.setup(def, _harness.player, _harness.player.hurtbox, room.enemy_bullets(), room.danger, room._nav)
	boss.bind_room(room, _harness.run.rng, 0)
	boss.position = Vector2(300.0, 100.0)
	room.get_node("%Enemies").add_child(boss)
	return boss


func test_a_null_phase_leaves_the_boss_inert_without_a_script_error() -> void:
	await _harness.ticks(2)
	var def: BossDef = PROFESSOR.duplicate() as BossDef
	def.phases = [PROFESSOR.phases[0], null]
	var boss: Boss = _make_boss(def)
	assert_eq(boss.process_mode, Node.PROCESS_MODE_DISABLED, "inert")
	await _harness.ticks(120)
	assert_false(boss.is_fighting())
	assert_true(boss.runners().is_empty())
	assert_push_error_count(1)


func test_a_null_attack_is_skipped_and_the_other_attacks_of_the_phase_start() -> void:
	await _harness.ticks(2)
	var phase: BossPhase = PROFESSOR.phases[0].duplicate() as BossPhase
	phase.extras = [null]
	var def: BossDef = PROFESSOR.duplicate() as BossDef
	def.announce_duration = 0.0
	def.phases = [phase]
	def.extra_attack = null
	var boss: Boss = _make_boss(def)
	await _harness.until(func() -> bool: return boss.is_fighting(), 60)
	await _harness.ticks(2)
	assert_gte(boss.runners().size(), 1, "the real attack runs")
	assert_push_error_count(2) # the data problem at set-up, the skipped attack
