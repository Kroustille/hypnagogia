class_name ConsumableEffect
extends RefCounted
## Base of the scripts of ConsumableDef.effect_script (story 5.3). One instance per definition while it lasts: the
## carrier keeps a lasting effect (Coffee) and uses the same object again when the consumable is taken a second time.

var def: ConsumableDef


## The keys the effect reads in def.params: the catalog refuses a definition that lacks one.
func required_params() -> Array[StringName]:
	return []


## The player uses the consumable. False = refused: nothing was spent, gained or changed.
func use(_player: Player) -> bool:
	return true


## Advances by game ticks of the player group (already scaled by pause and slow motion, never zero).
func tick(_ticks: float) -> void:
	pass


## True once nothing is left to run (the carrier lets go of the effect).
func is_done() -> bool:
	return true


## The player is gone: take back everything the effect gave.
func cancel() -> void:
	pass


func param(key: StringName) -> float:
	return def.params.get(key, 0.0)
