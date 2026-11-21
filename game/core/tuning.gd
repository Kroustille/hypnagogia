@abstract
class_name Tuning
## Static access point to balancing Resources stored in res://data/tuning/.
## Each story adds its own Resource here. They are read-only at runtime: never assign to them.

const PLAYER: PlayerTuning = preload("res://data/tuning/player_tuning.tres")
const DASH: DashTuning = preload("res://data/tuning/dash_tuning.tres")
const SHOT: ShotTuning = preload("res://data/tuning/shot_tuning.tres")
