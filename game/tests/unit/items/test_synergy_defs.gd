extends GutTest
## The synergy definitions of the Fall tag (story 5.7): valid, with the GDD values, translated, sorted by threshold.


func test_the_catalog_holds_both_levels_sorted_by_threshold() -> void:
	var all: Array[SynergyDef] = SynergyCatalog.all()
	assert_eq(all.size(), 2)
	assert_eq(all[0].id, &"fall_2")
	assert_eq(all[1].id, &"fall_3")
	for def: SynergyDef in all:
		assert_eq(SynergyCatalog.problem_of(def), "", String(def.id))
		assert_eq(def.tag, &"fall")


func test_level_two_values() -> void:
	var def: SynergyDef = load("res://data/synergies/fall_2.tres") as SynergyDef
	assert_eq(def.threshold, 2)
	assert_eq(def.params[&"shock_damage"], 15.0)
	assert_eq(def.params[&"shock_radius_tiles"], 1.5)
	assert_false(def.params.has(&"pit_damage"))


func test_level_three_values() -> void:
	var def: SynergyDef = load("res://data/synergies/fall_3.tres") as SynergyDef
	assert_eq(def.threshold, 3)
	assert_eq(def.params[&"shock_damage"], 30.0)
	assert_eq(def.params[&"shock_radius_tiles"], 2.5)
	assert_eq(def.params[&"pit_damage"], 0.0)


func test_texts_are_translated() -> void:
	for def: SynergyDef in SynergyCatalog.all():
		for key: StringName in [def.name_key, def.description_key]:
			assert_ne(tr(key), String(key), "%s has no translation" % key)


func test_a_definition_missing_a_param_of_its_effect_is_refused() -> void:
	var def: SynergyDef = (load("res://data/synergies/fall_2.tres") as SynergyDef).duplicate() as SynergyDef
	def.params = {&"shock_damage": 1.0}
	assert_ne(SynergyCatalog.problem_of(def), "")
