class_name OwnedItem
extends RefCounted
## One copy of an item the player holds. It is the SOURCE of its stat modifiers (never a node, never the shared
## ItemDef): two copies are two sources and add up, and StatBlock.clear_source() takes exactly one copy away.

var def: ItemDef
## The effect instance of this copy, null when the item has no effect_script.
var effect: ItemEffect
## Half-hearts of max really taken when this copy was added (given back exactly on removal).
var max_half_hearts_paid: int = 0

## Charge of an active item (story 5.8): rooms cleared since it was used, up to charge_max. Unused by other items.
var charge: int = 0
var charge_max: int = 0


func _init(item_def: ItemDef) -> void:
	def = item_def