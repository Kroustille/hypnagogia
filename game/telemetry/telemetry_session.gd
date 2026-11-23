class_name TelemetrySession
extends RefCounted
## Pure data of one playtest session: the event list and the indicators (story 2.8). No I/O, no clock:
## the caller passes the elapsed seconds, so it can be checked headless.

const VERSION: int = 1

var id: String = ""
var events: Array[Dictionary] = []
var runs: int = 0
var deaths: int = 0
var yes: int = 0
var no: int = 0
var no_answer: int = 0
var play_seconds: float = 0.0
## True from a death until it is answered or skipped.
var _death_open: bool = false


func _init(session_id: String) -> void:
	id = session_id


func start(at: float) -> void:
	_add("session_start", at)


func run_started(at: float) -> void:
	_close_death(at) # restarting without answering is an absence of answer
	runs += 1
	_add("run_start", at)


## cause: DamageInfo.Source name of the lethal hit, "unknown" when no hit was seen.
func death(at: float, cause: String) -> void:
	_close_death(at)
	deaths += 1
	_death_open = true
	_add("death", at, {"cause": cause})


## Returns false when no death is waiting for an answer (one answer per death).
func answer(at: float, just: bool) -> bool:
	if not _death_open:
		return false
	_death_open = false
	if just:
		yes += 1
	else:
		no += 1
	_add("answer", at, {"just": just})
	return true


func end(at: float) -> void:
	_close_death(at)
	play_seconds = at
	_add("session_end", at)


## yes / (yes + no), absences excluded; null when nobody answered.
func yes_rate() -> Variant:
	if yes + no == 0:
		return null
	return float(yes) / float(yes + no)


func to_dict(at: float) -> Dictionary:
	return {
		"version": VERSION,
		"session": id,
		"events": events,
		"summary": {
			"play_seconds": maxf(play_seconds, at),
			"runs": runs,
			"deaths": deaths,
			"yes": yes,
			"no": no,
			"no_answer": no_answer,
			"yes_rate": yes_rate(),
		},
	}


func _close_death(at: float) -> void:
	if _death_open:
		_death_open = false
		no_answer += 1
		_add("no_answer", at)


func _add(type: String, at: float, extra: Dictionary = {}) -> void:
	var event: Dictionary = {"type": type, "t": snappedf(at, 0.01)}
	event.merge(extra)
	events.append(event)
