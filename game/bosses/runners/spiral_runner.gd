class_name SpiralRunner
extends AttackRunner
## SPIRAL attack (Calcul mental): a ring sign shows around the boss for `telegraph` seconds, then every `emit_interval`
## seconds each arm fires one chalk; the arms turn at `rotation_deg_per_s`, so two chalks of an arm are
## rotation x emit_interval degrees apart. The first angle is 0, no draw. The cadence and the rotation count in
## clock x pace (a quicker room turns and fires quicker, the geometry stays the same), the sign in clock only.

const TICK_EPSILON: float = 1e-6
const MAX_EMISSIONS_PER_TICK: int = 8
const SIGN_RADIUS_TILES: float = 3.0
const SIGN_SOUND: AudioStream = preload("res://audio/sfx/sfx_enemy_night_light_telegraph.wav")

var _stopped: bool = false
var _sign_started: bool = false
var _sign_ticks_left: float = 0.0
var _sign_ticks_total: float = 0.0
var _sign: AttackSign
var _emitting: bool = false
var _emit_ticks_left: float = 0.0
## Angle of the next emission, degrees, always in [0, 360).
var _angle: float = 0.0
var _emissions: int = 0


## Angle of the next emission, in degrees.
func angle() -> float:
	return _angle


func emissions() -> int:
	return _emissions


func is_emitting() -> bool:
	return _emitting


func current_sign() -> AttackSign:
	return _sign if is_instance_valid(_sign) else null


func tick(clock_step: float, pace: float) -> void:
	if _stopped or _boss == null or _attack == null:
		return
	if not _sign_started:
		_start_sign()
	if not _emitting:
		_sign_ticks_left -= clock_step
		if _sign_ticks_left > TICK_EPSILON:
			if is_instance_valid(_sign):
				_sign.set_progress(1.0 - _sign_ticks_left / _sign_ticks_total)
			return
		_clear_sign()
		_emitting = true
		_emit_ticks_left = 0.0
	_emit_ticks_left -= clock_step * pace
	var interval_ticks: float = _attack.emit_interval * Engine.physics_ticks_per_second
	var guard: int = 0
	while _emit_ticks_left <= TICK_EPSILON and guard < MAX_EMISSIONS_PER_TICK and not _stopped:
		_emit()
		_emit_ticks_left += interval_ticks
		guard += 1
	if _emit_ticks_left <= TICK_EPSILON:
		_emit_ticks_left = 0.0 # a huge slow-down is not paid back later


func stop() -> void:
	_stopped = true
	_clear_sign()


func _start_sign() -> void:
	_sign_started = true
	_sign_ticks_total = Telegraph.duration_for(_attack.telegraph, _boss.danger.telegraph_mult) * Engine.physics_ticks_per_second
	_sign_ticks_left = _sign_ticks_total
	_sign = AttackSign.new()
	_sign.name = "SpiralSign"
	_sign.setup_ring(_boss.room_position(), SIGN_RADIUS_TILES * Const.TILE_SIZE)
	_boss.add_sign(_sign)
	Audio.play_sfx(SIGN_SOUND)


func _clear_sign() -> void:
	if is_instance_valid(_sign):
		_sign.queue_free()
	_sign = null


func _emit() -> void:
	var origin: Vector2 = _boss.room_position()
	var speed: float = _attack.bullet_speed * _boss.danger.enemy_bullet_speed_mult
	for direction: Vector2 in ChalkPatterns.spiral_directions(_angle, _attack.arms):
		_boss.fire_bullet(origin, direction, speed)
	_emissions += 1
	_angle = fposmod(_angle + _attack.rotation_deg_per_s * _attack.emit_interval, 360.0)
