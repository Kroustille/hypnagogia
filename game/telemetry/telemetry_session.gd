class_name TelemetrySession
extends RefCounted
## Pure data of one playtest session: the event list and the indicators (story 2.8). No I/O, no clock:
## the caller passes the elapsed seconds, so it can be checked headless.

const VERSION: int = 1
## Outcomes written in "run_end" (Run.Outcome names; "abandoned": a run cut by a restart or the end of the session).
const OUTCOME_DEATH: String = "death"
const OUTCOME_VICTORY: String = "victory"
const OUTCOME_ABANDONED: String = "abandoned"

var id: String = ""
var events: Array[Dictionary] = []
var runs: int = 0
var deaths: int = 0
var victories: int = 0
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
## item_id of the items taken, in order: of the current run, and by id with their count over the session (story 5.1).
var _run_items: Array[String] = []
## Shards held now in the run in progress, written in its "run_end" (story 5.4).
var _run_shards: int = 0
var items: Dictionary = {}
## True from a death until it is answered or skipped.
var _death_open: bool = false
## Seconds of play of the run in progress: paused time excluded, the caller feeds it (advance_play), never read from a clock.
var _run_play_seconds: float = 0.0
## Seed code of the run in progress and whether the player typed it (run_seeded), "" before.
var _run_seed: String = ""
var _run_seeded: bool = false
## How long the floor took to be ready, in ms: the run itself and from the request (floor_ready), -1 unknown.
var _run_startup_ms: int = -1
var _run_load_ms: int = -1
## One entry per finished run: duration, outcome, wake time, time below Lucid (story 6.9).
## The run in progress was resumed from a save, and its restored items are being announced (not counted again).
var _run_resumed: bool = false
var _restoring: bool = false
var runs_detail: Array[Dictionary] = []
## One entry per finished attempt against a boss (story 6.9).
var boss_attempts: Array[Dictionary] = []
## The attempt in progress, empty outside a fight against a boss.
var _attempt: Dictionary = {}


func _init(session_id: String) -> void:
	id = session_id


func start(at: float) -> void:
	_add("session_start", at)


func run_started(at: float) -> void:
	_close_death(at) # restarting without answering is an absence of answer
	_close_tiers(at, OUTCOME_ABANDONED) # a run that never reported its end (restart from the debug panel)
	runs += 1
	_tier = 0
	_tier_since = at
	_run_tier_seconds = [0.0, 0.0, 0.0, 0.0, 0.0]
	_run_spends = {}
	_run_items = []
	_run_shards = 0
	_run_play_seconds = 0.0
	_run_seed = ""
	_run_seeded = false
	_run_startup_ms = -1
	_run_load_ms = -1
	_run_resumed = false
	_restoring = false
	_add("run_start", at)


## The seed of the run that just started, written in its "run_start" event (no event of its own: the order of the events
## stays what the readers of the file expect); seeded: given by the player. Ignored outside a run.
func run_seeded(seed_code: String, seeded: bool) -> void:
	if _tier != -1 and _run_seed.is_empty():
		_run_seed = seed_code
		_run_seeded = seeded
	for index: int in range(events.size() - 1, -1, -1):
		if events[index]["type"] == "run_end":
			return
		if events[index]["type"] == "run_start" and not events[index].has("seed"):
			events[index]["seed"] = seed_code
			events[index]["seeded"] = seeded
			return


## The run that just started was resumed from a save: written in its "run_start" event and in its runs_detail entry, and the
## items announced until the first room are not counted again. Ignored outside a run.
func run_resumed() -> void:
	if _tier == -1:
		return
	_run_resumed = true
	_restoring = true
	for index: int in range(events.size() - 1, -1, -1):
		if events[index]["type"] == "run_end":
			return
		if events[index]["type"] == "run_start":
			events[index]["resumed"] = true
			return


## The player came into a room of the floor.
func room_entered(at: float, room_id: String, cell: Vector2i) -> void:
	_restoring = false # the announce of the restored items is over
	_add("room_entered", at, {"room_id": room_id, "cell": [cell.x, cell.y]})


## Seconds of play go by (the caller leaves out the time of the pause and of the wake screen). Ignored outside a run.
func advance_play(seconds: float) -> void:
	if _tier != -1:
		_run_play_seconds += maxf(seconds, 0.0)


## How long the floor of the run in progress took to be ready (story 6.9, NFR3): startup_ms for the run itself, load_ms from
## the request of the player. Written in the "run_start" event of the run. Ignored outside a run.
func floor_ready(startup_ms: int, load_ms: int) -> void:
	if _tier == -1:
		return
	_run_startup_ms = startup_ms
	_run_load_ms = load_ms
	for index: int in range(events.size() - 1, -1, -1):
		if events[index]["type"] == "run_start":
			events[index]["startup_ms"] = startup_ms
			events[index]["load_ms"] = load_ms
			return


## A boss came into the room: an attempt against it begins (story 6.9). Ignored outside a run, or while one is open.
func boss_engaged(at: float, boss_id: String) -> void:
	if _tier == -1 or not _attempt.is_empty():
		return
	_attempt = {"boss": boss_id, "run": runs, "started": snappedf(at, 0.01), "phase": 0, "hp_left": 1.0, "play_start": _run_play_seconds}


