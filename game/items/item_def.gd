class_name ItemDef
extends Resource
## Definition of an item (D9): data only. The player's copies are OwnedItem; the effect, when there is one, is an
## ItemEffect script. Texts are translation keys (strings.csv), never literals.

@export var id: StringName = &""
## Families of the item (&"body", &"fall"...): the TagTracker counts distinct items per tag.
@export var tags: Array[StringName] = []
## Name, bonus line and cost line shown by the banner.
@export var name_key: StringName = &""
@export var bonus_key: StringName = &""
@export var cost_key: StringName = &""
@export var modifiers: Array[ModifierDef] = []
## Optional script (extends ItemEffect) for what a stat modifier cannot say.
@export var effect_script: Script
## Lucidity the item costs when it is used or taken; 0 = none.
@export_range(0, 100, 1, "or_greater") var lucidity_cost: int = 0
## Whether a second copy may be taken (the copies add up).
@export var stackable: bool = false
## An active item goes in the HUD active slot (story 5.8).
@export var active: bool = false
## Change of the maximum hearts, in half-hearts (negative = a price paid in hearts).
@export var max_half_hearts_delta: int = 0
## Numbers an effect script reads (no magic number in the script).
@export var params: Dictionary[StringName, float] = {}


## Whether an owner with this maximum of hearts (in half-hearts) can pay the item's price in hearts.
func can_be_taken(max_half_hearts: int) -> bool:
	return max_half_hearts + max_half_hearts_delta >= Health.MIN_MAX_HALF_HEARTS
