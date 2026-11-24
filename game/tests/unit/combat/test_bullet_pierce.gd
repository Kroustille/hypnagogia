extends GutTest
## A piercing player shot goes through every target on its way and never hits the same one twice (story 5.1, AC 6, 8).

var _manager: BulletManager
var _hits: Dictionary[Hurtbox, int] = {}


func before_each() -> void:
	_manager = BulletManager.new()
	_manager.camp = BulletManager.Camp.PLAYER
	_manager.capacity = 8
	_manager.setup([])
	add_child_autofree(_manager)
	_hits = {}


func _add_target(x: float, stops_piercing: bool = false) -> Hurtbox:
	var hurtbox: Hurtbox = Hurtbox.new()
	hurtbox.stops_piercing = stops_piercing
	hurtbox.camp = BulletManager.Camp.ENEMY
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(12, 12)
	shape_node.shape = shape
	hurtbox.add_child(shape_node)
	hurtbox.position = Vector2(x, 0)
	add_child_autofree(hurtbox)
	hurtbox.damage_received.connect(func(_info: DamageInfo) -> void: _hits[hurtbox] = _hits.get(hurtbox, 0) + 1)
	_manager.register_hurtbox(hurtbox)
	return hurtbox


func _count(target: Hurtbox) -> int:
	return _hits.get(target, 0)


func _shoot(pierce: bool) -> void:
	var params: BulletParams = BulletParams.new()
	params.speed = 10.0
	params.damage = 5.0
	params.lifetime = 5.0
	params.pierce = pierce
	params.appearance = _manager.add_appearance(ImageTexture.create_from_image(Image.create(4, 4, false, Image.FORMAT_RGBA8)))
	assert_true(_manager.fire(params, Vector2.ZERO, Vector2.RIGHT))


func test_a_piercing_shot_hits_each_of_two_targets_exactly_once() -> void:
	var first: Hurtbox = _add_target(60.0)
	var second: Hurtbox = _add_target(100.0)
	_shoot(true)
	for i: int in 360:
		_manager._physics_process(1.0 / 60.0)
	assert_eq(_count(first), 1, "the bullet spends several ticks inside the first target")
	assert_eq(_count(second), 1)
	assert_eq(_manager.active_count, 0, "it flew on until its life ended")


func test_an_ordinary_shot_stops_at_the_first_target() -> void:
	var first: Hurtbox = _add_target(60.0)
	var second: Hurtbox = _add_target(100.0)
	_shoot(false)
	for i: int in 360:
		_manager._physics_process(1.0 / 60.0)
	assert_eq(_count(first), 1)
	assert_eq(_count(second), 0)


func test_the_memory_of_a_slot_does_not_leak_to_the_next_bullet() -> void:
	var first: Hurtbox = _add_target(60.0)
	_shoot(true)
	for i: int in 360:
		_manager._physics_process(1.0 / 60.0)
	_shoot(true) # same slot again
	for i: int in 360:
		_manager._physics_process(1.0 / 60.0)
	assert_eq(_count(first), 2, "one hit per bullet")


func test_a_piercing_shot_is_stopped_by_furniture_but_not_by_the_lamp() -> void:
	var lamp: Hurtbox = _add_target(40.0) # a trigger: pierced
	var furniture: Hurtbox = _add_target(80.0, true)
	var behind: Hurtbox = _add_target(120.0)
	_shoot(true)
	for i: int in 360:
		_manager._physics_process(1.0 / 60.0)
	assert_eq(_count(lamp), 1)
	assert_eq(_count(furniture), 1, "the furniture takes the hit")
	assert_eq(_count(behind), 0, "and the bullet ends there")
	assert_eq(_manager.active_count, 0)
