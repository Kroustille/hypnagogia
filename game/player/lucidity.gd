class_name Lucidity
extends RefCounted
## The lucidity gauge (D5, FR16/FR17): a value in 0..max and its live tier. Pure logic, no scene dependency.
## Story 3.1 covers the value, the live tier and their signals; spending (3.3), the room tier (3.6) and the
## graze cap (3.2) join later. Tier limits come from LucidityTuning, never from this file.

## Tiers, from the most lucid. Values are explicit: they travel as ints on Events.lucidity_tier_changed.
enum Tier { LUCID = 0, FLOATING = 1, DRIFT = 2, ABANDON = 3, TOTAL_ABANDON = 4 }

## The value changed (never emitted for an unchanged value).
signal value_changed(value: int)
## The live tier changed, in either direction.
signal tier_changed(tier: Tier)

var value: int
var live_tier: Tier

var _tuning: LucidityTuning


func _init(tuning: LucidityTuning) -> void:
	_tuning = tuning
	value = tuning.max_value
	live_tier = tier_for(value)


## Adds amount (clamped to the maximum: the surplus is lost, FR16).
func gain(amount: int) -> void:
	set_value(value + amount)


## Sets the value, clamped to 0..max. Debug tools and rules go through this one entry point.
func set_value(new_value: int) -> void:
	var clamped: int = clampi(new_value, 0, _tuning.max_value)
	if clamped == value:
		return
	value = clamped
	var tier: Tier = tier_for(value)
	var tier_moved: bool = tier != live_tier
	live_tier = tier # both fields are up to date before any listener runs
	value_changed.emit(value)
	if tier_moved:
		tier_changed.emit(tier)


## Tier of a value: the first tier whose floor the value reaches.
func tier_for(of_value: int) -> Tier:
	var floors: PackedInt32Array = _tuning.tier_floors
	for i: int in floors.size():
		if of_value >= floors[i]:
			return i as Tier
	return Tier.TOTAL_ABANDON
