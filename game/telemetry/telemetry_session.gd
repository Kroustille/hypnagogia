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
## Seconds spent in each lucidity tier (index = Lucidity.Tier), all runs of the session (NFR12).
var tier_seconds: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
## Tier of the run in progress and when it began, -1 outside a run.
var _tier: int = -1
var _tier_since: float = 0.0
## Seconds per tier of the current run only.
var _run_tier_seconds: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0]
## Spends by power then tier name (tier before the spend): of the session and of the current run.
var spends: Dictionary = {}
var _run_spends: Dictionary = {}
## True from a death until it is answered or skipped.
var _death_open: bool = false


func _init(session_id: String) -> void:
	id = session_id


func start(at: float) -> void:
	_add("session_start", at)


func run_started(at: float) -> void:
	_close_death(at) # restarting without answering is an absence of answer
	_close_tiers(at) # a run that never reported its end (restart from the debug panel)
	runs += 1
	_tier = 0
	_tier_since = at
	_run_tier_seconds = [0.0, 0.0, 0.0, 0.0, 0.0]
	_run_spends = {}
	_add("run_start", at)


## The live lucidity tier changed: the time since the previous change goes to the previous tier.
## Ignored outside a run (a fresh player announces itself before run_started).
func tier_changed(at: float, tier: int) -> void:
	if _tier == -1:
		return
	_credit(at)
	_tier = clampi(tier, 0, tier_seconds.size() - 1)
	_tier_since = at


## A power was paid (ignored outside a run). tier: Lucidity.Tier before the spend.
func spent(power: String, tier: int) -> void:
	if _tier == -1:
		return
	var tier_name: String = str(Lucidity.Tier.find_key(tier)).to_lower()
	_count_spend(spends, power, tier_name)
	_count_spend(_run_spends, power, tier_name)


## Run end: the time in each tier of this run, as a "run_end" event. Returns that run's seconds per tier.
func run_ended(at: float) -> Array[float]:
	if _tier == -1:
		return []
	_close_tiers(at)
	return _run_tier_seconds.duplicate()


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
	_close_tiers(at)
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
			"tier_seconds": tier_dict(tier_seconds),
			"spends": spends,
		},
	}


func _credit(at: float) -> void:
	var elapsed: float = maxf(at - _tier_since, 0.0)
	tier_seconds[_tier] += elapsed
	_run_tier_seconds[_tier] += elapsed


## Ends the tier tracking of the run in progress, if any; records its seconds per tier as a "run_end" event.
func _close_tiers(at: float) -> void:
	if _tier == -1:
		return
	_credit(at)
	_tier = -1
	_add("run_end", at, {"tier_seconds": tier_dict(_run_tier_seconds), "spends": _run_spends.duplicate(true)})


## Tier name (Lucidity.Tier key, lower case) to seconds, rounded to 10 ms.
static func tier_dict(seconds: Array[float]) -> Dictionary:
	var result: Dictionary = {}
	for i: int in seconds.size():
		result[str(Lucidity.Tier.find_key(i)).to_lower()] = snappedf(seconds[i], 0.01)
	return result


static func _count_spend(into: Dictionary, power: String, tier_name: String) -> void:
	var by_tier: Dictionary = into.get_or_add(power, {})
	var count: int = by_tier.get(tier_name, 0)
	by_tier[tier_name] = count + 1


func _close_death(at: float) -> void:
	if _death_open:
		_death_open = false
		no_answer += 1
		_add("no_answer", at)


func _add(type: String, at: float, extra: Dictionary = {}) -> void:
	var event: Dictionary = {"type": type, "t": snappedf(at, 0.01)}
	event.merge(extra)
	events.append(event)
