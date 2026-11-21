class_name DamageNumbers
extends Node2D
## World layer of a room's damage numbers (FR6, off by default in Settings). Listens to
## Events.enemy_damaged, so a number outlives its target. One number per hit, no merging: each new number
## takes the next horizontal offset of a fixed cycle, so close numbers stay readable (deterministic, no RNG).
## The setting is read on every hit: turning it on takes effect on the next hit, turning it off lets the
## numbers on screen finish.

## Starting point above the top center of the hurtbox, in pixels (visual, placeholder until epic 7).
const SPAWN_OFFSET: Vector2 = Vector2(0.0, -2.0)
## Horizontal offsets cycled through, one per number, in pixels (visual, placeholder until epic 7).
const X_OFFSETS: PackedFloat32Array = [0.0, -6.0, 6.0, -3.0, 3.0]

var _next_offset: int = 0


## On every entry: the arena is rebuilt by F5, and a layer out of the tree must not listen.
func _enter_tree() -> void:
	Events.enemy_damaged.connect(_on_events_enemy_damaged)


func _exit_tree() -> void:
	Events.enemy_damaged.disconnect(_on_events_enemy_damaged)


func _on_events_enemy_damaged(world_position: Vector2, amount: float) -> void:
	if not Settings.damage_numbers:
		return
	var number: DamageNumber = DamageNumber.new()
	number.setup(amount) # before add_child()
	number.position = (to_local(world_position) + SPAWN_OFFSET + Vector2(X_OFFSETS[_next_offset], 0.0)).round()
	_next_offset = (_next_offset + 1) % X_OFFSETS.size()
	add_child(number)
