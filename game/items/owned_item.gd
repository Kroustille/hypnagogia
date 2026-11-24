class_name OwnedItem
extends RefCounted
## One copy of an item the player holds. It is the SOURCE of its stat modifiers (never a node, never the shared
## ItemDef): two copies are two sources and add up, and StatBlock.clear_source() takes exactly one copy away.

var def: ItemDef
## The effect instance of this copy, null when the item has no effect_script.
var effect: ItemEffect


func _init(item_def: ItemDef) -> void:
	def = item_def
