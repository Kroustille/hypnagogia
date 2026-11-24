class_name DiveEffect
extends SynergyEffect
## Fall synergy (story 5.7): each dash ends with a shockwave at the arrival point. Both levels share this class, the
## params change: shock_damage, shock_radius_tiles, and optionally pit_damage (a factor on the fall's hit, 0 = free fall).

const SHOCKWAVE_SOUND: AudioStream = preload("res://audio/sfx/sfx_shockwave.wav")
const RING_COLOR: Color = Color(0.85, 0.7, 0.4)
const RING_DURATION: float = 0.35


func required_params() -> Array[StringName]:
	return [&"shock_damage", &"shock_radius_tiles"]


func attach(new_carrier: BuildCarrier, new_def: SynergyDef) -> void:
	if carrier != null:
		return
	super.attach(new_carrier, new_def)
	carrier.dash_ended.connect(_on_dash_ended)
	if def.params.has(&"pit_damage"):
		carrier.stats.set_modifier(self, StatBlock.Stat.PIT_DAMAGE, StatBlock.Kind.MULTIPLY, param(&"pit_damage"))


func detach() -> void:
	if carrier == null:
		return
	carrier.dash_ended.disconnect(_on_dash_ended)
	carrier.stats.clear_source(self)
	super.detach()


func _on_dash_ended() -> void:
	var room: Room = carrier.current_room
	if room == null or not is_instance_valid(room) or carrier.player == null:
		return
	var radius_px: float = param(&"shock_radius_tiles") * Const.TILE_SIZE
	var hit: int = room.shockwave(carrier.player.global_position, radius_px, param(&"shock_damage"), RING_COLOR, RING_DURATION)
	Audio.play_sfx(SHOCKWAVE_SOUND, 1)
	Log.debug("combat", "dive shockwave %s radius=%.0f damage=%s hit=%d" % [def.id, radius_px, param(&"shock_damage"), hit])
