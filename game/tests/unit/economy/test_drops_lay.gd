extends GutTest
## Drops._lay survives a room freed before the deferred call (story 5.4 review).


func test_a_freed_room_is_ignored() -> void:
	var room: Room = Room.new()
	room.free()
	Drops._lay(room, Drops.Kind.SHARDS_3, Vector2.ZERO, 0)
	pass_test("no error on a freed room")


func test_a_room_outside_the_tree_is_ignored() -> void:
	var room: Room = Room.new()
	Drops._lay(room, Drops.Kind.SHARDS_3, Vector2.ZERO, 0)
	room.free()
	pass_test("no error on a room outside the tree")
