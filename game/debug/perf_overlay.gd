class_name PerfOverlay
extends Control
## F3 performance overlay: FPS, 1% low, window size, integer scale factor and bullet counters.
## Present in every build. Measures the engine (real delta, not GameClock) and keeps running while paused.
## Texts are technical readouts (units/abbreviations), not game text: they intentionally bypass tr().
## This exemption only applies to debug/.

const SAMPLE_COUNT: int = 1000
const REFRESH_INTERVAL: float = 0.5
const LOW_PERCENTILE: float = 0.99

var _frame_times: PackedFloat32Array = PackedFloat32Array()
var _write_index: int = 0
var _filled: int = 0
var _since_refresh: float = 0.0
var _last_ticks_usec: int = 0

@onready var _label: Label = %Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_frame_times.resize(SAMPLE_COUNT)
	_last_ticks_usec = Time.get_ticks_usec()
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_perf"):
		visible = not visible
		if visible:
			# Drop old samples (startup frames, alt-tab spikes) so the 1% low reflects what is on screen now.
			_write_index = 0
			_filled = 0
		_since_refresh = REFRESH_INTERVAL
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	# Wall-clock frame time: unaffected by Engine.time_scale.
	var now_usec: int = Time.get_ticks_usec()
	var delta: float = (now_usec - _last_ticks_usec) / 1000000.0
	_last_ticks_usec = now_usec
	_frame_times[_write_index] = delta
	_write_index = (_write_index + 1) % SAMPLE_COUNT
	_filled = mini(_filled + 1, SAMPLE_COUNT)
	if not visible:
		return
	_since_refresh += delta
	if _since_refresh < REFRESH_INTERVAL:
		return
	_since_refresh = 0.0
	_refresh_text()


func _refresh_text() -> void:
	var size: Vector2i = get_window().size
	var factor: int = Const.integer_scale(size)
	var bullets: Vector2i = _bullet_counts()
	_label.text = "FPS %d | 1%% low %d | %dx%d x%d\nBullets %d | refused %d\n%s" % [
		roundi(Engine.get_frames_per_second()),
		roundi(_one_percent_low()),
		size.x, size.y, factor,
		bullets.x, bullets.y,
		_lucidity_text(),
	]


## Live lucidity of the player in the room, or a dash when there is none (live, refreshed with the overlay).
func _lucidity_text() -> String:
	var player: Player = get_tree().get_first_node_in_group(Const.GROUP_PLAYER) as Player
	if player == null:
		return "Lucidity -"
	return "Lucidity %d (%s)" % [player.lucidity.value, Lucidity.Tier.find_key(player.lucidity.live_tier)]


## Sum of (active, refused) over every BulletManager, found by node group. Called at 2 Hz only.
func _bullet_counts() -> Vector2i:
	var active: int = 0
	var refused: int = 0
	for node: Node in get_tree().get_nodes_in_group(Const.GROUP_BULLET_MANAGERS):
		var manager: BulletManager = node as BulletManager
		if manager == null:
			continue
		active += manager.active_count
		refused += manager.refused_count
	return Vector2i(active, refused)


## FPS at the 99th percentile of recorded frame durations (sorts a copy; called twice a second only).
func _one_percent_low() -> float:
	if _filled == 0:
		return 0.0
	var sorted: PackedFloat32Array = _frame_times.slice(0, _filled)
	sorted.sort()
	var index: int = clampi(ceili(LOW_PERCENTILE * _filled) - 1, 0, _filled - 1)
	var duration: float = sorted[index]
	return 1.0 / duration if duration > 0.0 else 0.0
