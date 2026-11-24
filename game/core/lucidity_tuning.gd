class_name LucidityTuning
extends Resource
## Balancing values of the lucidity gauge. Read-only at runtime (see Tuning.LUCIDITY).
## Gain, spend and danger values join this Resource with the stories that need them (3.2 to 3.7).

## Top of the gauge: a run starts here and gains never go above it (FR16).
@export_range(1, 1000, 1, "or_greater") var max_value: int = 100
## Lowest value of each tier, in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon, Total abandon),
## strictly decreasing, the last one being 0 (FR17: 76, 51, 26, 1, 0).
@export var tier_floors: PackedInt32Array = PackedInt32Array([76, 51, 26, 1, 0])

## Distance from the player's hurtbox rectangle under which a passing enemy bullet is a graze (tiles, FR22).
@export_range(0.1, 5.0, 0.05, "or_greater") var graze_radius: float = 1.0
## Lucidity gained by a graze.
@export_range(0, 100, 1, "or_greater") var graze_gain: int = 2
## Lucidity gained when the dash invulnerability avoids a bullet that would have hit (per bullet).
@export_range(0, 100, 1, "or_greater") var perfect_dash_gain: int = 5
## Lucidity gained when the room is cleared (a wave is emptied).
@export_range(0, 100, 1, "or_greater") var room_cleared_gain: int = 5
## Most lucidity grazes can give since Lucidity.begin_room().
@export_range(0, 1000, 1, "or_greater") var graze_cap_per_room: int = 20

## Damage bonus of the player per tier, in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon, Total abandon),
## as a fraction of the base damage (FR18: 0, +10 %, +20 %, +35 %, +35 %).
@export var tier_damage_bonus: PackedFloat32Array = PackedFloat32Array([0.0, 0.10, 0.20, 0.35, 0.35])
## Lucid tier precision: bonus on the player's shot speed (fraction of the base, FR18: +30 %).
@export_range(0.0, 5.0, 0.05, "or_greater") var lucid_shot_speed_bonus: float = 0.30
## Lucid tier precision: side of the player's hurtbox (tiles, FR18: 4 px).
@export_range(0.0625, 2.0, 0.0625, "or_greater") var lucid_hurtbox_size: float = 0.25

## Room danger (story 3.6), per room tier in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon, Total abandon).
## Multiplier on the speed of the bullets enemies fire (FR19: +10 % from Drift).
@export var danger_bullet_speed_mult: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.1, 1.1, 1.1])
## Multiplier on the duration of enemy telegraphs, never below Tuning.COMBAT.min_telegraph (FR19: x0.85 from Abandon).
@export var danger_telegraph_mult: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.0, 0.85, 0.85])
## First room tier (Lucidity.Tier, as an int) that calls reinforcements (read by story 3.7).
@export_range(0, 4, 1) var reinforcement_from_tier: int = 3
## First room tier (Lucidity.Tier, as an int) where nightmare bosses add a pattern (read from epic 6).
@export_range(0, 4, 1) var boss_extra_pattern_from_tier: int = 4
## Reinforcement (story 3.7): seconds between the announcement sign and the apparition. The minimal distance to the
## player is Tuning.COMBAT.min_spawn_distance (one rule for every spawn).
@export_range(0.1, 5.0, 0.05, "or_greater") var reinforcement_warning: float = 0.6

## Screen effects of the live tier (story 3.8), per tier in the order of Lucidity.Tier (Lucid, Floating, Drift, Abandon,
## Total abandon). Placeholders to judge in a window. They never touch gameplay.
## Wave amplitude of the decor, in pixels (0 when Lucid, strictly increasing).
@export var fx_wave: PackedFloat32Array = PackedFloat32Array([0.0, 0.5, 1.0, 1.5, 2.0])
## Chromatic aberration of the decor, in pixels (0 when Lucid, strictly increasing).
@export var fx_aberration: PackedFloat32Array = PackedFloat32Array([0.0, 0.5, 1.0, 1.5, 2.0])
## Cutoff of the low-pass filter on the Music bus, in Hz (20500 = open, strictly decreasing).
@export var fx_music_cutoff_hz: PackedFloat32Array = PackedFloat32Array([20500.0, 8000.0, 4000.0, 2000.0, 1000.0])
## Seconds an effect takes to reach a new target: never a jump.
@export_range(0.05, 5.0, 0.05, "or_greater") var fx_transition: float = 0.5
## Photosensitivity mode: highest distortion in pixels, for the wave and for the aberration.
@export_range(0.0, 5.0, 0.05, "or_greater") var fx_photosensitive_cap: float = 0.5
## Awakening screen shake (the only consumer): largest offset per axis in pixels (before the setting) and duration.
@export_range(0, 8, 1, "or_greater") var shake_pixels: int = 2
@export_range(0.05, 2.0, 0.05, "or_greater") var shake_duration: float = 0.15
