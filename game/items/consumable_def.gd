class_name ConsumableDef
extends Resource
## Definition of a consumable (story 5.3): data only, like ItemDef. The player carries at most one; using it runs a
## ConsumableEffect script. Texts are translation keys (strings.csv), never literals.

@export var id: StringName = &""
## Name, bonus line and cost line shown by the banner.
@export var name_key: StringName = &""
@export var bonus_key: StringName = &""
@export var cost_key: StringName = &""
## Script (extends ConsumableEffect) run when the consumable is used.
@export var effect_script: Script
## Numbers the effect script reads (no magic number in the script).
@export var params: Dictionary[StringName, float] = {}
