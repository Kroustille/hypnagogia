class_name LenientProfessor
extends Professor
## Test double: a Professor whose failed asserts do not raise a SCRIPT ERROR, so a test can look at what happens after
## the data error is reported (the run_tests gate refuses every SCRIPT ERROR).


func _assert_failed(_message: String) -> void:
	pass
