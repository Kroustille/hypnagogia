class_name Health
extends Node
## Player health, counted in whole half-hearts: hearts, armor (blue half-hearts, lost first) and the
## invulnerability that follows a hit. Runtime state component: the tuning Resources stay read-only.
## Hearts max + armor never exceed the cap. The owner (parent) listens to the local signals.
## Damage always arrives through DamageInfo -> Hurtbox.receive() -> apply_damage().

## Half-hearts, max half-hearts or armor changed.
signal changed
## Emitted once, after changed, when half-hearts reach 0.
signal died

## Margin against floating point rounding when comparing ticks.
const TICK_EPSILON: float = 1e-6
## Lowest max an item can leave: one heart (it was one heart the player had to keep to stay alive).
const MIN_MAX_HALF_HEARTS: int = 2

var half_hearts: int = 0
## Heart containers, in half-hearts. Items lower it (lose_max) and give it back (restore_max).
var max_half_hearts: int = 0
## Blue half-hearts, lost before the hearts.
var armor: int = 0
## True while nothing can add armor (story 5.9, Naked in public).
var armor_blocked: bool = false

var _cap_half_hearts: int = 0
## Half-hearts of max taken by lose_max() and not yet given back.
var _max_lost: int = 0
var _hit_ticks: float = 0.0
var _hit_ticks_left: float = 0.0
var _forced_invulnerable: bool = false
var _dead: bool = false
var _clock_group: GameClock.Group = GameClock.Group.PLAYER
var _is_setup: bool = false


## Dependency injection: call before add_child(). Inconsistent values are bounded (AR28).
func setup(
	starting_half_hearts: int,
	cap_half_hearts: int,
	hit_invulnerability_seconds: float,
	clock_group: GameClock.Group
) -> void:
	var starting: int = maxi(starting_half_hearts, 1)
	var cap: int = maxi(cap_half_hearts, starting)
	var seconds: float = hit_invulnerability_seconds
	if not is_finite(seconds) or seconds < 0.0:
		seconds = 0.0
	if starting != starting_half_hearts or cap != cap_half_hearts or seconds != hit_invulnerability_seconds:
		Log.error("combat", "Health.setup() got inconsistent values (start=%d cap=%d invulnerability=%s)" % [
			starting_half_hearts, cap_half_hearts, hit_invulnerability_seconds])
		assert(false, "Inconsistent Health tuning")
	half_hearts = starting
	max_half_hearts = starting
	armor = 0
	_cap_half_hearts = cap
	_hit_ticks = seconds * Engine.physics_ticks_per_second
	_clock_group = clock_group
	_is_setup = true


func _ready() -> void:
	if not _is_setup:
		Log.error("combat", "Health %s added without setup()" % get_path())
		assert(false, "Health.setup() must be called before add_child()")
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if _hit_ticks_left > 0.0:
		_hit_ticks_left -= GameClock.scale(_clock_group)
		if _hit_ticks_left <= TICK_EPSILON:
			_hit_ticks_left = 0.0


## Returns the half-hearts removed (armor + hearts); 0 when the hit is ignored (invulnerable, dead, invalid).
func apply_damage(info: DamageInfo) -> int:
	if not _is_setup or _dead or is_invulnerable():
		return 0
	var amount: int = 0
	if is_finite(info.amount):
		amount = roundi(info.amount)
	if amount < 1:
		Log.error("combat", "hit refused: invalid amount %s" % info.amount)
		assert(false, "Invalid damage amount")
		return 0
	var taken_armor: int = mini(amount, armor)
	var taken_hearts: int = mini(amount - taken_armor, half_hearts)
	armor -= taken_armor
	half_hearts -= taken_hearts
	if half_hearts <= 0:
		_dead = true
		_hit_ticks_left = 0.0
		changed.emit()
		died.emit()
	else:
		_hit_ticks_left = _hit_ticks
		changed.emit()
	return taken_armor + taken_hearts


## Adds armor under the cap. Returns false when nothing fits (or dead).
func add_armor(amount: int) -> bool:
	if not _check_amount(amount, "add_armor") or _dead or armor_blocked:
		return false
	var room: int = _cap_half_hearts - max_half_hearts - armor
	if room <= 0:
		return false
	armor += mini(amount, room)
	changed.emit()
	return true


## Removes all the armor (story 5.9): not a hit, no invulnerability, no player_hit. Returns the half-hearts removed.
func clear_armor() -> int:
	var removed: int = armor
	if removed == 0:
		return 0
	armor = 0
	changed.emit()
	return removed


## Lowers the max by this many half-hearts, never below MIN_MAX_HALF_HEARTS; current hearts come down to the new max
## (no hit, no invulnerability, armor untouched). Returns what was really taken.
func lose_max(amount: int) -> int:
	if not _check_amount(amount, "lose_max"):
		return 0
	var taken: int = clampi(max_half_hearts - MIN_MAX_HALF_HEARTS, 0, amount)
	if taken == 0:
		return 0
	max_half_hearts -= taken
	_max_lost += taken
	half_hearts = mini(half_hearts, max_half_hearts)
	changed.emit()
	return taken


