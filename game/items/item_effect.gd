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


## The item was added to the loadout.
func attach(new_carrier: BuildCarrier) -> void:
	carrier = new_carrier


## The item was removed (or the carrier left the tree): undo everything attach() connected.
func detach() -> void:
	carrier = null


## dt: seconds of game time of the player group (paused: 0).
func tick(_dt: float) -> void:
	pass


## The player used the active item (story 5.8).
func activate() -> void:
	pass
