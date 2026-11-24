class_name SaveDir
extends RefCounted
## A fresh temporary save folder for one test: points SaveService at it, and puts the previous folder back on restore().

var path: String = ""
var _previous: String = ""


func _init() -> void:
	_previous = SaveService.directory()
	var temp: DirAccess = DirAccess.create_temp("hypnagogia_save", true)
	path = temp.get_current_dir()
	SaveService.set_directory(path)


func file(name: String) -> String:
	return SaveService.path_of(name)


func restore() -> void:
	SaveService.set_directory(_previous)
	for name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(name))
	DirAccess.remove_absolute(path)
