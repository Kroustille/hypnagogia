class_name ModifierDef
extends Resource
## One stat modifier given by an item: which stat, how it combines (StatBlock.Kind) and by how much.

@export var stat: StatBlock.Stat = StatBlock.Stat.DAMAGE
@export var kind: StatBlock.Kind = StatBlock.Kind.ADD_FLAT
## ADD_FLAT: added to the base; ADD_PERCENT: fraction of the base (0.3 = +30 %); MULTIPLY: factor.
@export var value: float = 0.0
