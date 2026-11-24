class_name FurnitureDef
extends Resource
## What a kind of furniture is (story 4.4): its footprint, its hit points and its placeholder look.
## Read-only at runtime: one def is shared by every piece of its kind (GDD: furniture has 30 HP).

## Identifier for logs and for the room source text (`furniture <id> x y`).
@export var id: StringName = &""
## Footprint in whole tiles. A piece placed at (x, y) covers tiles x to x + width - 1 and y to y + height - 1.
@export var size: Vector2i = Vector2i.ONE
## Hit points. Neutral default: a def that forgets it is reported by HitPoints, never given another's value.
@export_range(0.0, 1000.0, 1.0, "or_greater") var max_hp: float = 0.0
## Placeholder look until epic 7: a plain rectangle of this color.
@export var color: Color = Color.WHITE
