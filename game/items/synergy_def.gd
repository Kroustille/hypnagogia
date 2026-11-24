class_name SynergyDef
extends Resource
## A synergy (D9, story 5.7): reaching `threshold` distinct items of `tag` activates a level. Data only; the highest
## level reached replaces the lower ones. Texts are translation keys (strings.csv), numbers live in `params`.

@export var id: StringName = &""
@export var tag: StringName = &""
## Distinct items of the tag needed.
@export_range(1, 10, 1, "or_greater") var threshold: int = 2
@export var name_key: StringName = &""
@export var description_key: StringName = &""
## Script (extends SynergyEffect) that makes the synergy do something.
@export var effect_script: Script
## Numbers the effect reads (no magic number in the script).
@export var params: Dictionary[StringName, float] = {}
