class_name AwakeningTuning
extends Resource
## Balancing values of the Awakening power (story 3.3). Read-only at runtime (see Tuning.AWAKENING).

## Lucidity spent by one use.
@export_range(1, 1000, 1, "or_greater") var cost: int = 30
## Seconds before Awakening can be used again, counted in game time.
@export_range(0.0, 30.0, 0.05, "or_greater") var cooldown: float = 1.0
## Enemies closer than this to the player (tiles, center to center) are pushed back.
@export_range(0.5, 20.0, 0.1, "or_greater") var effect_radius: float = 3.0
## Distance the pushed enemies are sent back, stopped by walls and bodies (tiles).
@export_range(0.0, 20.0, 0.1, "or_greater") var knockback_distance: float = 2.0
