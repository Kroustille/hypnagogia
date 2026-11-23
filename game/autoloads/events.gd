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

## A run ended. outcome: Run.Outcome as an int (autoloads/ depends on no feature folder).
## Emitted once per run, after the Events.player_hit of the lethal hit, from the Run's handler of Player.died,
## in the tick of the lethal hit. Listeners: Main (wake screen),
## telemetry (story 2.8).
@warning_ignore("unused_signal")
signal run_ended(outcome: int)

## The last enemy of a wave died: the room has no enemy left. room: the room (Node: autoloads/ depends on no
## feature folder). The room's lowest lucidity tier joins it with the lucidity rules (epic 3).
## Listeners: loot and item effects (epic 5), telemetry (story 2.8).
@warning_ignore("unused_signal")
signal room_cleared(room: Node)

## The player's health changed (hit, heal, armor) or a fresh player came in (initial state of a run), in half-hearts.
## Listeners: HUD (story 2.7).
@warning_ignore("unused_signal")
signal player_health_changed(half_hearts: int, max_half_hearts: int, armor: int)
