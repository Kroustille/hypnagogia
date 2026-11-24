class_name ReinforcementSpawn
extends Marker2D
## Where a reinforcement may appear (story 3.7). Child of the room's ReinforcementSpawns node.


func _enter_tree() -> void:
	add_to_group(Const.GROUP_REINFORCEMENT_SPAWN)
