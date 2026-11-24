class_name PlayerFactory
extends RefCounted
## Test aid (story 5.3): a bare Player in the test tree, with no room, for logic that reads its health, lucidity and stats.

const PLAYER_SCENE: PackedScene = preload("res://player/player.tscn")


static func make(parent: Node) -> Player:
	var player: Player = PLAYER_SCENE.instantiate() as Player
	parent.add_child(player)
	return player
