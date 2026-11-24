extends GutTest
## The item pools (story 5.2): every item of the catalog is in the treasure pool and the shop pool.

const POOLS: Array[String] = ["res://data/pools/treasure_pool.tres", "res://data/pools/shop_pool.tres"]


func test_every_item_of_the_catalog_is_in_both_pools() -> void:
	var catalog: Array[ItemDef] = ItemCatalog.all()
	assert_gt(catalog.size(), 0)
	for path: String in POOLS:
		var pool: ItemPoolDef = load(path) as ItemPoolDef
		assert_not_null(pool, path)
		var ids: Array[StringName] = []
		for def: ItemDef in pool.items:
			assert_not_null(def, "%s holds a null item" % path)
			ids.append(def.id)
		for def: ItemDef in catalog:
			assert_true(ids.has(def.id), "%s misses %s" % [path, def.id])
		assert_eq(ids.size(), catalog.size(), "%s holds only catalog items, once each" % path)
