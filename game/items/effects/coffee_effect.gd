class_name CoffeeEffect
extends ConsumableEffect
## Coffee (story 5.3): a boost of speed and fire rate, then a slower walk, then nothing. Every number is a stat
## modifier owned by this object (a source holds one modifier per stat: taking it again replaces, never stacks).

enum Phase { IDLE, BOOST, CRASH }

var _stats: StatBlock
var _phase: Phase = Phase.IDLE
var _ticks_left: float = 0.0


func required_params() -> Array[StringName]:
	return [&"boost", &"boost_seconds", &"crash", &"crash_seconds"]


func use(player: Player) -> bool:
	if player.health.is_dead():
		return false
	_stats = player.stats
	_begin(Phase.BOOST)
	return true


func tick(ticks: float) -> void:
	if _phase == Phase.IDLE:
		return
	_ticks_left -= ticks
	if _ticks_left > 0.0:
		return
	if _phase == Phase.BOOST:
		_begin(Phase.CRASH)
	else:
		cancel()


func is_done() -> bool:
	return _phase == Phase.IDLE


func phase() -> Phase:
	return _phase


func cancel() -> void:
	if _stats != null:
		_stats.clear_source(self)
	_phase = Phase.IDLE
	_ticks_left = 0.0


func _begin(phase_now: Phase) -> void:
	_phase = phase_now
	var tps: float = Engine.physics_ticks_per_second
	if phase_now == Phase.BOOST:
		_ticks_left = param(&"boost_seconds") * tps
		_stats.set_modifier(self, StatBlock.Stat.MOVE_SPEED, StatBlock.Kind.ADD_PERCENT, param(&"boost"))
		_stats.set_modifier(self, StatBlock.Stat.FIRE_RATE, StatBlock.Kind.ADD_PERCENT, param(&"boost"))
	else:
		_ticks_left = param(&"crash_seconds") * tps
		_stats.set_modifier(self, StatBlock.Stat.MOVE_SPEED, StatBlock.Kind.ADD_PERCENT, -param(&"crash"))
		_stats.clear_modifier(self, StatBlock.Stat.FIRE_RATE)
