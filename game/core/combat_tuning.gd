class_name CombatTuning
extends Resource
## Balancing values of health, hits, telegraphs, spawns and enemy bullets. Read-only at runtime (see Tuning.COMBAT).
## Hearts are stored in half-hearts (integers): Health counts in whole half-hearts, no conversion needed.
## Durations are in seconds, distances in tiles; tick conversion happens in Health and Telegraph.

## Half-hearts the player starts a run with (3 hearts).
@export_range(1, 48, 1, "or_greater") var starting_half_hearts: int = 6
## Cap of heart containers plus armor, in half-hearts (12 hearts, armor included).
@export_range(1, 48, 1, "or_greater") var heart_cap_half_hearts: int = 24
## Half-hearts removed by a basic hit (floors 1 and 2).
@export_range(1, 48, 1, "or_greater") var hit_damage_half_hearts: int = 1
## Invulnerability after a hit, in seconds.
@export_range(0.0, 10.0, 0.05, "or_greater") var hit_invulnerability_duration: float = 1.0
## Shortest telegraph of any enemy attack, in seconds (FR26: also under the danger multiplier, Abandon included).
@export_range(0.0, 5.0, 0.05, "or_greater") var min_telegraph: float = 0.4
## Closest an enemy may appear to the player, in tiles (FR31), center to center.
@export_range(0.0, 20.0, 0.25, "or_greater") var min_spawn_distance: float = 3.0
## Collision radius of every enemy bullet, in tiles (4 px): the reserved look has this diameter, what is seen is what hits.
@export_range(0.05, 2.0, 0.05, "or_greater") var enemy_bullet_radius: float = 0.25
## Safety net of an enemy bullet, in seconds: not a range, walls stop every bullet well before.
@export_range(0.5, 60.0, 0.5, "or_greater") var enemy_bullet_lifetime: float = 10.0
## Half-hearts lost by a fall into a pit (story 4.3): the base of the PIT_DAMAGE stat.
@export_range(0, 48, 1, "or_greater") var pit_damage_half_hearts: int = 1
## Seconds between two recalculations of an enemy's path (story 4.5): throttled, never every frame.
@export_range(0.05, 5.0, 0.05, "or_greater") var path_refresh_interval: float = 0.4
## Paths the room's grid computes per physics tick, all enemies together (story 4.5): the others keep their path.
@export_range(1, 64, 1, "or_greater") var max_paths_per_tick: int = 4
