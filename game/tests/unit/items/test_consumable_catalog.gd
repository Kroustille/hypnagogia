extends GutTest
## The consumable definitions (story 5.3): every number comes from the .tres.


func test_the_catalog_holds_pinch_and_coffee() -> void:
	var ids: Array[StringName] = []
	for def: ConsumableDef in ConsumableCatalog.all():
		ids.append(def.id)
	assert_eq(ids, [&"coffee", &"pinch"] as Array[StringName])


func test_the_numbers_are_in_the_data() -> void:
	var pinch: ConsumableDef = ConsumableCatalog.by_id(&"pinch")
	assert_eq(pinch.params[&"lucidity_gain"], 25.0)
	assert_eq(pinch.params[&"half_hearts_cost"], 1.0)
	var coffee: ConsumableDef = ConsumableCatalog.by_id(&"coffee")
	assert_eq(coffee.params[&"boost"], 0.3)
	assert_eq(coffee.params[&"boost_seconds"], 10.0)
	assert_eq(coffee.params[&"crash"], 0.2)
	assert_eq(coffee.params[&"crash_seconds"], 5.0)


func test_a_missing_param_is_a_problem() -> void:
	var def: ConsumableDef = ConsumableDef.new()
	def.id = &"x"
	def.name_key = &"A"
	def.bonus_key = &"B"
	def.cost_key = &"C"
	def.effect_script = PinchEffect
	assert_string_contains(ConsumableCatalog.problem_of(def), "missing param")
	def.effect_script = null
	assert_string_contains(ConsumableCatalog.problem_of(def), "effect_script")
	assert_ne(ConsumableCatalog.problem_of(null), "")


func test_every_text_key_has_a_translation() -> void:
	for def: ConsumableDef in ConsumableCatalog.all():
		for key: StringName in [def.name_key, def.bonus_key, def.cost_key]:
			assert_ne(tr(key), String(key), "%s is translated" % key)
