class_name PinchEffect
extends ConsumableEffect
## Pinch yourself: lucidity against half a heart of life, never armor (story 5.3). Refused at the last half-heart.


func required_params() -> Array[StringName]:
	return [&"lucidity_gain", &"half_hearts_cost"]


func use(player: Player) -> bool:
	var cost: int = roundi(param(&"half_hearts_cost"))
	if player.health.is_dead() or player.health.half_hearts - cost < 1:
		return false
	player.health.lose_half_hearts_unarmored(cost)
	player.lucidity.gain(roundi(param(&"lucidity_gain")), Lucidity.Source.CONSUMABLE)
	return true
