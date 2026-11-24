class_name BulletParams
extends Resource
## Parameters of one shot. Distances are in tiles and durations in seconds (AR9):
## BulletManager.fire() converts them to pixels, the only place where that conversion happens.
## Item effects extend this in epic 5 (pierce now; rear shot, size later), one field per effect actually built.

## Travel speed, in tiles per second.
@export var speed: float = 5.5
## Collision radius, in tiles. Stored for the hit tests of later stories; unused by wall tests.
@export var radius: float = 0.25
## Seconds before the bullet disappears.
@export var lifetime: float = 8.0
## Index returned by BulletManager.add_appearance().
@export var appearance: int = 0
## Damage of one hit. ENEMY camp: half-hearts, at least 1 after rounding. PLAYER camp: enemy HP, > 0.
## BulletManager.fire() refuses a damage its target would refuse.
@export var damage: float = 0.0
## A piercing shot keeps flying after a hit and never hits the same target twice (stat PIERCE of the shooter).
@export var pierce: bool = false
