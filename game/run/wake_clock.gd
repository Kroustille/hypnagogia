class_name WakeClock
extends RefCounted
## The time the player wakes up at (story 6.6): the night starts at the tuned minute of the day and each floor (phase)
## covers a tuned number of minutes. The time advances with the combat rooms cleared, never inside one. Pure: no node.
## Minutes are counted from midnight of the evening and may pass 1440; format() wraps them.

var _tuning: WakeTuning


func _init(tuning: WakeTuning = Tuning.WAKE) -> void:
	_tuning = tuning


## The minute the night starts at.
func start_minute() -> int:
	return _tuning.start_minute_of_day


## The time at the death on the floor, after cleared combat rooms out of total. Never the end of the phase
## (the end is the victory), unless the cap is disabled.
func minute_at_death(floor_index: int, cleared_combat_rooms: int, total_combat_rooms: int) -> int:
	var minute: int = minute_at(floor_index, cleared_combat_rooms, total_combat_rooms)
	var cap: int = _floor_start(floor_index) + _tuning.phase_minutes - _tuning.death_cap_margin_minutes
	if _tuning.death_cap_margin_minutes > 0:
		minute = mini(minute, cap)
	return minute


## The time after cleared combat rooms out of total, proportional: it only moves when a room is finished (floori).
func minute_at(floor_index: int, cleared_combat_rooms: int, total_combat_rooms: int) -> int:
	var base: int = _floor_start(floor_index)
	if total_combat_rooms <= 0:
		return base
	var cleared: int = clampi(cleared_combat_rooms, 0, total_combat_rooms)
	return base + floori(float(_tuning.phase_minutes) * cleared / total_combat_rooms)


## The time when the nightmare of the floor is beaten: the end of its phase.
func minute_after_boss(floor_index: int) -> int:
	return _floor_start(floor_index) + _tuning.phase_minutes


func _floor_start(floor_index: int) -> int:
	return _tuning.start_minute_of_day + maxi(floor_index, 0) * _tuning.phase_minutes


## "HH:MM" on 24 hours (pattern UI_CLOCK_FORMAT), midnight passed. A negative minute is refused ("--:--", logged).
static func format(minute: int) -> String:
	if minute < 0:
		Log.error("run", "wake minute %d is negative" % minute)
		return "--:--"
	var wrapped: int = minute % 1440
	var pattern: String = TranslationServer.translate(&"UI_CLOCK_FORMAT")
	if pattern == "UI_CLOCK_FORMAT":
		pattern = "%02d:%02d" # translations not loaded
	return pattern % [wrapped / 60, wrapped % 60]
