extends GutTest
## ItemCatalog: every definition of data/items is valid; a definition without a text key is refused (story 5.1, AC 2).


func test_every_item_of_the_folder_is_valid_and_in_the_catalog() -> void:
	var raw: Array[ItemDef] = ItemCatalog.load_unchecked()
	assert_gte(raw.size(), 2)
	for def: ItemDef in raw:
		assert_eq(ItemCatalog.problem_of(def), "", String(def.id))
	assert_eq(ItemCatalog.all().size(), raw.size())
	assert_not_null(ItemCatalog.by_id(&"falling_tooth"))
	assert_not_null(ItemCatalog.by_id(&"lead_legs"))
	assert_null(ItemCatalog.by_id(&"nope"))


func test_every_text_key_of_the_items_is_translated() -> void:
	for def: ItemDef in ItemCatalog.all():
		for key: StringName in [def.name_key, def.bonus_key, def.cost_key]:
			assert_ne(tr(key), String(key), "%s has no translation" % key)


func test_a_definition_without_a_name_bonus_or_cost_key_is_refused() -> void:
	var def: ItemDef = ItemDef.new()
	def.id = &"x"
	def.name_key = &"A"
	def.bonus_key = &"B"
	def.cost_key = &"C"
	assert_eq(ItemCatalog.problem_of(def), "")
	for field: String in ["name_key", "bonus_key", "cost_key"]:
		var broken: ItemDef = def.duplicate() as ItemDef
		broken.set(field, &"")
		assert_ne(ItemCatalog.problem_of(broken), "", field)
	var no_id: ItemDef = def.duplicate() as ItemDef
	no_id.id = &""
	assert_ne(ItemCatalog.problem_of(no_id), "")


func test_two_modifiers_on_one_stat_are_refused() -> void:
	var def: ItemDef = ItemDef.new()
	def.id = &"x"
	def.name_key = &"A"
	def.bonus_key = &"B"
	def.cost_key = &"C"
	var first: ModifierDef = ModifierDef.new()
	var second: ModifierDef = ModifierDef.new()
	def.modifiers = [first, second]
	assert_ne(ItemCatalog.problem_of(def), "")


func _valid_def(id: StringName) -> ItemDef:
	var def: ItemDef = ItemDef.new()
	def.id = id
	def.name_key = &"A"
	def.bonus_key = &"B"
	def.cost_key = &"C"
	return def


func test_a_positive_max_half_hearts_delta_is_refused() -> void:
	var def: ItemDef = _valid_def(&"x")
	def.max_half_hearts_delta = 2
	assert_ne(ItemCatalog.problem_of(def), "")
	def.max_half_hearts_delta = -2
	assert_eq(ItemCatalog.problem_of(def), "")


func test_a_duplicate_tag_is_refused() -> void:
	var def: ItemDef = _valid_def(&"x")
	def.tags = [&"heavy", &"heavy"]
	assert_ne(ItemCatalog.problem_of(def), "")
	def.tags = [&"heavy", &"light"]
	assert_eq(ItemCatalog.problem_of(def), "")


func test_a_duplicate_id_is_detected() -> void:
	var seen: Dictionary[StringName, bool] = {}
	assert_true(ItemCatalog.is_new_id(_valid_def(&"x"), seen))
	assert_true(ItemCatalog.is_new_id(_valid_def(&"y"), seen))
	assert_false(ItemCatalog.is_new_id(_valid_def(&"x"), seen))


func test_an_effect_without_its_params_is_refused() -> void:
	var def: ItemDef = _valid_def(&"x")
	def.effect_script = preload("res://items/effects/free_fall_effect.gd")
	assert_string_contains(ItemCatalog.problem_of(def), "rate")
	def.params = {&"rate": 0.05, &"max_bonus": 0.5, &"step_seconds": 1.0}
	assert_eq(ItemCatalog.problem_of(def), "")


func test_an_effect_script_that_is_not_an_item_effect_is_refused() -> void:
	var def: ItemDef = _valid_def(&"x")
	def.effect_script = preload("res://items/item_def.gd")
	assert_ne(ItemCatalog.problem_of(def), "")