## Gives back up to this many half-hearts of the max taken by lose_max() (the current hearts do not move: heal for those).
## Returns what was really given back.
func restore_max(amount: int) -> int:
	if not _check_amount(amount, "restore_max") or _dead:
		return 0
	var given: int = mini(amount, _max_lost)
	if given == 0:
		return 0
	max_half_hearts += given
	armor = mini(armor, maxi(_cap_half_hearts - max_half_hearts, 0))
	_max_lost -= given
	changed.emit()
	return given


## A price paid in life, not a hit (story 5.3): removes hearts only, never armor, and never the last half-heart. No
## invulnerability is read or started. Returns the half-hearts really lost.
func lose_half_hearts_unarmored(amount: int) -> int:
	if not _check_amount(amount, "lose_half_hearts_unarmored") or _dead:
		return 0
	var lost: int = clampi(half_hearts - 1, 0, amount)
	if lost == 0:
		return 0
	half_hearts -= lost
	changed.emit()
	return lost


## Heals up to max_half_hearts. Returns false when nothing fits (already full, or dead).
func heal(amount: int) -> bool:
	if not _check_amount(amount, "heal") or _dead:
		return false
	var room: int = max_half_hearts - half_hearts
	if room <= 0:
		return false
	half_hearts += mini(amount, room)
	changed.emit()
	return true


## Any reason: after a hit, or forced (debug F1).
func is_invulnerable() -> bool:
	return _forced_invulnerable or _hit_ticks_left > TICK_EPSILON


## Only the post-hit window: drives the blink.
func is_hit_invulnerable() -> bool:
	return _hit_ticks_left > TICK_EPSILON


## Full length of the post-hit invulnerability, in ticks (as bounded by setup()).
func hit_ticks_total() -> float:
	return _hit_ticks


## Ticks of post-hit invulnerability left (game ticks, weighted by the clock).
func hit_ticks_left() -> float:
	return _hit_ticks_left


func set_forced_invulnerability(enabled: bool) -> void:
	_forced_invulnerable = enabled


func is_forced_invulnerable() -> bool:
	return _forced_invulnerable


func cap_half_hearts() -> int:
	return _cap_half_hearts


func is_dead() -> bool:
	return _dead


func _check_amount(amount: int, method: String) -> bool:
	if amount > 0:
		return true
	Log.error("combat", "Health.%s() needs a positive amount, got %d" % [method, amount])
	assert(false, "Invalid amount")
	return false


## True when heal() would add something (alive and hurt).
func can_heal() -> bool:
	return not _dead and half_hearts < max_half_hearts


## True when add_armor() would add something (alive and under the cap).
func can_add_armor() -> bool:
	return not _dead and not armor_blocked and _cap_half_hearts - max_half_hearts - armor > 0


## The persistent part of the state (story 6.8): hearts, max, armor and the max lost to items. The post-hit invulnerability
## is not saved: a room replayed starts clean.
func export_state() -> Dictionary:
	return {"half_hearts": half_hearts, "max_half_hearts": max_half_hearts, "armor": armor, "max_lost": _max_lost}


## True when state has the shape export_state() makes (whole numbers, hearts above 0).
static func is_valid_state(state: Variant) -> bool:
	if typeof(state) != TYPE_DICTIONARY:
		return false
	var dict: Dictionary = state
	for key: String in ["half_hearts", "max_half_hearts", "armor", "max_lost"]:
		var value: Variant = dict.get(key)
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return false
		var number: float = value
		if not is_finite(number) or floorf(number) != number or number < 0.0 or number > 1.0e6:
			return false
	return RunState.whole(dict["half_hearts"]) >= 1 and RunState.whole(dict["max_half_hearts"]) >= MIN_MAX_HALF_HEARTS


## Puts the state back (after the items were added again: they apply their max cost, this overwrites it). Values are
## bounded by the cap. Emits changed, never died. Returns false when the state is not valid.
func restore_state(state: Dictionary) -> bool:
	if not is_valid_state(state):
		Log.error("combat", "Health.restore_state() got an invalid state")
		return false
	max_half_hearts = clampi(RunState.whole(state["max_half_hearts"]), MIN_MAX_HALF_HEARTS, _cap_half_hearts)
	half_hearts = clampi(RunState.whole(state["half_hearts"]), 1, max_half_hearts)
	armor = clampi(RunState.whole(state["armor"]), 0, maxi(_cap_half_hearts - max_half_hearts, 0))
	_max_lost = RunState.whole(state["max_lost"])
	_hit_ticks_left = 0.0
	_dead = false
	changed.emit()
	return true
