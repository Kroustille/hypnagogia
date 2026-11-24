extends GutTest
## Furniture (story 4.4, AC 1 to 4): a solid body that stops the shots of both camps, loses their damage as hit points,
## and blocks nothing once destroyed. Played in a start room without enemies (bed at (4, 4), desk at (10, 12)).

const ROOM: String = "res://tests/fixtures/rooms/furniture_room.tscn"
const SLEEPWALKER: String = "res://data/enemies/sleepwalker.tres"

var _harness: RoomHarness
var _bed: Furniture
var _desk: Furniture


func before_each() -> void:
	_harness = RoomHarness.new()
	add_child(_harness)
	_harness.start(ROOM)
	for piece: Furniture in _harness.room.furnitures():
		if piece.def.id == &"bed":
			_bed = piece
		elif piece.def.id == &"desk":
			_desk = piece
	await _harness.ticks(2)


func after_each() -> void:
	_harness.release()


## A shot aimed at the middle of the piece's left side, from RUN_UP_TILES to its left.
func _shoot_at(piece: Furniture, manager: BulletManager, count: int = 1) -> void:
	var rect: Rect2 = piece.footprint_rect()
	var origin: Vector2 = Vector2(rect.position.x - 2.0 * Const.TILE_SIZE, rect.get_center().y)
	for i: int in count:
		assert_true(_harness.fire_shot(manager, origin, Vector2.RIGHT), "shot %d fired" % i)


func test_furniture_comes_from_its_def_with_30_hit_points_and_a_solid_body_on_its_layer() -> void:
	assert_eq(_bed.def.max_hp, 30.0)
	assert_eq(_bed.hp.current, 30.0)
	assert_eq(_bed.footprint_rect().size, Vector2(3, 2) * Const.TILE_SIZE, "the def's size in tiles")
	var body: StaticBody2D = _bed.get_node("Body") as StaticBody2D
	assert_eq(body.collision_layer, Const.LAYER_FURNITURE)
	var shape: RectangleShape2D = (body.get_node("Shape") as CollisionShape2D).shape as RectangleShape2D
	assert_eq(shape.size, _bed.footprint_rect().size)
	assert_true(_harness.room.player_bullets().has_hurtbox(_bed.player_shot_hurtbox), "hit by the player's shots")
	assert_true(_harness.room.enemy_bullets().has_hurtbox(_bed.enemy_shot_hurtbox), "hit by the enemies' shots")
	assert_eq(_bed.player_shot_hurtbox.camp, BulletManager.Camp.ENEMY)
	assert_eq(_bed.enemy_shot_hurtbox.camp, BulletManager.Camp.PLAYER)


func test_a_player_shot_is_stopped_and_costs_the_piece_the_bullet_damage() -> void:
	var manager: BulletManager = _harness.room.player_bullets()
	_shoot_at(_bed, manager)
	await _harness.ticks(30)
	assert_eq(manager.active_count, 0, "the shot disappeared")
	assert_eq(_bed.hp.current, 29.0, "1 damage lost")
	assert_false(_bed.is_destroyed())


func test_an_enemy_shot_is_stopped_and_a_half_heart_is_one_hit_point() -> void:
	var manager: BulletManager = _harness.room.enemy_bullets()
	_shoot_at(_bed, manager)
	await _harness.ticks(30)
	assert_eq(manager.active_count, 0, "the shot disappeared")
	assert_eq(_bed.hp.current, 29.0)


func test_furniture_has_no_hitbox_so_it_hurts_nobody() -> void:
	assert_eq(_bed.find_children("*", "Hitbox", true, false).size(), 0)


func test_the_30th_hit_destroys_it_once_and_the_shots_of_that_tick_are_consumed() -> void:
	watch_signals(_bed)
	_shoot_at(_bed, _harness.room.player_bullets(), 31) # 31 shots at the same spot: they all arrive in the same tick
	await _harness.ticks(30)
	assert_true(_bed.is_destroyed())
	assert_eq(_bed.hp.current, 0.0, "the 31st shot found nothing to hit")
	assert_signal_emit_count(_bed, "destroyed", 1)
	assert_eq(_harness.room.player_bullets().active_count, 0, "all 31 shots were consumed")


func test_a_destroyed_piece_blocks_neither_shots_nor_bodies() -> void:
	_shoot_at(_bed, _harness.room.player_bullets(), 30)
	await _harness.ticks(30)
	assert_true(_bed.is_destroyed())
	var body: StaticBody2D = _bed.get_node("Body") as StaticBody2D
	assert_eq(body.collision_layer, 0, "no longer on the furniture layer")
	assert_false(_bed.player_shot_hurtbox.is_hittable())
	assert_false(_bed.enemy_shot_hurtbox.is_hittable())
	for manager: BulletManager in [_harness.room.player_bullets(), _harness.room.enemy_bullets()]:
		_shoot_at(_bed, manager)
	await _harness.ticks(45)
	assert_eq(_harness.room.player_bullets().active_count, 1, "the player's shot crossed the place of the bed")
	assert_eq(_harness.room.enemy_bullets().active_count, 1, "so did the enemy shot")


