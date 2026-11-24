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


## Dependency injection: call before add_child().
func setup(owner_player: Player, stat_block: StatBlock) -> void:
	player = owner_player
	stats = stat_block
	loadout = Loadout.new(self)
	tags = TagTracker.new(loadout)


func _physics_process(delta: float) -> void:
	var dt: float = delta * GameClock.scale(GameClock.Group.PLAYER)
	if dt <= 0.0:
		return
	for owned: OwnedItem in loadout.items():
		if owned.effect != null and owned.effect.wants_tick:
			owned.effect.tick(dt)


func _exit_tree() -> void:
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
