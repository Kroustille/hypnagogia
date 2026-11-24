class_name BossAttack
extends Resource
## One attack of a boss, as data (AR7, D4): flat fields shared by every kind, the unused ones stay at their default.
## Read-only at runtime: a .tres is shared, a runner never writes it (its state lives in the runner).
## Distances in tiles, durations in seconds, speeds in tiles per second.

## Kinds of attack. Explicit values: they are serialized in .tres files, so a new kind is added at the END and nothing
## is ever renumbered.
enum Kind { ROW = 0 }

@export var kind: Kind = Kind.ROW
## Seconds from the start of one telegraph to the start of the next one (so from one volley to the next).
@export_range(0.0, 20.0, 0.1, "or_greater") var interval: float = 0.0
## Sign shown before the attack, before the room's danger is applied (never under Tuning.COMBAT.min_telegraph).
@export_range(0.0, 10.0, 0.05, "or_greater") var telegraph: float = 0.0
## Speed of the bullets before the room's danger.
@export_range(0.0, 20.0, 0.1, "or_greater") var bullet_speed: float = 0.0
## ROW: distance between two neighbouring bullets of the row.
@export_range(0.0, 4.0, 0.05, "or_greater") var spacing_tiles: float = 0.0
## ROW: width of the free passage in the row.
@export_range(0.0, 36.0, 0.5, "or_greater") var gap_tiles: float = 0.0
## ROW: the passage of a row is at most this far from the previous one, so it is always reachable.
@export_range(0.0, 36.0, 0.5, "or_greater") var max_gap_shift_tiles: float = 0.0


## "" when the attack can run, else why not (impossible values: not finite, <= 0, a telegraph under the minimum).
func validate() -> String:
	if not Kind.values().has(kind):
		return "unknown kind %d" % kind
	if not _positive(interval):
		return "interval %s must be finite and > 0" % interval
	if not is_finite(telegraph) or telegraph < Tuning.COMBAT.min_telegraph - 1e-6:
		return "telegraph %s must be finite and >= %s" % [telegraph, Tuning.COMBAT.min_telegraph]
	if telegraph > interval:
		return "telegraph %s is longer than the interval %s" % [telegraph, interval]
	if not _positive(bullet_speed) or bullet_speed >= Engine.physics_ticks_per_second:
		return "bullet_speed %s must be > 0 and under one tile per tick" % bullet_speed
	match kind:
		Kind.ROW:
			if not _positive(spacing_tiles):
				return "spacing_tiles %s must be finite and > 0" % spacing_tiles
			if not _positive(gap_tiles):
				return "gap_tiles %s must be finite and > 0" % gap_tiles
			if not _positive(max_gap_shift_tiles):
				return "max_gap_shift_tiles %s must be finite and > 0" % max_gap_shift_tiles
	return ""


static func _positive(value: float) -> bool:
	return is_finite(value) and value > 0.0
