class_name NakedEffect
extends ItemEffect
## Naked in public (story 5.9): the armor is lost when the item is taken and none can be gained after; in exchange the
## enemies do not fire during the first seconds of each fight (the room counts them from fight_started).

## The armor was taken away once: a carrier that leaves the tree and comes back does not empty it again.
var _stripped: bool = false


func required_params() -> Array[StringName]:
	return [&"hold_seconds", &"blocks_armor"]


func attach(new_carrier: BuildCarrier) -> void:
	if carrier != null:
		return
	super.attach(new_carrier)
	var health: Health = carrier.player.health
	if not _stripped:
		_stripped = true
		health.clear_armor()
	health.armor_blocked = true
	carrier.room_fight_started.connect(_on_room_fight_started)


func detach() -> void:
	if carrier == null:
		return
	carrier.room_fight_started.disconnect(_on_room_fight_started)
	carrier.player.health.armor_blocked = false
	super.detach()


func _on_room_fight_started(room: Room) -> void:
	if room == null or not is_instance_valid(room):
		return
	room.set_fire_hold(param(&"hold_seconds") * Engine.physics_ticks_per_second)
