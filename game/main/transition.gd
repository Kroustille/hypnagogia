class_name Transition
extends CanvasLayer
## The fade to black between two rooms (story 4.8): black in Tuning.ROOM.transition_duration seconds, the swap, clear
## again in the same time. Counted in physics ticks (no Timer), and frozen while the game is paused.
## Lives in Main, above the world and the UI. The Run finds it by its group; without it (checks) the Run swaps at once.

enum Phase { IDLE, TO_BLACK, FROM_BLACK }

var _phase: Phase = Phase.IDLE
var _ticks_left: float = 0.0
var _on_black: Callable
var _on_done: Callable

@onready var _veil: ColorRect = ColorRect.new()


func _ready() -> void:
	add_to_group(Const.GROUP_TRANSITION)
	_veil.name = "Veil"
	_veil.color = Color.BLACK
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	_veil.modulate.a = 0.0
	_veil.visible = false
	add_child(_veil)


## Fades to black, calls on_black (the swap), fades back, then calls on_done. A new call while one is playing is ignored.
func play(on_black: Callable, on_done: Callable) -> void:
	if _phase != Phase.IDLE:
		return
	_on_black = on_black
	_on_done = on_done
	_phase = Phase.TO_BLACK
	_ticks_left = _duration_ticks()
	_veil.visible = true
	_set_alpha(0.0)


## Drops the fade in progress without calling anyone: the run that asked for it is leaving.
func cancel() -> void:
	_on_black = Callable()
	_on_done = Callable()
	_abort()


func is_playing() -> bool:
	return _phase != Phase.IDLE


## True when the screen is fully black.
func is_black() -> bool:
	return _veil.visible and _veil.modulate.a >= 1.0


func _physics_process(_delta: float) -> void:
	_veil.visible = _phase != Phase.IDLE and not GameClock.paused # no veil over the pause menu
	if _phase == Phase.IDLE or GameClock.paused:
		return
	if not _callable_alive(_on_black if _phase == Phase.TO_BLACK else _on_done):
		_abort() # the run that asked for it is gone (restart): nothing to swap, nothing to give back
		return
	_ticks_left -= 1.0
	var total: float = maxf(_duration_ticks(), 1.0)
	var progress: float = clampf(1.0 - _ticks_left / total, 0.0, 1.0)
	if _phase == Phase.TO_BLACK:
		_set_alpha(progress)
		if _ticks_left <= 0.0:
			_set_alpha(1.0)
			_phase = Phase.FROM_BLACK
			_ticks_left = _duration_ticks()
			_on_black.call()
	else:
		_set_alpha(1.0 - progress)
		if _ticks_left <= 0.0:
			_abort()
			var done: Callable = _on_done
			_on_done = Callable()
			done.call()


func _duration_ticks() -> float:
	return Tuning.ROOM.transition_duration * Engine.physics_ticks_per_second


func _set_alpha(alpha: float) -> void:
	_veil.modulate.a = alpha


func _callable_alive(callable: Callable) -> bool:
	return callable.is_valid()


## Back to a clear screen.
func _abort() -> void:
	_phase = Phase.IDLE
	_veil.visible = false
	_set_alpha(0.0)
