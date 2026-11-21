class_name HitFeedback
extends Node
## Reusable impact feedback for any entity that takes a shot: a white flash (hit_flash shader) and a short
## visual knockback of the sprite. Knows nothing of its owner: the owner connects its Hurtbox to play().
## Durations and distances come from Tuning.SHOT (impact_*). Counted in game ticks of its clock group.

const FLASH_SHADER: Shader = preload("res://vfx/shaders/hit_flash.gdshader")
const FLASH_PARAM: StringName = &"flash"
## Margin against floating point rounding when comparing elapsed ticks to the duration.
const TICK_EPSILON: float = 1e-6

var _material: ShaderMaterial
var _kick: SpriteKick
var _clock_group: GameClock.Group = GameClock.Group.ENEMIES
var _flash_ticks_left: float = 0.0


## Dependency injection: call before add_child(). Gives the sprite its own ShaderMaterial (never shared).
func setup(sprite: Sprite2D, clock_group: GameClock.Group) -> void:
	_clock_group = clock_group
	_material = ShaderMaterial.new()
	_material.shader = FLASH_SHADER
	_material.set_shader_parameter(FLASH_PARAM, 0.0)
	sprite.material = _material
	_kick = SpriteKick.new(sprite)


func _ready() -> void:
	if _material == null:
		Log.error("combat", "HitFeedback %s added without setup()" % get_path())
		assert(false, "HitFeedback.setup() must be called before add_child()")
		set_physics_process(false)


## Starts the flash and the knockback along direction (unit, or ZERO for no knockback). Replaying restarts both.
func play(direction: Vector2) -> void:
	if _material == null:
		return
	var tuning: ShotTuning = Tuning.SHOT
	_flash_ticks_left = maxf(tuning.impact_flash_duration, 0.0) * Engine.physics_ticks_per_second
	_material.set_shader_parameter(FLASH_PARAM, 1.0 if _flash_ticks_left > TICK_EPSILON else 0.0)
	_kick.kick(
		direction, tuning.impact_knockback_distance * Const.TILE_SIZE, tuning.impact_knockback_duration
	)


func is_flashing() -> bool:
	return _flash_ticks_left > TICK_EPSILON


func _physics_process(_delta: float) -> void:
	var clock_scale: float = GameClock.scale(_clock_group) # one read per tick
	if _flash_ticks_left > 0.0:
		_flash_ticks_left -= clock_scale
		if _flash_ticks_left <= TICK_EPSILON:
			_flash_ticks_left = 0.0
			_material.set_shader_parameter(FLASH_PARAM, 0.0)
	_kick.tick(clock_scale)