## The boss lost or regained hit points. A reading of 0 is the bar being hidden (death or the room torn down): the share left
## of the last real reading stays.
func boss_health(hp: float, max_hp: float) -> void:
	if _attempt.is_empty() or max_hp <= 0.0 or hp <= 0.0:
		return
	_attempt["hp_left"] = clampf(hp / max_hp, 0.0, 1.0)


## The boss moved to a phase (index of BossDef.phases): the attempt keeps the deepest one reached.
func boss_phase(phase_index: int) -> void:
	if _attempt.is_empty():
		return
	var reached: int = _attempt["phase"]
	_attempt["phase"] = maxi(reached, phase_index)


## The boss died: the attempt is won.
func boss_defeated(at: float) -> void:
	_close_attempt(at, OUTCOME_VICTORY)


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


## Something was bought in a shop (ignored outside a run): one "purchase" event.
func purchase(at: float, item_id: String, price: int) -> void:
	if _tier == -1:
		return
	_add("purchase", at, {"id": item_id, "price": price})


## The shards held changed (ignored outside a run).
func shards_changed(total: int) -> void:
	if _tier == -1:
		return
	_run_shards = total


## The player took an item (ignored outside a run).
func item_taken(item_id: String) -> void:
	if _tier == -1:
		return
	_run_items.append(item_id)
	if _restoring:
		return # restored from a save, already counted by the night it was taken in
	items[item_id] = items.get(item_id, 0) + 1


## Run end: the time in each tier of this run, as a "run_end" event carrying the outcome ("death" or "victory").
## Returns that run's seconds per tier.
func run_ended(at: float, outcome: String = OUTCOME_DEATH, wake_minute: int = -1) -> Array[float]:
	if _tier == -1:
		return []
	_close_tiers(at, outcome, wake_minute)
	return _run_tier_seconds.duplicate()


## The night was won (the run ended by victory): no death, no question to answer.
func victory(at: float) -> void:
	_close_death(at)
	victories += 1
	_add("victory", at)


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
	_close_tiers(at, OUTCOME_ABANDONED)
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
		"runs_detail": runs_detail,
		"boss_attempts": boss_attempts,
		"summary": {
			"play_seconds": maxf(play_seconds, at),
			"runs": runs,
			"deaths": deaths,
			"victories": victories,
			"yes": yes,
			"no": no,
			"no_answer": no_answer,
			"yes_rate": yes_rate(),
			"tier_seconds": tier_dict(tier_seconds),
			"below_lucid_seconds": snappedf(below_lucid_seconds(tier_seconds), 0.01),
			"below_lucid_share": snappedf(below_lucid_seconds(tier_seconds) / _sum(tier_seconds), 0.001) if _sum(tier_seconds) > 0.0 else 0.0,
			"spends": spends,
			"items": items,
		},
	}


func _credit(at: float) -> void:
	var elapsed: float = maxf(at - _tier_since, 0.0)
	tier_seconds[_tier] += elapsed
	_run_tier_seconds[_tier] += elapsed


## Ends the tier tracking of the run in progress, if any; records its seconds per tier as a "run_end" event.
func _close_tiers(at: float, outcome: String, wake_minute: int = -1) -> void:
	if _tier == -1:
		return
	_credit(at)
	_close_attempt(at, outcome)
	_record_run(outcome, wake_minute)
	_tier = -1
	_add("run_end", at, {"outcome": outcome, "tier_seconds": tier_dict(_run_tier_seconds), "spends": _run_spends.duplicate(true), "items": _run_items.duplicate(), "shards": _run_shards, "wake_minute": wake_minute, "wake": WakeClock.format(wake_minute) if wake_minute >= 0 else ""})


## Closes the attempt against a boss, if one is open. outcome: "victory", "death" or "abandoned".
func _close_attempt(at: float, outcome: String) -> void:
	if _attempt.is_empty():
		return
	var attempt: Dictionary = _attempt
	_attempt = {}
	var started: float = attempt["play_start"]
	attempt["outcome"] = outcome
	if outcome == OUTCOME_VICTORY:
		attempt["hp_left"] = 0.0
	attempt["duration_seconds"] = snappedf(_run_play_seconds - started, 0.01)
	attempt["ended"] = snappedf(at, 0.01)
	attempt.erase("play_start")
	boss_attempts.append(attempt)


## One entry of runs_detail for the run that ends. Called with the seconds of the tiers already credited.
func _record_run(outcome: String, wake_minute: int) -> void:
	var below: float = below_lucid_seconds(_run_tier_seconds)
	var total: float = _sum(_run_tier_seconds)
	runs_detail.append({
		"run": runs,
		"seed": _run_seed,
		"seeded": _run_seeded,
		"resumed": _run_resumed,
		"outcome": outcome,
		"duration_seconds": snappedf(_run_play_seconds, 0.01),
		"wake": WakeClock.format(wake_minute) if wake_minute >= 0 else "",
		"below_lucid_seconds": snappedf(below, 0.01),
		"below_lucid_share": snappedf(below / total, 0.001) if total > 0.0 else 0.0,
		"startup_ms": _run_startup_ms,
		"load_ms": _run_load_ms,
	})


## Seconds in the tiers below Lucid (Floating to Total abandon): everything but the first tier.
static func below_lucid_seconds(seconds: Array[float]) -> float:
	return _sum(seconds) - seconds[0]


static func _sum(seconds: Array[float]) -> float:
	var total: float = 0.0
	for value: float in seconds:
		total += value
	return total


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
