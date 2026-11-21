class_name DamageNumber
extends Node2D
## One damage number: the amount, centered above its position, rising a few pixels then fading out.
## Counted in game ticks of GameClock.Group.FX in _physics_process (frozen while paused, slowed by F4),
## then frees itself. Kept on whole pixels for the pixel font, so physics interpolation is off.
## Numbers, not text: no tr(). Font and outline come from the project theme (DamageNumberLabel).

# Presentation values, placeholder until epic 7 (visual, not GDD values).
## Lifetime in seconds.
const DURATION: float = 0.5
## Total rise over the lifetime, in pixels.
const RISE_PX: float = 8.0
## Share of the lifetime spent fully opaque before fading.
const HOLD_RATIO: float = 0.5
## Width of the centered label, in pixels (wide enough for 4 digits).
const LABEL_WIDTH: float = 40.0
const THEME_TYPE: StringName = &"DamageNumberLabel"
## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _amount: float = 0.0
var _has_setup: bool = false
var _ticks_total: float = 0.0
var _ticks_elapsed: float = 0.0
var _origin: Vector2 = Vector2.ZERO
var _label: Label


## Dependency injection: call before add_child().
func setup(amount: float) -> void:
	_amount = amount
	_has_setup = true


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if not _has_setup:
		Log.error("combat", "DamageNumber added without setup()")
		assert(false, "DamageNumber.setup() must be called before add_child()")
		queue_free()
		return
	_label = Label.new()
	_label.theme_type_variation = THEME_TYPE
	_label.text = str(roundi(_amount))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	var height: float = _label.get_combined_minimum_size().y
	_label.size = Vector2(LABEL_WIDTH, height)
	# Bottom center of the text on this node's position, on whole pixels.
	_label.position = Vector2(-LABEL_WIDTH / 2.0, -height).round()
	_origin = position
	_ticks_total = maxf(DURATION, 0.0) * Engine.physics_ticks_per_second


func _physics_process(_delta: float) -> void:
	_ticks_elapsed += GameClock.scale(GameClock.Group.FX)
	var t: float = clampf(_ticks_elapsed / _ticks_total, 0.0, 1.0) if _ticks_total > 0.0 else 1.0
	position = (_origin + Vector2(0.0, -RISE_PX * t)).round()
	modulate.a = 1.0 - clampf((t - HOLD_RATIO) / (1.0 - HOLD_RATIO), 0.0, 1.0)
	if _ticks_elapsed >= _ticks_total - TICK_EPSILON:
		queue_free()
