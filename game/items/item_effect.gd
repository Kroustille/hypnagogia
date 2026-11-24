class_name ItemEffect
extends RefCounted
## Base of the scripts of ItemDef.effect_script (D9). One instance per OwnedItem, created by the Loadout.
## An effect that listens to the BuildCarrier connects in attach() and MUST disconnect in detach().

## The carrier calls tick() each physics tick only when this is true.
var wants_tick: bool = false
## The copy this effect belongs to. Held weakly: OwnedItem holds the effect, a strong link back would be a cycle.
var owned: OwnedItem:
	get:
		if _owned_ref == null:
			return null
		var item: Variant = _owned_ref.get_ref()
		return item if item is OwnedItem else null
	set(value):
		_owned_ref = weakref(value) if value != null else null
var _owned_ref: WeakRef
var carrier: BuildCarrier


## The keys the effect reads in ItemDef.params: the catalog refuses a definition that lacks one.
func required_params() -> Array[StringName]:
	return []


## The source of the modifiers of this effect: its OwnedItem (so Loadout.remove clears them), itself without one.
func modifier_source() -> Object:
	var item: OwnedItem = owned
	return item if item != null else self


## A number of the definition.
func param(key: StringName) -> float:
	var item: OwnedItem = owned
	return item.def.params.get(key, 0.0) if item != null else 0.0


## True when the effect can be attached to a build that is not the player's (the Reflection, story 5.10): it then reads only
## carrier.stats and carrier.host, never carrier.player. Most effects are tied to the player and say no.
func supports_non_player() -> bool:
	return false


## The item was added to the loadout (or the carrier entered the tree again). Does nothing when already attached.
func attach(new_carrier: BuildCarrier) -> void:
	carrier = new_carrier


## The item was removed (or the carrier left the tree): undo everything attach() connected. Safe to call twice.
func detach() -> void:
	carrier = null


## dt: seconds of game time of the player group (never zero). Never called on a detached effect by the carrier.
func tick(_dt: float) -> void:
	pass


## The player used the active item (story 5.8), after the charge and the lucidity were checked and spent.
func activate(_player: Player) -> void:
	pass
