class_name DebugPanel
extends Control
## F1 debug panel (AR24): commands on keys 1 to 9 while it is visible and the game is not paused.
## It only calls public methods of the game (Health, Hurtbox, BulletManager), never private fields.
## Instantiated by Main in debug builds only. Texts are technical readouts: they intentionally bypass tr()
## (exemption of debug/).

## Debug values of the test emitter, not GDD values.
const EMITTER_BULLET_SPEED: float = 5.0 # tiles per second
const EMITTER_BULLET_LIFETIME: float = 10.0 # seconds
const BURST_COUNT: int = 3
const BURST_SPREAD_DEGREES: float = 15.0
const AUTO_FIRE_INTERVAL: float = 0.25 # seconds
const REFRESH_INTERVAL: float = 0.25

## Debug request of the spawn commands: top center of the playable area, replaced by the room when too close.
const SPAWN_REQUEST: Vector2 = Vector2(304, 40)
const SLEEPWALKER_DEF: EnemyDef = preload("res://data/enemies/sleepwalker.tres")
const NIGHT_LIGHT_DEF: EnemyDef = preload("res://data/enemies/night_light.tres")
const LULLABY_DEF: EnemyDef = preload("res://data/enemies/lullaby.tres")
const SHEEP_DEF: EnemyDef = preload("res://data/enemies/sheep.tres")

var _auto_fire: bool = false
var _auto_ticks: float = 0.0
var _last_message: String = ""
var _since_refresh: float = 0.0
var _params: BulletParams = BulletParams.new()

@onready var _label: Label = %Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_panel"):
		visible = not visible
		_refresh_text()
		get_viewport().set_input_as_handled()
		return
	var key: InputEventKey = event as InputEventKey
	if not visible or GameClock.paused or key == null or not key.pressed or key.echo:
		return
	var handled: bool = true
	match key.physical_keycode:
		KEY_1:
			_toggle_invulnerability()
		KEY_2:
			_add_armor()
		KEY_3:
			_hit_player()
		KEY_4:
			_fire_burst()
		KEY_5:
			_toggle_auto_fire()
		KEY_6:
			_spawn(SLEEPWALKER_DEF, "sleepwalker")
		KEY_7:
			_spawn(NIGHT_LIGHT_DEF, "night light")
		KEY_8:
			_spawn(LULLABY_DEF, "lullaby")
		KEY_9:
			_spawn(SHEEP_DEF, "sheep")
		KEY_0:
			_kill_all()
		KEY_MINUS:
			_next_wave()
		_:
			handled = false
	if handled:
		_refresh_text()
		get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if not _auto_fire:
		return
	_auto_ticks += GameClock.scale(GameClock.Group.ENEMIES) # zero while paused, 4x slower under F4
	var interval_ticks: float = AUTO_FIRE_INTERVAL * Engine.physics_ticks_per_second
	if _auto_ticks + 1e-6 < interval_ticks:
		return
	_auto_ticks = 0.0
	if not _fire(1, 0.0):
		_auto_fire = false # player or manager gone (F5)
		_last_message = "auto fire stopped: %s" % _last_message # keep the cause set by _fire()


func _process(delta: float) -> void:
	if not visible:
		return
	_since_refresh += delta
	if _since_refresh >= REFRESH_INTERVAL:
		_refresh_text()


func _toggle_invulnerability() -> void:
	var player: Player = _find_player()
	if player == null:
		return
	var enabled: bool = not player.health.is_forced_invulnerable()
	player.health.set_forced_invulnerability(enabled)
	_log("invulnerability %s" % ("on" if enabled else "off"))


func _add_armor() -> void:
	var player: Player = _find_player()
	if player == null:
		return
	if player.health.add_armor(1):
		_log("armor added")
	else:
		_log("armor refused: cap reached")


func _hit_player() -> void:
	var player: Player = _find_player()
	if player == null:
		return
	var info: DamageInfo = DamageInfo.from_bullet(
		Tuning.COMBAT.hit_damage_half_hearts, Vector2.ZERO, DamageInfo.Source.DEBUG
	)
	var accepted: bool = player.hurtbox.receive(info)
	_log("hit applied" if accepted else "hit ignored (invulnerable or dead)")


## Asks the active room for the enemy of the pressed key (6 to 9).
func _spawn(def: EnemyDef, label: String) -> void:
	var room: Arena = get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Arena # never cached: F5 and restarts recreate it
	if room == null:
		_last_message = "no room"
		return
	var enemy: Enemy = room.spawn_enemy(def, SPAWN_REQUEST)
	if enemy == null:
		_log("spawn refused")
	else:
		_log("%s spawned at %s" % [label, enemy.global_position])


