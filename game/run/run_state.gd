class_name RunState
extends RefCounted
## What a run is about, apart from its nodes (story 4.7): the seed, whether the player chose it, the floor being played.
## Carried by the Run; the generator and the menus read it, nothing else writes it.

## The seed of the run (40 bits, see RunRng).
var run_seed: int = 0
## True when the seed was given (shared code, F1 panel) instead of drawn: such a run does not count for progression.
var seeded: bool = false
## Index of the floor being played; only the first floor exists for now.
var floor_index: int = 0
