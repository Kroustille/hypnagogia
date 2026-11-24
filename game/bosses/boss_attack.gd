class_name BossAttack
extends Resource
## One attack of a boss, as data (AR7, D4): flat fields shared by every kind, the unused ones stay at their default.
## Read-only at runtime: a .tres is shared, a runner never writes it (its state lives in the runner).
## Distances in tiles, durations in seconds, speeds in tiles per second.

## Kinds of attack. Explicit values: they are serialized in .tres files, so a new kind is added at the END and nothing
## is ever renumbered.
enum Kind { ROW = 0, SPIRAL = 1, AIMED = 2, RULER = 3, RING = 4 }

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
## SPIRAL: number of arms (chalks per emission, evenly spread around the boss).
@export_range(0, 16, 1, "or_greater") var arms: int = 0
## SPIRAL: rotation of the arms, in degrees per second (negative turns the other way).
@export_range(-720.0, 720.0, 1.0) var rotation_deg_per_s: float = 0.0
## SPIRAL: seconds between two emissions (one chalk per arm each time). `interval` is not used by a spiral.
@export_range(0.0, 5.0, 0.05, "or_greater") var emit_interval: float = 0.0
## AIMED: chalks of the fan. RING: chalks of the circle.
@export_range(0, 16, 1, "or_greater") var bullet_count: int = 0
## AIMED: angle between the two outer chalks of the fan, in degrees (0 = all on one line).
@export_range(0.0, 180.0, 0.5) var spread_deg: float = 0.0
## RULER: thickness of the bar, in tiles.
@export_range(0.0, 8.0, 0.25, "or_greater") var thickness_tiles: float = 0.0
## RULER: speed of the bar, in tiles per second (the room danger does not change it: the telegraph carries the fairness).
@export_range(0.0, 30.0, 0.5, "or_greater") var sweep_speed: float = 0.0
## RING: angle the circle turns by from one volley to the next, in degrees (half the step between two chalks: the holes
## of two successive circles do not line up). A fixed pattern, no draw.
@export_range(-180.0, 180.0, 0.5) var ring_offset_deg: float = 0.0


## "" when the attack can run, else why not (impossible values: not finite, <= 0, a telegraph under the minimum).
func validate() -> String:
	if not Kind.values().has(kind):
		return "unknown kind %d" % kind
	if not is_finite(telegraph) or telegraph < Tuning.COMBAT.min_telegraph - 1e-6:
		return "telegraph %s must be finite and >= %s" % [telegraph, Tuning.COMBAT.min_telegraph]
	if kind != Kind.SPIRAL:
		if not _positive(interval):
			return "interval %s must be finite and > 0" % interval
		if telegraph > interval:
			return "telegraph %s is longer than the interval %s" % [telegraph, interval]
	if kind != Kind.RULER and (not _positive(bullet_speed) or bullet_speed >= Engine.physics_ticks_per_second):
		return "bullet_speed %s must be > 0 and under one tile per tick" % bullet_speed
	match kind:
		Kind.ROW:
			if not _positive(spacing_tiles):
				return "spacing_tiles %s must be finite and > 0" % spacing_tiles
			if not _positive(gap_tiles):
				return "gap_tiles %s must be finite and > 0" % gap_tiles
			if not _positive(max_gap_shift_tiles):
				return "max_gap_shift_tiles %s must be finite and > 0" % max_gap_shift_tiles
		Kind.SPIRAL:
			if arms < 1:
				return "arms %d must be >= 1" % arms
			if not is_finite(rotation_deg_per_s):
				return "rotation_deg_per_s %s must be finite" % rotation_deg_per_s
			if not _positive(emit_interval):
				return "emit_interval %s must be finite and > 0" % emit_interval
		Kind.AIMED:
			if bullet_count < 1:
				return "bullet_count %d must be >= 1" % bullet_count
			if not is_finite(spread_deg) or spread_deg < 0.0 or spread_deg > 180.0:
				return "spread_deg %s must be between 0 and 180" % spread_deg
		Kind.RING:
			if bullet_count < 2:
				return "bullet_count %d must be >= 2" % bullet_count
			if not is_finite(ring_offset_deg):
				return "ring_offset_deg %s must be finite" % ring_offset_deg
		Kind.RULER:
			if not _positive(thickness_tiles):
				return "thickness_tiles %s must be finite and > 0" % thickness_tiles
			if not _positive(sweep_speed) or sweep_speed >= Engine.physics_ticks_per_second:
				return "sweep_speed %s must be > 0 and under one tile per tick" % sweep_speed
			# A bar that moves more than its own thickness in a tick could step over the player without overlapping.
			if sweep_speed >= thickness_tiles * Engine.physics_ticks_per_second:
				return "sweep_speed %s must be under thickness_tiles * ticks per second (%s): the bar would skip the player" % [sweep_speed, thickness_tiles * Engine.physics_ticks_per_second]
	return ""


static func _positive(value: float) -> bool:
	return is_finite(value) and value > 0.0
