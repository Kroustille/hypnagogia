class_name SynergyEffect
extends RefCounted
## Base of SynergyDef.effect_script (story 5.7): same contract as ItemEffect. One instance per active level; the
## BuildCarrier attaches it when the level activates and detaches it when it ends. detach() MUST undo attach().

var def: SynergyDef
var carrier: BuildCarrier


## The keys the effect reads in SynergyDef.params.
func required_params() -> Array[StringName]:
	return []


## A number of the definition.
func param(key: StringName) -> float:
	return def.params.get(key, 0.0) if def != null else 0.0


## Does nothing when already attached.
func attach(new_carrier: BuildCarrier, new_def: SynergyDef) -> void:
	if carrier != null:
		return
	carrier = new_carrier
	def = new_def


## Safe to call twice.
func detach() -> void:
	carrier = null
