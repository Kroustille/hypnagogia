class_name DangerProfile
extends RefCounted
## What the lowest lucidity tier of the room does to its enemies (story 3.6, FR19, P1). One instance per room, mutated
## in place by apply_tier(): enemies already alive read the current values when they fire or start a telegraph.
## Only the room tier feeds it (never the live tier). The defaults are the neutral profile (Lucid).

## Multiplier on the speed of the bullets enemies fire.
var enemy_bullet_speed_mult: float = 1.0
## Multiplier on the duration of enemy telegraphs (Telegraph keeps its own minimum).
var telegraph_mult: float = 1.0
## The room calls reinforcements (story 3.7).
var reinforcement: bool = false
## Nightmare bosses add a pattern (epic 6).
var boss_extra_pattern: bool = false


## Sets every field for a room tier (Lucidity.Tier as an int). Returns true when at least one field changed.
func apply_tier(tier: int, tuning: LucidityTuning) -> bool:
	var index: int = clampi(tier, 0, Lucidity.Tier.size() - 1)
	var speed: float = _entry(tuning.danger_bullet_speed_mult, index)
	var telegraph: float = _entry(tuning.danger_telegraph_mult, index)
	var call_reinforcement: bool = index >= tuning.reinforcement_from_tier
	var extra_pattern: bool = index >= tuning.boss_extra_pattern_from_tier
	var changed: bool = (
			speed != enemy_bullet_speed_mult or telegraph != telegraph_mult
			or call_reinforcement != reinforcement or extra_pattern != boss_extra_pattern)
	enemy_bullet_speed_mult = speed
	telegraph_mult = telegraph
	reinforcement = call_reinforcement
	boss_extra_pattern = extra_pattern
	return changed


## The tier's entry, or 1 (neutral) when the table is too short.
func _entry(table: PackedFloat32Array, index: int) -> float:
	return table[index] if index < table.size() else 1.0
