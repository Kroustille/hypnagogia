class_name BrokenAlarmEffect
extends ItemEffect
## Broken Alarm (story 5.8), the first active item: slows the dream around the player for a few seconds. The carrier has
## already checked the charge and spent the lucidity. The player and the player's bullets are not slowed, nor the FX.

const SOUND: AudioStream = preload("res://audio/sfx/sfx_broken_alarm.wav")
const RING_COLOR: Color = Color(0.6, 0.8, 1.0)
const RING_RADIUS_TILES: float = 6.0
const RING_DURATION: float = 0.5
const SLOWED_GROUPS: Array[GameClock.Group] = [
	GameClock.Group.ENEMIES, GameClock.Group.ENEMY_BULLETS, GameClock.Group.WORLD]


func required_params() -> Array[StringName]:
	return [&"charge_rooms", &"slow_factor", &"slow_seconds"]


func activate(player: Player) -> void:
	GameClock.apply_slow(self, SLOWED_GROUPS, param(&"slow_factor"), param(&"slow_seconds"))
	Audio.play_sfx(SOUND, 1)
	var room: Room = carrier.current_room if carrier != null else null
	if room != null and is_instance_valid(room):
		room.add_ring(player.global_position, RING_RADIUS_TILES * Const.TILE_SIZE, RING_COLOR, RING_DURATION)
