extends Node
## Global signal bus: cross-cutting notifications only. Primitive types in signatures (autoloads/ depends
## on no feature folder). Signals are added by the stories that need them.

## The player took a hit. damage: half-hearts removed (armor included). source: DamageInfo.Source as an int
## (autoloads/ depends on no feature folder). Listeners: lucidity rules, HUD, telemetry (later stories).
@warning_ignore("unused_signal")
signal player_hit(damage: int, source: int)

## An enemy hurtbox took damage. world_position: top center of its rectangle (damage numbers, telemetry).
@warning_ignore("unused_signal")
signal enemy_damaged(world_position: Vector2, amount: float)