## Kills every living enemy of the active room, without clearing the room (no Events.room_cleared from the kill itself).
func _kill_all() -> void:
	var room: Arena = get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Arena
	if room == null:
		_last_message = "no room"
		return
	_log("%d enemies killed" % room.kill_all_enemies())


## Kills every enemy and spawns the next wave at once.
func _next_wave() -> void:
	var room: Arena = get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Arena
	var runner: WaveRunner = room.wave_runner() if room != null else null
	if runner == null:
		_log("no wave runner")
		return
	runner.force_next_wave()
	_log("next wave (%d)" % runner.wave_number())


func _fire_burst() -> void:
	if _fire(BURST_COUNT, BURST_SPREAD_DEGREES):
		_log("burst fired")


func _toggle_auto_fire() -> void:
	_auto_fire = not _auto_fire
	_auto_ticks = 0.0
	_log("auto fire %s" % ("on" if _auto_fire else "off"))


## Fires count bullets aimed at the player, spread over spread_degrees. False when no player or manager.
func _fire(count: int, spread_degrees: float) -> bool:
	var player: Player = _find_player()
	if player == null:
		return false
	var manager: BulletManager = _find_enemy_manager(player)
	if manager == null:
		_last_message = "no enemy bullet manager"
		return false
	var appearance: int = manager.add_appearance(EnemyBulletLook.texture()) # same index every time: no duplicate
	if appearance < 0:
		_last_message = "appearance refused"
		return false
	_params.appearance = appearance
	_params.speed = EMITTER_BULLET_SPEED
	_params.radius = Tuning.COMBAT.enemy_bullet_radius
	_params.lifetime = EMITTER_BULLET_LIFETIME
	_params.damage = Tuning.COMBAT.hit_damage_half_hearts
	var origin: Vector2 = Vector2((Const.ROOM_TILES.x + 2) * Const.TILE_SIZE / 2.0, 2.5 * Const.TILE_SIZE)
	var offset: Vector2 = manager.to_local(player.global_position) - origin
	if offset == Vector2.ZERO:
		return true
	var base: Vector2 = offset.normalized()
	for i: int in count:
		var angle: float = deg_to_rad(spread_degrees) * (i - (count - 1) / 2.0)
		manager.fire(_params, origin, base.rotated(angle))
	return true


func _find_player() -> Player:
	var player: Player = get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player
	if player == null:
		_last_message = "no player"
	return player


## The enemy-camp manager that can hit this player (its hurtbox is registered there): independent of the tree.
## The load test has an enemy manager but no player.
func _find_enemy_manager(player: Player) -> BulletManager:
	for node: Node in get_tree().get_nodes_in_group(Const.GROUP_BULLET_MANAGERS):
		var manager: BulletManager = node as BulletManager
		if manager != null and manager.camp == BulletManager.Camp.ENEMY and manager.has_hurtbox(player.hurtbox):
			return manager
	return null


func _log(message: String) -> void:
	_last_message = message
	Log.debug("combat", "debug panel: %s" % message)


func _refresh_text() -> void:
	_since_refresh = 0.0
	if not visible:
		return
	var player: Player = get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player
	var lines: PackedStringArray = PackedStringArray([
		"F1 panel (keys 1-9)",
		"1 invulnerable: %s" % ("on" if _invulnerable_now(player) else "off"),
		"2 +1/2 armor",
		"3 -1/2 heart",
		"4 burst x%d" % BURST_COUNT,
		"5 auto fire: %s" % ("on" if _auto_fire else "off"),
		"6 spawn sleepwalker",
		"7 spawn night light",
		"8 spawn lullaby",
		"9 spawn sheep",
		"0 kill all enemies",
		"- next wave",
	])
	if player != null:
		var health: Health = player.health
		lines.append("hearts %d/%d  armor %d  cap %d" % [
			health.half_hearts, health.max_half_hearts, health.armor, health.cap_half_hearts()])
	var room: Arena = get_tree().get_first_node_in_group(Const.GROUP_ROOM) as Arena
	if room != null:
		lines.append("enemies alive %d" % room.alive_enemy_count())
		var runner: WaveRunner = room.wave_runner()
		if runner != null:
			lines.append("wave %d %s" % [runner.wave_number(), runner.state_name().to_lower()])
	if not _last_message.is_empty():
		lines.append(_last_message)
	_label.text = "\n".join(lines)


func _invulnerable_now(player: Player) -> bool:
	return player != null and player.health.is_forced_invulnerable()

