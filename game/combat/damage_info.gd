class_name DamageInfo
extends RefCounted
## One hit, from a source to a Hurtbox. Player: half-hearts (integers). Enemies: HP (floats).
## Always delivered through Hurtbox.receive(), never by calling the target directly.

enum Source { PLAYER_SHOT } # extended by later stories (enemy bullet, contact, pit...)

var amount: float = 0.0
var source: Source = Source.PLAYER_SHOT
var is_heavy: bool = false
## Unit vector of the hit (bullet heading), ZERO if none: drives the knockback.
## Added to the architecture's list (amount, source, is_heavy) for the impact knockback of story 1.5.
var direction: Vector2 = Vector2.ZERO


static func from_bullet(bullet_amount: float, bullet_direction: Vector2, bullet_source: Source) -> DamageInfo:
	var info: DamageInfo = DamageInfo.new()
	info.amount = bullet_amount
	info.direction = bullet_direction
	info.source = bullet_source
	return info
