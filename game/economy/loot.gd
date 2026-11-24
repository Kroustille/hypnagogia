class_name Loot
extends RefCounted
## What a cleared combat room gives (story 5.4). Pure: it only reads the stream it is given.
##
## The draws are always the same, whatever the tier and whatever the outcome: the shards, the chance, the type, then
## the consumable (only when the type is a consumable). The chance is drawn even when it is 0, so a drop that does not
## happen moves the stream exactly like one that does.


class LootResult extends RefCounted:
	var shards: int = 0
	## Drops.Kind of each drop that happens (none, or one; extra drops come from story 5.9).
	var drops: Array[int] = []
	## For each drop, the raw draw that picks its consumable (0 when it is not one).
	var consumable_rolls: Array[int] = []


## extra_drops: guaranteed drops on top (story 5.9), each drawing its own type; no effect at 0.
static func roll(lowest_tier: int, rng: RandomNumberGenerator, lucidity_tuning: LucidityTuning,
		economy_tuning: EconomyTuning, extra_drops: int = 0) -> LootResult:
	var result: LootResult = LootResult.new()
	var mult: float = loot_mult(lucidity_tuning, lowest_tier)
	var base: int = rng.randi_range(economy_tuning.shards_min, economy_tuning.shards_max)
	result.shards = roundi(base * mult)
	var chance: float = clampf(economy_tuning.drop_chance * mult, 0.0, 1.0)
	var happens: bool = rng.randf() < chance
	_draw_kind(rng, result, happens)
	for _extra: int in extra_drops:
		_draw_kind(rng, result, true)
	return result


static func loot_mult(lucidity_tuning: LucidityTuning, tier: int) -> float:
	var mults: PackedFloat32Array = lucidity_tuning.tier_loot_mult
	return mults[clampi(tier, 0, mults.size() - 1)]


static func _draw_kind(rng: RandomNumberGenerator, result: LootResult, keep: bool) -> void:
	var kind: int = rng.randi_range(0, Drops.Kind.size() - 1)
	var consumable_roll: int = 0
	if kind == Drops.Kind.CONSUMABLE:
		consumable_roll = rng.randi() & 0x7fffffff
	if keep:
		result.drops.append(kind)
		result.consumable_rolls.append(consumable_roll)
