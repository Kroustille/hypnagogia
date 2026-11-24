class_name BuildCarrier
extends Node
## The build of the player (D9, P5): its StatBlock, its Loadout and its TagTracker, and the one place item effects
## listen to. The player relays its events here; no other story wires a new signal on the player.
## Child of the Player, created by Player._ready().

## A hit is about to be applied: an effect may change info.amount.
signal hit_incoming(info: DamageInfo)
## A hit was applied. lost: half-hearts removed (> 0); source: DamageInfo.Source as an int.
signal hit_taken(lost: int, source: int)
signal dash_ended
## The room has no enemy left. lowest_tier: Lucidity.Tier as an int.
signal room_cleared(room: Node, lowest_tier: int)

var player: Player
## The same object as Player.stats.
var stats: StatBlock
var loadout: Loadout
var tags: TagTracker
## Consumable effects still running (Coffee), by consumable id: one object per definition, reused when it is taken again.
var _running: Dictionary[StringName, ConsumableEffect] = {}

## What using the consumable came to: nothing to use, used, or refused (a sound, nothing spent).
enum UseResult { NONE, USED, REFUSED }


## Dependency injection: call before add_child().
func setup(owner_player: Player, stat_block: StatBlock) -> void:
	player = owner_player
	stats = stat_block
	loadout = Loadout.new(self)
	tags = TagTracker.new(loadout)
	loadout.consumable_changed.connect(_on_consumable_changed)


func _physics_process(delta: float) -> void:
	var ticks: float = GameClock.scale(GameClock.Group.PLAYER)
	var dt: float = delta * ticks
	if dt <= 0.0:
		return
	for id: StringName in _running.keys():
		var effect: ConsumableEffect = _running[id]
		effect.tick(ticks)
		if effect.is_done():
			_running.erase(id)
	for owned: OwnedItem in loadout.items():
		if owned.effect != null and owned.effect.wants_tick:
			owned.effect.tick(dt)


func _exit_tree() -> void:
	for effect: ConsumableEffect in _running.values():
		effect.cancel()
	_running.clear()
	if loadout != null:
		loadout.detach_all()


## Why this item cannot be taken now, "" when it can.
func refusal_of(def: ItemDef) -> String:
	if player == null or player.health.is_dead():
		return "dead"
	if not def.stackable and loadout.copies_of(def.id) > 0:
		return "not stackable"
	if def.max_half_hearts_delta < 0 and player.health.max_half_hearts + def.max_half_hearts_delta < Health.MIN_MAX_HALF_HEARTS:
		return "not enough hearts"
	return ""


func can_take(def: ItemDef) -> bool:
	return refusal_of(def).is_empty()


## The player takes a copy of the item: the loadout, the bus and the banner. Null (and a log) when it cannot be taken.
func acquire(def: ItemDef) -> OwnedItem:
	var refusal: String = refusal_of(def)
	if not refusal.is_empty():
		Log.warn("items", "item %s refused: %s" % [def.id, refusal])
		return null
	var owned: OwnedItem = loadout.add(def)
	var copies: int = loadout.copies_of(def.id)
	Log.info("items", "item taken %s copies=%d" % [def.id, copies])
	Events.item_acquired.emit(def.id, copies)
	Events.banner_requested.emit(def.name_key, def.bonus_key, def.cost_key)
	return owned


## True when the player can take it (alive). A carried consumable is replaced, never a refusal.
func can_take_consumable(def: ConsumableDef) -> bool:
	return def != null and player != null and not player.health.is_dead()


## The player takes the consumable: the slot, the bus and the banner. Returns the one it replaces (null when the slot was
## free): the caller puts it back on the floor.
func acquire_consumable(def: ConsumableDef) -> ConsumableDef:
	var previous: ConsumableDef = loadout.set_consumable(def)
	Log.info("items", "consumable taken %s replaced=%s" % [def.id, previous.id if previous != null else &"none"])
	Events.banner_requested.emit(def.name_key, def.bonus_key, def.cost_key)
	return previous


## Uses the carried consumable. NONE without one or when dead (silent); REFUSED when its effect says no (nothing is spent).
func use_consumable() -> UseResult:
	var def: ConsumableDef = loadout.consumable
	if def == null or player == null or player.health.is_dead():
		return UseResult.NONE
	var effect: ConsumableEffect = _running.get(def.id)
	if effect == null:
		effect = ConsumableCatalog.make_effect(def)
	if effect == null:
		Log.error("items", "consumable %s has no usable effect" % def.id)
		assert(false, "ConsumableDef.effect_script must extend ConsumableEffect")
		return UseResult.NONE
	if not effect.use(player):
		Log.info("items", "consumable %s refused" % def.id)
		return UseResult.REFUSED
	if not effect.is_done():
		_running[def.id] = effect
	Log.info("items", "consumable used %s" % def.id)
	loadout.set_consumable(null)
	return UseResult.USED


## The effect of a lasting consumable that runs now (checks), null otherwise.
func running_effect(id: StringName) -> ConsumableEffect:
	return _running.get(id)


func _on_consumable_changed(def: ConsumableDef) -> void:
	Events.consumable_changed.emit(def.id if def != null else &"", def.name_key if def != null else &"")
