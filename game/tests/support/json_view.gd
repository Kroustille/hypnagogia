class_name JsonView
extends RefCounted
## Typed reads of parsed JSON for the tests (strict typing refuses a Variant where a typed value is expected).


static func d(value: Variant) -> Dictionary:
	var result: Dictionary = value
	return result


static func a(value: Variant) -> Array:
	var result: Array = value
	return result


static func n(value: Variant) -> int:
	var number: float = value
	return int(number)


static func s(value: Variant) -> String:
	var text: String = value
	return text
