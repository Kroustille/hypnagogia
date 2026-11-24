class_name RingRunner
extends AttackRunner
## RING attack (the Professor's pop quiz): every `interval` seconds a ring sign shows around the boss for `telegraph`
## seconds, then a circle of `bullet_count` chalks leaves the boss. Each circle is turned by `ring_offset_deg` from the
## previous one, so two successive circles never line up: a fixed pattern, no draw. The first sign comes as soon as the
## runner starts. Cadence in clock x pace, sign in clock only (never under Tuning.COMBAT.min_telegraph).

const TICK_EPSILON: float = 1e-6
const SIGN_RADIUS_TILES: float = 2.5
const SIGN_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_night_light_telegraph.wav")

var _stopped: bool = false
var _cycle_ticks_left: float = 0.0
var _sign_ticks_left: float = 0.0
var _sign_ticks_total: float = 0.0
var _sign: AttackSign
var _fired_rings: int = 0


## Circles fired so far.
func fired_rings() -> int:
	return _fired_rings


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
			_fire_ring()
		elif is_instance_valid(_sign):
			_sign.set_progress(1.0 - _sign_ticks_left / _sign_ticks_total)
	if _sign_ticks_left <= 0.0 and _cycle_ticks_left <= TICK_EPSILON and not _stopped:
		_start_sign()


func stop() -> void:
	_stopped = true
	_sign_ticks_left = 0.0
	_clear_sign()


func _start_sign() -> void:
	_cycle_ticks_left = _attack.interval * Engine.physics_ticks_per_second
	_sign_ticks_total = Telegraph.duration_for(_attack.telegraph, _boss.danger.telegraph_mult) * Engine.physics_ticks_per_second
	_sign_ticks_left = _sign_ticks_total
	_sign = AttackSign.new()
	_sign.name = "RingSign"
	_sign.setup_ring(_boss.room_position(), SIGN_RADIUS_TILES * Const.TILE_SIZE)
	_boss.add_sign(_sign)
	Audio.play_sfx(SIGN_SOUND)


func _clear_sign() -> void:
	if is_instance_valid(_sign):
		_sign.queue_free()
	_sign = null


func _fire_ring() -> void:
	var origin: Vector2 = _boss.room_position()
	var speed: float = _attack.bullet_speed * _boss.danger.enemy_bullet_speed_mult
	var directions: Array[Vector2] = ChalkPatterns.ring_directions(_attack.bullet_count, _fired_rings * _attack.ring_offset_deg)
	var fired: int = 0
	for direction: Vector2 in directions:
		if _boss.fire_bullet(origin, direction, speed):
			fired += 1
	_fired_rings += 1
	Log.debug("combat", "%s ring %d fired %d/%d" % [_boss.name, _fired_rings, fired, directions.size()])
	_clear_sign()
