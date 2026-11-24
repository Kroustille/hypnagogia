class_name BlankExamEffect
extends ItemEffect
## Blank exam (story 5.9): a timer runs in each fight room not yet cleared; at 0 the enemies left move and fire faster
## for the rest of the room. Clearing a combat room always drops one more thing (the loot reads guaranteed_drops).
## The timer lives here, not in the room: it stops when the player leaves the room, dies or clears it.

var _room: Room
var _seconds_left: float = 0.0
var _running: bool = false
var _expired: bool = false


func required_params() -> Array[StringName]:
	return [&"seconds", &"pace_bonus", &"guaranteed_drops"]


func attach(new_carrier: BuildCarrier) -> void:
	if carrier != null:
		return
	super.attach(new_carrier)
	carrier.room_entered.connect(_on_room_entered)
	carrier.room_cleared.connect(_on_room_cleared)
	carrier.player.health.died.connect(_stop)
	var room: Room = carrier.current_room
	if room != null and is_instance_valid(room) and room.is_node_ready():
		_on_room_entered(room) # taken inside a room that has a fight to win


func detach() -> void:
	if carrier == null:
		return
	carrier.room_entered.disconnect(_on_room_entered)
	carrier.room_cleared.disconnect(_on_room_cleared)
	if carrier.player.health.died.is_connected(_stop):
		carrier.player.health.died.disconnect(_stop)
	_stop()
	super.detach()


func tick(dt: float) -> void:
	if not _running:
		return
	if _room == null or not is_instance_valid(_room) or carrier.current_room != _room or _room.is_cleared():
		_stop()
		return
	_seconds_left -= dt
	if _seconds_left > 0.0:
		Events.exam_timer_changed.emit(_seconds_left)
		return
	_expired = true
	_room.set_pace_mult(1.0 + param(&"pace_bonus"))
	Log.info("items", "blank exam: time is up, enemies pace x%.2f" % _room.danger.pace_mult)
	_stop()


## True while the timer runs.
func is_running() -> bool:
	return _running


func seconds_left() -> float:
	return _seconds_left


## True when the room is a fight the timer applies to: a combat room with enemies to come, not yet cleared.
static func applies_to(room: Room) -> bool:
	return room.room_type == Room.RoomType.COMBAT and not room.is_nightmare() and not room.is_cleared() and room.has_fight()


func _on_room_entered(room: Room) -> void:
	_stop()
	_expired = false
	if not applies_to(room):
		return
	_room = room
	_seconds_left = param(&"seconds")
	_running = true
	wants_tick = true
	Events.exam_timer_changed.emit(_seconds_left)


func _on_room_cleared(_room_cleared: Node, _lowest_tier: int) -> void:
	_stop()


## Stops and hides the timer (the pace already set stays until the room ends).
func _stop() -> void:
	var was_running: bool = _running
	_running = false
	wants_tick = false
	_room = null
	if was_running:
		Events.exam_timer_changed.emit(-1.0)
