class_name StatBlock
extends RefCounted
## Stats of an entity: a base value per stat plus modifiers, each owned by a source object (D9).
## value = (base + sum(ADD_FLAT)) * (1 + sum(ADD_PERCENT)) * product(MULTIPLY).
## ADD_PERCENT modifiers add up with each other before being applied to the base.
## A source (any Object: a lucidity gauge, an item...) holds at most one modifier per stat.

## Emitted when the computed value of a stat changes (never on a set that changes nothing).
signal changed(stat: int)
## The base value of a stat changed (a base is not a modifier: whatever is derived from it must be recomputed).
signal base_changed(stat: int)

## PIT_DAMAGE: half-hearts lost by a fall. MOVE_SPEED: tiles per second. FIRE_RATE: shots per second.
## CAN_FLY_OVER_PITS, PIERCE and REAR_SHOT: booleans carried by a float (active when > 0).
## New stats are appended at the end: the values may be stored.
enum Stat { DAMAGE, SHOT_SPEED, HURTBOX_SIZE, PIT_DAMAGE, CAN_FLY_OVER_PITS, MOVE_SPEED, FIRE_RATE, PIERCE, REAR_SHOT }
enum Kind { ADD_FLAT, ADD_PERCENT, MULTIPLY }

## stat -> { source: Object -> Modifier }
class Modifier:
	var kind: int
	var value: float

	func _init(kind_: int, value_: float) -> void:
		kind = kind_
		value = value_


var _modifiers: Dictionary = {}
## stat -> base value
var _bases: Dictionary[int, float] = {}
## stat -> last computed value (to emit changed only on a real variation)
var _values: Dictionary[int, float] = {}
## stat -> Vector2(min, max) of the bounds set by set_bounds()
var _bounds: Dictionary[int, Vector2] = {}


func base_of(stat: Stat) -> float:
	return _bases.get(stat, 0.0)


func set_base(stat: Stat, value: float) -> void:
	var previous: float = _bases.get(stat, NAN)
	_bases[stat] = value
	_refresh(stat)
	if is_nan(previous) or not is_equal_approx(previous, value):
		base_changed.emit(stat)


## Limits of the computed value of a stat (inclusive). Use -INF or INF for no limit on one side.
func set_bounds(stat: Stat, minimum: float, maximum: float) -> void:
	assert(minimum <= maximum, "StatBlock bounds are inverted")
	_bounds[stat] = Vector2(minimum, maximum)
	_refresh(stat)


## The computed value, within its bounds.
func value_of(stat: Stat) -> float:
	return _values.get(stat, 0.0)


## Sets the modifier of this source on this stat, replacing the one it already had there.
func set_modifier(source: Object, stat: Stat, kind: Kind, value: float) -> void:
	var by_source: Dictionary = _modifiers.get(stat, {})
	by_source[source] = Modifier.new(kind, value)
	_modifiers[stat] = by_source
	_refresh(stat)


## Removes every modifier of this source, on every stat.
func clear_source(source: Object) -> void:
	for stat: int in _modifiers.keys():
		var by_source: Dictionary = _modifiers[stat]
		if by_source.erase(source):
			_refresh(stat as Stat)


## Removes the modifier of this source on one stat only.
func clear_modifier(source: Object, stat: Stat) -> void:
	var by_source: Dictionary = _modifiers.get(stat, {})
	if by_source.erase(source):
		_refresh(stat)


func _compute(stat: Stat) -> float:
	var flat: float = 0.0
	var percent: float = 0.0
	var product: float = 1.0
	var by_source: Dictionary = _modifiers.get(stat, {})
	for entry: Modifier in by_source.values():
		match entry.kind:
			Kind.ADD_FLAT:
				flat += entry.value
			Kind.ADD_PERCENT:
				percent += entry.value
			Kind.MULTIPLY:
				product *= entry.value
	var result: float = (base_of(stat) + flat) * (1.0 + percent) * product
	if _bounds.has(stat):
		var limits: Vector2 = _bounds[stat]
		result = clampf(result, limits.x, limits.y)
	return result


func _refresh(stat: Stat) -> void:
	var computed: float = _compute(stat)
	if _values.has(stat) and is_equal_approx(_values[stat], computed):
		return
	_values[stat] = computed
	changed.emit(stat)
