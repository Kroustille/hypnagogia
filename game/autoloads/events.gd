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
## telemetry (story 2.8; the cause of death is the source of the last player_hit).
@warning_ignore("unused_signal")
signal run_ended(outcome: int)

## Something asks for a new Run (F1 panel now, menus later). mode: RunOptions.Mode as an int (0 arena, 1 room);
## seed_value: used when seeded is true; room_path: scene of the room in room mode. Listener: Main.
@warning_ignore("unused_signal")
signal run_requested(mode: int, seed_value: int, seeded: bool, room_path: String)

## The last enemy of a wave died: the room has no enemy left. room: the room (Node: autoloads/ depends on no
## feature folder). lowest_tier: the room tier, the deepest Lucidity.Tier (int) reached during the wave.
## Listeners: player (lucidity), loot and item effects (epic 5).
@warning_ignore("unused_signal")
signal room_cleared(room: Node, lowest_tier: int)

## The room tier went deeper during a wave (story 3.6). tier and previous_tier: Lucidity.Tier as ints.
## Listeners: telemetry and effects (later stories); the room itself listens to the gauge, not to this.
@warning_ignore("unused_signal")
signal room_danger_raised(tier: int, previous: int)

## The player's health changed (hit, heal, armor) or a fresh player came in (initial state of a run), in half-hearts.
## Listeners: HUD (story 2.7).
@warning_ignore("unused_signal")
signal player_health_changed(half_hearts: int, max_half_hearts: int, armor: int)

## A run began (a fresh Run is ready). Listeners: telemetry (story 2.8).
@warning_ignore("unused_signal")
signal run_started

## The player answered "was this death fair?" on the wake screen. Never emitted when they restart without
## answering: the telemetry derives the absence of answer from the next run_started. Listeners: telemetry (story 2.8).
@warning_ignore("unused_signal")
signal death_judged(just: bool)

## An enemy bullet grazed the player and was counted. position: the bullet (global). gained: lucidity actually gained
## (0 once the room cap is reached). Listeners: telemetry and effects (later stories).
@warning_ignore("unused_signal")
signal player_grazed(position: Vector2, gained: int)

## The dash invulnerability avoided an enemy bullet that would have hit (per bullet). position: the bullet (global).
## gained: lucidity actually gained. Listeners: telemetry and effects (later stories).
@warning_ignore("unused_signal")
signal perfect_dash(position: Vector2, gained: int)

## The lucidity value changed, or a fresh player came in (initial state of a run). value: 0..100; tier: Lucidity.Tier
## as an int (autoloads/ depends on no feature folder). Listeners: HUD gauge (story 3.1).
@warning_ignore("unused_signal")
signal lucidity_value_changed(value: int, tier: int)

## The live lucidity tier changed, in either direction. tier and previous_tier: Lucidity.Tier as ints.
## Never emitted for the initial state. Listeners: telemetry (story 3.1); danger and effects (stories 3.5+).
@warning_ignore("unused_signal")
signal lucidity_tier_changed(tier: int, previous_tier: int)

## A power spent lucidity (story 3.3). power: the power's name (&"awakening"); cost: lucidity paid; tier: the
## Lucidity.Tier (int) the player was in before paying. Listeners: telemetry.
@warning_ignore("unused_signal")
signal lucidity_spent(power: StringName, cost: int, tier: int)

## The player came into a room of the floor (story 4.8), the first one included. room_id: the id of the room scene
## (a StringName like "onset_combat_003"); cell_x, cell_y: its cell of the floor. Listeners: telemetry, the map (4.9).
@warning_ignore("unused_signal")
signal room_entered(room_id: StringName, cell_x: int, cell_y: int)

## The seed of the run that just started (story 4.11), emitted right after run_started (whose signature stays as it is).
## seed_code: the 8 characters of RunRng.seed_code(); seeded: true when the player gave the seed (no unlocks, AR29).
## Listeners: telemetry.
@warning_ignore("unused_signal")
signal run_seeded(seed_code: String, seeded: bool)
