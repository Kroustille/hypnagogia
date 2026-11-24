class_name PickupSpot
extends Marker2D
## Where something lies on a pedestal of a pre-drawn room (story 5.2). Child of the room's PickupSpots node; the position
## is in room coordinates. The Run puts the room's offer there (it draws it, the room never does).

## What the spot holds, as written in the room source text (`pickup <slot> x y`).
enum Slot { ITEM, CONSUMABLE, HEART, ARMOR }

## Names of the slots in the room source text.
const SLOT_NAMES: Dictionary[String, Slot] = {
	"item": Slot.ITEM, "consumable": Slot.CONSUMABLE, "heart": Slot.HEART, "armor": Slot.ARMOR,
}

@export var slot: Slot = Slot.ITEM


func _ready() -> void:
	add_to_group(Const.GROUP_PICKUP_SPOT)
