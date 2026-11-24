class_name LucidityFx
extends Node2D
## Screen effects of the live lucidity tier (story 3.8): a wave and a chromatic aberration on the decor only, and a
## low-pass filter on the music. Child of the arena. The effects follow the live tier (not the room tier), read
## Settings, and ease to every new target over Tuning.LUCIDITY.fx_transition (counted in game ticks of the FX group).
## They change nothing in the gameplay: no collision, speed or clock is touched.
## The distortion is a ColorRect at Const.Z_INDEX_POSTFX that copies what is drawn before it (the decor at
## Const.Z_INDEX_DECOR): entities, telegraphs, bullets and the HUD are drawn after it and stay sharp.

const SHADER: Shader = preload("res://vfx/shaders/lucidity_distortion.gdshader")
const POSTFX_NAME: String = "PostFx"
## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _player: Player
var _frame_size: Vector2 = Vector2.ZERO
var _postfx: ColorRect
var _material: ShaderMaterial

## Current, start and target values of the eased effects. The cutoff is eased on a logarithmic scale.
var _wave: float = 0.0
var _aberration: float = 0.0
var _log_cutoff: float = 0.0
var _start_wave: float = 0.0
var _start_aberration: float = 0.0
var _start_log_cutoff: float = 0.0
var _target_wave: float = 0.0
var _target_aberration: float = 0.0
var _target_log_cutoff: float = 0.0
var _ticks_total: float = 1.0
var _ticks_elapsed: float = 1.0
var _seconds: float = 0.0


## Call before add_child(). frame_size: the room frame in pixels (walls included).
func setup(player: Player, frame_size: Vector2) -> void:
	_player = player
	_frame_size = frame_size


func _ready() -> void:
	if _player == null:
		Log.error("fx", "lucidity fx added without setup()")
		assert(false, "LucidityFx.setup() must be called before add_child()")
		set_physics_process(false)
		return
	_material = ShaderMaterial.new() # one per instance: the screen copy is not shared
	_material.shader = SHADER
	_postfx = ColorRect.new()
	_postfx.name = POSTFX_NAME
	_postfx.size = _frame_size
	_postfx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_postfx.z_index = Const.Z_INDEX_POSTFX
	_postfx.material = _material
	add_child(_postfx)
	# A new game starts at the state of its tier, with no ease: a restart shows no trace of the last run.
	_compute_targets()
	_wave = _target_wave
	_aberration = _target_aberration
	_log_cutoff = _target_log_cutoff
	_ticks_elapsed = _ticks_total
	_apply()
	Events.lucidity_tier_changed.connect(_on_lucidity_tier_changed)
	Settings.changed.connect(_on_settings_changed)


func _physics_process(_delta: float) -> void:
	var step: float = GameClock.scale(GameClock.Group.FX)
	if step <= 0.0:
		return
	_seconds += step / Engine.physics_ticks_per_second
	if _ticks_elapsed < _ticks_total - TICK_EPSILON:
		_ticks_elapsed += step
		var t: float = clampf(_ticks_elapsed / _ticks_total, 0.0, 1.0)
		_wave = lerpf(_start_wave, _target_wave, t)
		_aberration = lerpf(_start_aberration, _target_aberration, t)
		_log_cutoff = lerpf(_start_log_cutoff, _target_log_cutoff, t)
	_apply()


## Distortion currently shown, in pixels (checks).
func wave_amount() -> float:
	return _wave


func aberration() -> float:
	return _aberration


## Distortion aimed at for the live tier and the settings, in pixels: f(tier) x intensity, capped in photosensitivity mode.
static func distortion_target(table: PackedFloat32Array, tier: int) -> float:
	var value: float = table[clampi(tier, 0, table.size() - 1)] * Settings.distortion_intensity
	if Settings.photosensitive:
		value = minf(value, Tuning.LUCIDITY.fx_photosensitive_cap)
	return value


func _compute_targets() -> void:
	var tier: int = _player.lucidity.live_tier
	var tuning: LucidityTuning = Tuning.LUCIDITY
	_target_wave = distortion_target(tuning.fx_wave, tier)
	_target_aberration = distortion_target(tuning.fx_aberration, tier)
	_target_log_cutoff = log(tuning.fx_music_cutoff_hz[clampi(tier, 0, tuning.fx_music_cutoff_hz.size() - 1)])
	_ticks_total = maxf(tuning.fx_transition * Engine.physics_ticks_per_second, 1.0)


## Starts an ease from what is shown now to the new targets.
func _retarget() -> void:
	_start_wave = _wave
	_start_aberration = _aberration
	_start_log_cutoff = _log_cutoff
	_compute_targets()
	_ticks_elapsed = 0.0


func _apply() -> void:
	_material.set_shader_parameter(&"wave_amount", _wave)
	_material.set_shader_parameter(&"aberration", _aberration)
	_material.set_shader_parameter(&"time", _seconds)
	_postfx.visible = _wave >= 0.5 or _aberration >= 0.5 # no screen copy while nothing would be drawn (the shader rounds below 0.5 px to 0)
	Audio.set_music_muffle(exp(_log_cutoff))


func _on_lucidity_tier_changed(_tier: int, _previous: int) -> void:
	_retarget()


func _on_settings_changed() -> void:
	_retarget()
