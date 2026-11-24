class_name AimedRunner
extends AttackRunner
## AIMED attack (Calcul mental): every `interval` seconds a line shows from the boss toward the player for `telegraph`
## seconds (it follows the player), then a fan of `bullet_count` chalks, `spread_deg` between the outer ones, leaves the
## boss centered on where the player is at that moment (not at the start of the sign, like ShooterEnemy). The first sign
## comes as soon as the runner starts. Cadence in clock x pace, sign in clock only.

const TICK_EPSILON: float = 1e-6
const SIGN_LENGTH_TILES: float = 6.0
const SIGN_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_lullaby_telegraph.wav")

var _stopped: bool = false
var _cycle_ticks_left: float = 0.0
var _sign_ticks_left: float = 0.0
var _sign_ticks_total: float = 0.0
var _sign: AttackSign
var _fired_fans: int = 0


func fired_fans() -> int:
	return _fired_fans


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
			_fire_fan()
		elif is_instance_valid(_sign):
			_sign.set_progress(1.0 - _sign_ticks_left / _sign_ticks_total)
			_sign.set_arrow_end(_arrow_end())
	if _sign_ticks_left <= 0.0 and _cycle_ticks_left <= TICK_EPSILON and not _stopped:
		_start_sign()


func stop() -> void:
	_stopped = true
	_sign_ticks_left = 0.0
	_clear_sign()


func _arrow_end() -> Vector2:
	var origin: Vector2 = _boss.room_position()
	var to: Vector2 = _boss.target_room_position() - origin
	if to.length_squared() < 1e-6:
		return origin
	return origin + to.normalized() * minf(to.length(), SIGN_LENGTH_TILES * Const.TILE_SIZE)


func _start_sign() -> void:
	_cycle_ticks_left = _attack.interval * Engine.physics_ticks_per_second
	_sign_ticks_total = Telegraph.duration_for(_attack.telegraph, _boss.danger.telegraph_mult) * Engine.physics_ticks_per_second
	_sign_ticks_left = _sign_ticks_total
	_sign = AttackSign.new()
	_sign.name = "AimedSign"
	_sign.setup_arrow(_boss.room_position(), _arrow_end())
	_boss.add_sign(_sign)
	Audio.play_sfx(SIGN_SOUND)


func _clear_sign() -> void:
	if is_instance_valid(_sign):
		_sign.queue_free()
	_sign = null


func _fire_fan() -> void:
	var origin: Vector2 = _boss.room_position()
	var aim: Vector2 = _boss.target_room_position() - origin
	var speed: float = _attack.bullet_speed * _boss.danger.enemy_bullet_speed_mult
	var fired: int = 0
	for direction: Vector2 in ChalkPatterns.aimed_fan(aim, _attack.bullet_count, _attack.spread_deg):
		if _boss.fire_bullet(origin, direction, speed):
			fired += 1
	_fired_fans += 1
	Log.debug("combat", "%s fan %d fired %d/%d" % [_boss.name, _fired_fans, fired, _attack.bullet_count])
	_clear_sign()
