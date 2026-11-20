extends Node
## Per-group time scale. Gameplay code multiplies its delta by scale(group).
## Never use Engine.time_scale, Timer nodes or create_timer() for gameplay.

enum Group { PLAYER, ENEMIES, ENEMY_BULLETS, PLAYER_BULLETS, WORLD, FX }

var paused: bool = false
var _scales: Dictionary[Group, float] = {}


func _init() -> void:
	for group: Group in Group.values():
		_scales[group] = 1.0


func scale(group: Group) -> float:
	return 0.0 if paused else _scales[group]
