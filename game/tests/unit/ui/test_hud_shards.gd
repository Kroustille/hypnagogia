extends GutTest
## The HUD shards counter follows Events.shards_changed (story 5.4).

const HUD_SCENE: PackedScene = preload("res://ui/hud/hud.tscn")


func test_the_counter_shows_the_total_of_the_bus() -> void:
	var hud: Hud = HUD_SCENE.instantiate() as Hud
	add_child_autofree(hud)
	Events.shards_changed.emit(0)
	assert_eq(hud.shards_text(), tr(&"UI_HUD_SHARDS") % 0)
	Events.shards_changed.emit(12)
	assert_eq(hud.shards_text(), tr(&"UI_HUD_SHARDS") % 12)