func test_the_player_and_an_enemy_are_stopped_by_it_until_it_is_destroyed() -> void:
	var def: EnemyDef = load(SLEEPWALKER) as EnemyDef
	var rect: Rect2 = _desk.footprint_rect()
	var enemy: Enemy = _harness.room.spawn_enemy(def, _harness.room.to_local(Vector2(rect.position.x - 3.0 * Const.TILE_SIZE, rect.get_center().y)))
	assert_not_null(enemy)
	_harness.player.global_position = Vector2(rect.end.x + 3.0 * Const.TILE_SIZE, rect.get_center().y)
	await _harness.ticks(2)
	var toward_desk: Vector2 = Vector2(rect.size.x + 6.0 * Const.TILE_SIZE, 0)
	assert_true(_harness.player.test_move(_harness.player.global_transform, -toward_desk), "the player is stopped (from the right)")
	assert_true(enemy.test_move(enemy.global_transform, toward_desk), "the enemy is stopped (from the left)")
	enemy.set_physics_process(false) # it stays where it is for the rest of the test
	_shoot_at(_desk, _harness.room.player_bullets(), 30)
	await _harness.ticks(30)
	assert_true(_desk.is_destroyed())
	assert_false(_harness.player.test_move(_harness.player.global_transform, -toward_desk * 0.5), "the player walks through the place of the desk")
	assert_false(enemy.test_move(enemy.global_transform, toward_desk * 0.5), "so does the enemy")


func test_an_enemy_never_appears_on_furniture() -> void:
	var def: EnemyDef = load(SLEEPWALKER) as EnemyDef
	var enemy: Enemy = _harness.room.spawn_enemy(def, _harness.room.to_local(_bed.footprint_rect().get_center()))
	assert_not_null(enemy)
	assert_false(enemy.body_world_rect().intersects(_bed.footprint_rect()), "moved off the bed")
	var again: Enemy = _harness.room.spawn_enemy(def, _harness.room.to_local(_bed.footprint_rect().get_center()))
	assert_not_null(again)
	_shoot_at(_bed, _harness.room.player_bullets(), 30)
	await _harness.ticks(30)
	var third: Enemy = _harness.room.spawn_enemy(def, _harness.room.to_local(_bed.footprint_rect().get_center()))
	assert_not_null(third)
	assert_almost_eq(third.global_position, _bed.footprint_rect().get_center(), Vector2(0.01, 0.01), "once destroyed it is a free place")


func test_glide_stops_before_furniture_and_goes_through_once_destroyed() -> void:
	var rect: Rect2 = _bed.footprint_rect()
	var origin: Vector2 = Vector2(rect.position.x - 4.0 * Const.TILE_SIZE, rect.get_center().y)
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(8, 8)
	var distance: float = 8.0 * Const.TILE_SIZE
	var space: PhysicsDirectSpaceState2D = _harness.player.get_world_2d().direct_space_state
	var destination: Vector2 = Glide.resolve_destination(space, origin, Vector2.RIGHT, distance, shape, [])
	assert_lt(destination.x + 4.0, rect.position.x + 0.01, "stopped on the near side of the bed")
	assert_gt(destination.x, origin.x, "but it did move")
	_shoot_at(_bed, _harness.room.player_bullets(), 30)
	await _harness.ticks(30)
	space = _harness.player.get_world_2d().direct_space_state
	destination = Glide.resolve_destination(space, origin, Vector2.RIGHT, distance, shape, [])
	assert_almost_eq(destination.x, origin.x + distance, 0.01, "the whole distance once the bed is gone")


func test_a_charging_sheep_is_stopped_by_furniture_without_being_stunned() -> void:
	var rect: Rect2 = _desk.footprint_rect()
	var def: EnemyDef = load("res://data/enemies/sheep.tres") as EnemyDef
	var y: float = rect.get_center().y
	var sheep: Sheep = _harness.room.spawn_enemy(def, _harness.room.to_local(Vector2(rect.position.x - 6.0 * Const.TILE_SIZE, y))) as Sheep
	assert_not_null(sheep)
	_harness.player.global_position = Vector2(rect.end.x + 4.0 * Const.TILE_SIZE, y) # the charge aims across the desk
	var charged: bool = await _harness.until(func() -> bool: return sheep._state == Sheep.State.CHARGE, 600)
	assert_true(charged, "it charged")
	var stopped: bool = await _harness.until(func() -> bool: return sheep._state != Sheep.State.CHARGE, 200)
	assert_true(stopped, "the charge ended")
	assert_ne(sheep._state, Sheep.State.STUN, "furniture does not stun")
	assert_lt(sheep.body_world_rect().end.x, rect.position.x + 1.0, "it stayed on the near side of the desk")
