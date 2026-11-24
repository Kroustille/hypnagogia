class_name Telegraph
extends Node
## Announces an attack (FR26, AR7): every enemy attack starts with start(). Its duration is
## max(base x multiplier, Tuning.COMBAT.min_telegraph), counted in game ticks of the owner's clock group.
## Plays the telegraph sound; the animation is the owner's (it swaps its sprite texture on the same tick).
## The multiplier is the room's danger.telegraph_mult (story 3.6).
## As a child of its owner at the same tick priority it ticks after it: started on tick N it reads
## 24 ticks (0.4 s at 60 Hz) and the owner sees it inactive on tick N + 24.

const TICK_EPSILON: float = 1e-6

var _clock_group: GameClock.Group = GameClock.Group.ENEMIES
var _ticks_left: float = 0.0
var _ticks_total: float = 0.0
var _is_setup: bool = false


## Dependency injection: call before add_child().
func setup(clock_group: GameClock.Group) -> void:
	_clock_group = clock_group
	_is_setup = true


func _ready() -> void:
	if not _is_setup:
		set_physics_process(false) # before the assert: a failed assert aborts the function in debug builds
		Log.error("combat", "Telegraph %s added without setup()" % get_path())
		assert(false, "Telegraph.setup() must be called before add_child()")


## Starts (or restarts) the telegraph. Returns its duration in seconds.
func start(base_seconds: float, sound: AudioStream, multiplier: float = 1.0) -> float:
	var base: float = base_seconds
	var factor: float = multiplier
	var base_valid: bool = is_finite(base_seconds) and base_seconds >= 0.0
	var factor_valid: bool = is_finite(multiplier) and multiplier >= 0.0
	if not base_valid:
		base = 0.0
	if not factor_valid:
		factor = 1.0
	if not base_valid or not factor_valid:
		Log.error("combat", "invalid telegraph base=%s multiplier=%s, bounded to %s x %s" % [base_seconds, multiplier, base, factor])
		_assert_failed("Telegraph.start() needs a finite base >= 0 and multiplier >= 0")
	var duration: float = maxf(base * factor, Tuning.COMBAT.min_telegraph)
	_ticks_left = duration * Engine.physics_ticks_per_second
	_ticks_total = _ticks_left
	var owner_name: String = String(get_parent().name) if get_parent() != null else String(name)
	Log.debug("combat", "telegraph %s started duration=%.2f" % [owner_name, duration])
	if sound == null:
		Log.error("combat", "telegraph started without a sound")
		_assert_failed("Telegraph.start() needs a sound")
	else:
		Audio.play_sfx(sound)
	return duration


func is_active() -> bool:
	return _ticks_left > TICK_EPSILON


## Share of the telegraph already elapsed, from 0 (just started) to 1 (about to end); 0 when inactive.
## Drives the owner's animation steps (rising glow, inhale). Ticks after its owner: the owner reads last tick's value.
func progress() -> float:
	if not is_active() or _ticks_total <= 0.0:
		return 0.0
	return clampf(1.0 - _ticks_left / _ticks_total, 0.0, 1.0)


func _physics_process(_delta: float) -> void:
	if _ticks_left <= 0.0:
		return
	_ticks_left -= GameClock.scale(_clock_group)
	if _ticks_left <= TICK_EPSILON:
		_ticks_left = 0.0


## A failed assert aborts the function it is in (debug builds): kept in its own function so the caller carries on
## with the bounded values (AR28).
func _assert_failed(message: String) -> void:
	assert(false, message)
