class_name RulerRunner
extends AttackRunner
## RULER attack (Examen final): every `interval` seconds a bar sweeps the room. 0.8 s before (`telegraph`, never under the
## floor of Tuning.COMBAT.min_telegraph), a rectangle shows where the bar starts and arrows show its way; then a Ruler
## is launched. The way is drawn in the BOSS stream. The first sweep comes `interval` seconds after the runner starts. A ruler
## already launched is not kept when the runner stops. Cadence in clock x pace, sign in clock only.

const TICK_EPSILON: float = 1e-6
const ARROW_LENGTH_TILES: float = 4.0
const ARROW_ROWS: int = 3
const SIGN_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_lullaby_telegraph.wav")

var _stopped: bool = false
var _cycle_ticks_left: float = 0.0
var _sign_ticks_left: float = 0.0
var _sign_ticks_total: float = 0.0
var _signs: Array[AttackSign] = []
var _left_to_right: bool = true
var _ruler: Ruler
var _launched: int = 0


func setup(boss: Boss, attack: BossAttack) -> void:
	super(boss, attack)
	var first_sign: float = maxf(attack.interval - attack.telegraph, 0.0)
	_cycle_ticks_left = first_sign * Engine.physics_ticks_per_second


func launched() -> int:
	return _launched


func current_ruler() -> Ruler:
	return _ruler if is_instance_valid(_ruler) else null


## The signs on screen (the start rectangle, then the arrows).
func current_signs() -> Array[AttackSign]:
	var found: Array[AttackSign] = []
	for sign_node: AttackSign in _signs:
		if is_instance_valid(sign_node):
			found.append(sign_node)
	return found


func tick(clock_step: float, pace: float) -> void:
	if _stopped or _boss == null or _attack == null:
		return
	_cycle_ticks_left -= clock_step * pace
	if _sign_ticks_left > 0.0:
		_sign_ticks_left -= clock_step
		if _sign_ticks_left <= TICK_EPSILON:
			_sign_ticks_left = 0.0
			_launch()
		else:
			for sign_node: AttackSign in current_signs():
				sign_node.set_progress(1.0 - _sign_ticks_left / _sign_ticks_total)
	if _sign_ticks_left <= 0.0 and _cycle_ticks_left <= TICK_EPSILON and not _stopped:
		_start_sign()


func stop() -> void:
	_stopped = true
	_sign_ticks_left = 0.0
	_clear_signs()
	if is_instance_valid(_ruler):
		_ruler.dismiss()
	_ruler = null


func _start_sign() -> void:
	_left_to_right = _boss.draw_unit() < 0.5
	_cycle_ticks_left = _attack.interval * Engine.physics_ticks_per_second
	_sign_ticks_total = Telegraph.duration_for(_attack.telegraph, _boss.danger.telegraph_mult) * Engine.physics_ticks_per_second
	_sign_ticks_left = _sign_ticks_total
	var arena: Rect2 = _boss.arena_px()
	var thickness: float = _attack.thickness_tiles * Const.TILE_SIZE
	var way: float = 1.0 if _left_to_right else -1.0
	var start_x: float = arena.position.x if _left_to_right else arena.end.x - thickness
	var band: AttackSign = AttackSign.new()
	band.name = "RulerSign"
	band.setup_band(Rect2(start_x, arena.position.y, thickness, arena.size.y))
	_add_sign(band)
	var edge_x: float = arena.position.x + thickness if _left_to_right else arena.end.x - thickness
	for i: int in ARROW_ROWS:
		var y: float = arena.position.y + arena.size.y * (i + 1.0) / (ARROW_ROWS + 1.0)
		var arrow: AttackSign = AttackSign.new()
		arrow.name = "RulerArrow%d" % i
		arrow.setup_arrow(Vector2(edge_x, y), Vector2(edge_x + way * ARROW_LENGTH_TILES * Const.TILE_SIZE, y))
		_add_sign(arrow)
	Audio.play_sfx(SIGN_SOUND)


func _add_sign(sign_node: AttackSign) -> void:
	_signs.append(sign_node)
	_boss.add_sign(sign_node)


func _clear_signs() -> void:
	for sign_node: AttackSign in _signs:
		if is_instance_valid(sign_node):
			sign_node.queue_free()
	_signs.clear()


func _launch() -> void:
	_clear_signs()
	_ruler = Ruler.new()
	_ruler.launch(_boss, _boss.arena_px(), _left_to_right, _attack.thickness_tiles, _attack.sweep_speed)
	_launched += 1
	Log.debug("combat", "%s ruler %d launched left_to_right=%s" % [_boss.name, _launched, _left_to_right])
