extends GutTest
## A heavy hit (story 6.2, AC5): a Hitbox set up as heavy delivers a DamageInfo with is_heavy and the source RULER.

var _player: Player
var _received: Array[DamageInfo] = []


func before_each() -> void:
	_player = PlayerFactory.make(self)
	_player.global_position = Vector2(100.0, 100.0)
	_player.health.set_forced_invulnerability(false)
	_received.clear()
	_player.hurtbox.damage_received.connect(func(info: DamageInfo) -> void: _received.append(info))
	await get_tree().physics_frame


func after_each() -> void:
	_player.queue_free()


func _heavy_hitbox() -> Hitbox:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(16.0, 16.0)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.shape = shape
	var hitbox: Hitbox = Hitbox.new()
	hitbox.camp = BulletManager.Camp.ENEMY
	hitbox.add_child(shape_node)
	hitbox.setup(_player.hurtbox, Tuning.COMBAT.heavy_hit_half_hearts, DamageInfo.Source.RULER, GameClock.Group.ENEMIES, true)
	add_child(hitbox)
	hitbox.global_position = _player.global_position
	return hitbox


func test_the_heavy_tuning_is_one_heart() -> void:
	assert_eq(Tuning.COMBAT.heavy_hit_half_hearts, 2)


func test_a_heavy_hitbox_removes_a_heart_and_flags_the_info() -> void:
	var before: int = _player.health.half_hearts
	var hitbox: Hitbox = _heavy_hitbox()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(before - _player.health.half_hearts, 2, "one heart")
	assert_gte(_received.size(), 1)
	assert_true(_received[0].is_heavy)
	assert_eq(_received[0].source, DamageInfo.Source.RULER)
	hitbox.queue_free()


func test_the_armor_is_taken_first() -> void:
	_player.health.add_armor(2)
	var hearts: int = _player.health.half_hearts
	var hitbox: Hitbox = _heavy_hitbox()
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_eq(_player.health.armor, 0)
	assert_eq(_player.health.half_hearts, hearts, "the hearts are untouched")
	hitbox.queue_free()


func test_it_lands_once_while_the_hit_invulnerability_lasts() -> void:
	var before: int = _player.health.half_hearts
	var hitbox: Hitbox = _heavy_hitbox()
	for i: int in 30:
		await get_tree().physics_frame
	assert_eq(before - _player.health.half_hearts, 2, "one hit, the invulnerability of 1 s covers the pass")
	hitbox.queue_free()


func test_a_plain_hitbox_is_not_heavy() -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(16.0, 16.0)
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	shape_node.shape = shape
	var hitbox: Hitbox = Hitbox.new()
	hitbox.camp = BulletManager.Camp.ENEMY
	hitbox.add_child(shape_node)
	hitbox.setup(_player.hurtbox, 1, DamageInfo.Source.CONTACT, GameClock.Group.ENEMIES)
	add_child(hitbox)
	hitbox.global_position = _player.global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_gte(_received.size(), 1)
	assert_false(_received[0].is_heavy)
	hitbox.queue_free()


func test_the_telemetry_cause_of_the_ruler_is_ruler() -> void:
	assert_eq(str(DamageInfo.Source.find_key(DamageInfo.Source.RULER)).to_lower(), "ruler")
	assert_eq(DamageInfo.Source.RULER, 6)
