class_name RowRunner
extends AttackRunner
## ROW attack (Dictée): every `interval` seconds a sign (band and lit gap) shows for `telegraph` seconds at the top of the
## room, then a row of chalks appears there and falls with a gap to cross. The gap comes from the BOSS stream of the run.
## The first sign comes as soon as the runner starts. Cadence counts in clock x pace, the sign in clock only (it never
## goes under Tuning.COMBAT.min_telegraph), both freeze when the boss stops ticking its runners (fire_hold).

const TICK_EPSILON: float = 1e-6
## Where a row is born, below the top edge of the playable area (never inside the wall).
const SPAWN_OFFSET_TILES: float = 1.5
const SIGN_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_lullaby_telegraph.wav")

## Center of the gap of the last row announced, in tiles from the left of the playable area (NAN before the first).
var last_gap: float = NAN
var _stopped: bool = false
var _cycle_ticks_left: float = 0.0
var _sign_ticks_left: float = 0.0
var _sign_ticks_total: float = 0.0
var _sign: AttackSign
var _fired_rows: int = 0


func setup(boss: Boss, attack: BossAttack) -> void:
	super(boss, attack)


## Rows fired so far.
func fired_rows() -> int:
	return _fired_rows


func current_sign() -> AttackSign:
	return _sign if is_instance_valid(_sign) else null


func tick(clock_step: float, pace: float) -> void:
	if _stopped or _boss == null or _attack == null:
		return
	_cycle_ticks_left -= clock_step * pace
	if _sign_ticks_left > 0.0:
		_sign_ticks_left -= clock_step
		if _sign_ticks_left <= TICK_EPSILON:
			_sign_ticks_left = 0.0
			_fire_row()
		elif is_instance_valid(_sign):
			_sign.set_progress(1.0 - _sign_ticks_left / _sign_ticks_total)
	if _sign_ticks_left <= 0.0 and _cycle_ticks_left <= TICK_EPSILON and not _stopped:
		_start_sign()


func stop() -> void:
	_stopped = true
	_sign_ticks_left = 0.0
	if is_instance_valid(_sign):
		_sign.queue_free()
	_sign = null


func _start_sign() -> void:
	var arena: Rect2 = _boss.arena_px()
	var width_tiles: float = arena.size.x / Const.TILE_SIZE
	last_gap = ChalkPatterns.next_gap(_boss.draw_unit(), last_gap, width_tiles, _attack.gap_tiles, _attack.max_gap_shift_tiles)
	_cycle_ticks_left = _attack.interval * Engine.physics_ticks_per_second
	_sign_ticks_total = Telegraph.duration_for(_attack.telegraph, _boss.danger.telegraph_mult) * Engine.physics_ticks_per_second
	_sign_ticks_left = _sign_ticks_total
	var gap_left: float = arena.position.x + (last_gap - _attack.gap_tiles / 2.0) * Const.TILE_SIZE
	_sign = AttackSign.new()
	_sign.name = "RowSign"
	_sign.setup(
		Vector2(arena.position.x, arena.end.x),
		Vector2(gap_left, gap_left + _attack.gap_tiles * Const.TILE_SIZE),
		arena.position.y + SPAWN_OFFSET_TILES * Const.TILE_SIZE
	)
	_boss.add_sign(_sign)
	Audio.play_sfx(SIGN_SOUND)


func _fire_row() -> void:
	var arena: Rect2 = _boss.arena_px()
	var y: float = arena.position.y + SPAWN_OFFSET_TILES * Const.TILE_SIZE
	var speed: float = _attack.bullet_speed * _boss.danger.enemy_bullet_speed_mult # read now: bullets in flight keep theirs
	var chalks: Array[Vector2] = ChalkPatterns.row(
		arena.size.x / Const.TILE_SIZE, _attack.spacing_tiles, last_gap, _attack.gap_tiles, Tuning.COMBAT.enemy_bullet_radius
	)
	var fired: int = 0
	for chalk: Vector2 in chalks:
		if _boss.fire_bullet(Vector2(arena.position.x + chalk.x * Const.TILE_SIZE, y), Vector2.DOWN, speed):
			fired += 1
	_fired_rows += 1
	Log.debug("combat", "%s row %d fired %d/%d gap=%.2f" % [_boss.name, _fired_rows, fired, chalks.size(), last_gap])
	if is_instance_valid(_sign):
		_sign.queue_free()
	_sign = null
