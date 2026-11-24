extends GutTest
## RoomBuilder (stories 4.2 and 4.7): headers, phase, wave range, stable ids.

const TEXT_HEAD: String = "type: combat\nsize: screen\n"
var _builder: RoomBuilder


func before_each() -> void:
	_builder = RoomBuilder.new()


func after_each() -> void:
	_builder.free()


func _grid() -> String:
	var rows: PackedStringArray = PackedStringArray()
	for y: int in 19:
		rows.append(".".repeat(36))
	return "\n".join(rows)


func _build(text: String, errors: PackedStringArray) -> Room:
	return _builder.build(text, errors)


func test_the_phase_header_is_read() -> void:
	var errors: PackedStringArray = PackedStringArray()
	var room: Room = _build("phase: dream\n" + TEXT_HEAD + _grid() + "\ndoor N\n", errors)
	assert_eq(errors, PackedStringArray())
	assert_eq(room.phase, &"dream")
	room.free()


func test_a_bad_phase_is_an_error() -> void:
	var errors: PackedStringArray = PackedStringArray()
	_build("phase: Bad Phase\n" + TEXT_HEAD + _grid() + "\ndoor N\n", errors).free()
	assert_true(errors.size() > 0)


func test_a_line_with_a_colon_that_is_not_a_header_is_an_unknown_line() -> void:
	var errors: PackedStringArray = PackedStringArray()
	_build(TEXT_HEAD + _grid() + "\ndoor N\nfurniture bed 3 4 : the note\n", errors).free()
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("furniture needs"), errors[0]) # read as a furniture line, not as a header


func test_a_wave_outside_the_range_is_an_error() -> void:
	var errors: PackedStringArray = PackedStringArray()
	_build(TEXT_HEAD + _grid() + "\ndoor N\nspawn sleepwalker 21 5 5\n", errors).free()
	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("wave 21"), errors[0])
	var fine: PackedStringArray = PackedStringArray()
	_build(TEXT_HEAD + _grid() + "\ndoor N\nspawn sleepwalker 20 5 5\n", fine).free()
	assert_eq(fine, PackedStringArray())


func test_the_nightmare_type_alone_makes_a_nightmare_room() -> void:
	var errors: PackedStringArray = PackedStringArray()
	var room: Room = _build("type: nightmare\nsize: screen\n" + _grid() + "\ndoor N\n", errors)
	assert_true(room.is_nightmare())
	room.room_type = Room.RoomType.COMBAT
	assert_false(room.is_nightmare())
	room.free()


func test_stable_ids_replace_the_random_ones() -> void:
	var one: String = '[ext_resource type="Script" path="res://a.gd" id="1_abcde"]\n[ext_resource type="Script" path="res://b.gd" id="2_zzzzz"]\n' \
		+ '[node name="Room" type="Node2D" unique_id=111]\nscript = ExtResource("1_abcde")\n' \
		+ '[node name="Door" type="Node2D" parent="Doors" unique_id=222]\nscript = ExtResource("2_zzzzz")\n'
	var two: String = one.replace("1_abcde", "1_qwert").replace("2_zzzzz", "2_poiuy").replace("=111", "=999").replace("=222", "=888")
	var stable: String = RoomBuilder.stable_ids(one)
	assert_eq(RoomBuilder.stable_ids(two), stable, "the random parts do not reach the result")
	assert_false(stable.contains("abcde"))
	assert_true(stable.contains('id="1_'), "the numeric prefix stays")
	assert_false(stable.contains("unique_id=111"))
	var references: int = stable.count('ExtResource("1_')
	assert_eq(references, 1, "the reference follows the renamed id")
	assert_true(stable.contains('id="%s"' % stable.get_slice('ExtResource("', 1).get_slice('"', 0)))


func test_a_pool_room_builds_the_same_file_twice() -> void:
	var source: String = "res://tests/fixtures/rooms/valid.txt"
	var first: String = _built_text(source)
	var second: String = _built_text(source)
	assert_false(first.is_empty())
	assert_eq(first, second)


func _built_text(source: String) -> String:
	var output: String = "user://builder_test.tscn"
	assert_eq(_builder.run(source, output), 0)
	var text: String = FileAccess.get_file_as_string(output)
	DirAccess.remove_absolute(output)
	return text


func test_a_failed_build_writes_nothing() -> void:
	var source: String = "user://builder_bad.txt"
	var file: FileAccess = FileAccess.open(source, FileAccess.WRITE)
	file.store_string(TEXT_HEAD + _grid() + "\ndoor N\nspawn dragon 0 5 5\n")
	file.close()
	var output: String = "user://builder_bad.tscn"
	assert_eq(_builder.run(source, output), 1)
	assert_false(FileAccess.file_exists(output))
	DirAccess.remove_absolute(source)
