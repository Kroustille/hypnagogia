class_name ShooterEnemy
extends Enemy
## Base of the enemies that shoot (La Veilleuse, La Berceuse): a fire cycle of ShooterDef.fire_interval that restarts
## when a telegraph starts, so volleys come every fire_interval; the first telegraph comes one full cycle after the
## spawn. A volley is a fan of bullet_count bullets spread_angle apart, centered on the target, fired through the
## room's enemy BulletManager (setup()) at the target's position of the firing tick, with the reserved look.
## Subclasses hold the state machine and call _tick_cycle() once per tick, in every state.

const TICK_EPSILON: float = 1e-6

var _shooter_def: ShooterDef
var _bullet_params: BulletParams
var _cycle_ticks_left: float = 0.0
var _volley_count: int = 0
var _spread_radians: float = 0.0
var _interval_seconds: float = 0.0
var _telegraph_seconds: float = 0.0
## Speed of the bullets before the room's danger (tiles per second): the multiplier never compounds on it.
var _base_bullet_speed: float = 0.0


func _ready() -> void:
	super()
	if _def == null:
		return # already reported by Enemy
	_shooter_def = _def as ShooterDef
	if _shooter_def == null or _bullets == null:
		process_mode = Node.PROCESS_MODE_DISABLED # before the assert: it aborts the function in debug builds
		_def = null # subclasses test _def after super()
		Log.error("combat", "shooter %s needs a ShooterDef and the room's enemy BulletManager" % get_path())
		assert(false, "ShooterEnemy needs a ShooterDef and a BulletManager")
		return
	# Validated once (AR28): bounded values, never inherited from another enemy.
	_interval_seconds = _bounded_seconds(_shooter_def.fire_interval, "fire_interval", "it never fires")
	if _interval_seconds <= 0.0:
		_interval_seconds = INF # an invalid cycle never ends: no telegraph, no volley
	var telegraph_seconds: float = _bounded_seconds(_shooter_def.telegraph_duration, "telegraph_duration", "bounded to 0")
	_volley_count = _shooter_def.bullet_count
	if _volley_count < 1:
		_volley_count = 0
		Log.error("combat", "shooter %s bullet_count=%d is invalid, it never fires" % [_shooter_def.id, _shooter_def.bullet_count])
		_assert_failed("ShooterDef bullet_count must be >= 1")
	_spread_radians = 0.0
	if is_finite(_shooter_def.spread_angle):
		_spread_radians = deg_to_rad(_shooter_def.spread_angle)
	else:
		Log.error("combat", "shooter %s spread_angle=%s is invalid, bounded to 0" % [_shooter_def.id, _shooter_def.spread_angle])
		_assert_failed("ShooterDef spread_angle must be finite")
	var speed: float = _shooter_def.bullet_speed
	# Same bound as BulletManager._is_shot_valid(): under one tile per tick, else every shot would be refused.
	if not (is_finite(speed) and speed > 0.0 and speed < Engine.physics_ticks_per_second):
		_volley_count = 0 # an invalid speed never fires
		Log.error("combat", "shooter %s bullet_speed=%s is invalid, it never fires" % [_shooter_def.id, speed])
		_assert_failed("ShooterDef bullet_speed must be finite, > 0 and under one tile per tick")
	_telegraph_seconds = telegraph_seconds
	_bullet_params = BulletParams.new() # own instance, never a shared Resource
	_base_bullet_speed = speed if _volley_count > 0 else 1.0
	_bullet_params.speed = _base_bullet_speed
	_bullet_params.radius = Tuning.COMBAT.enemy_bullet_radius
	_bullet_params.lifetime = Tuning.COMBAT.enemy_bullet_lifetime
	_bullet_params.damage = Tuning.COMBAT.hit_damage_half_hearts
	_bullet_params.appearance = _bullets.add_appearance(EnemyBulletLook.texture()) # the same index for every shooter
	if _bullet_params.appearance < 0:
		_volley_count = 0 # fire() would refuse every bullet
		Log.error("combat", "shooter %s got no bullet appearance, it never fires" % _shooter_def.id)
		_assert_failed("ShooterEnemy needs a bullet appearance")
	if _volley_count == 0:
		_interval_seconds = INF # a shooter that never fires stays inert: no glow, no sound
	_restart_cycle()


## Once per tick, in every state, before the state's _process_<state>(): advances the fire cycle.
func _tick_cycle(clock_scale: float) -> void:
	if danger.fire_hold:
		return # the room holds the fire (story 5.9)
	_cycle_ticks_left -= clock_scale * danger.pace_mult


func _is_cycle_over() -> bool:
	return _cycle_ticks_left <= TICK_EPSILON


## Starts the telegraph (sound included) and restarts the cycle. Called by the subclass's _enter(TELEGRAPH).
func _start_telegraph(sound: AudioStream) -> void:
	_restart_cycle()
	_start_telegraph_of(_telegraph_seconds, sound)


## Fires one volley at the target's current position. Returns the number of bullets fired (0 without a target, on
## top of it, with a refused or walled-in shot). One Log.debug per volley, never per tick.
func _fire_volley() -> int:
	if _volley_count <= 0 or not is_instance_valid(_target):
		return 0
	var origin: Vector2 = _bullets.to_local(global_position)
	var to: Vector2 = _bullets.to_local(_target_position()) - origin
	if to.length_squared() < 1e-6:
		return 0
	var aim: Vector2 = to.normalized()
	var fired: int = 0
	_bullet_params.speed = _base_bullet_speed * danger.enemy_bullet_speed_mult # read now: bullets in flight keep theirs
	for i: int in _volley_count:
		var angle: float = _spread_radians * (i - (_volley_count - 1) / 2.0)
		if _bullets.fire(_bullet_params, origin, aim.rotated(angle)):
			fired += 1
	Log.debug("combat", "%s fired %d/%d" % [_def.id, fired, _volley_count])
	return fired


func _restart_cycle() -> void:
	_cycle_ticks_left = _interval_seconds * Engine.physics_ticks_per_second


## Seconds, bounded to 0 with Log.error + assert when not finite or <= 0 (consequence: text of the log line).
func _bounded_seconds(seconds: float, field: String, consequence: String) -> float:
	var valid: bool = is_finite(seconds) and seconds > 0.0
	if not valid:
		Log.error("combat", "shooter %s %s=%s is invalid, %s" % [_shooter_def.id, field, seconds, consequence])
		_assert_failed("ShooterDef durations must be finite and > 0")
	return seconds if valid else 0.0
