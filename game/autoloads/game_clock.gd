extends Node
## Per-group time scale. Gameplay code multiplies its delta by scale(group).
## Never use Engine.time_scale, Timer nodes or create_timer() for gameplay.

enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }

var paused: bool = false
## Global time multiplier, composed with every group scale. Debug slow motion (F4) uses it.
## Clamped to [0, 1]: a scale above 1 is not a supported case (see deferred-work, story 1.2).
var global_multiplier: float = 1.0:
	set(value):
		global_multiplier = clampf(value, 0.0, 1.0)
var _scales: Dictionary[Group, float] = {}


func _init() -> void:
	for group: Group in Group.values():
		_scales[group] = 1.0


func scale(group: Group) -> float:
	return 0.0 if paused else _scales[group] * global_multiplier
