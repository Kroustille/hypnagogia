extends GutHookScript
const PreRun: GDScript = preload("res://tests/support/pre_run.gd")
## Runs once after the suite: removes the temporary save folder pre_run.gd made.


func run() -> void:
	var path: String = PreRun.temp_directory
	if path.is_empty():
		return
	for file_name: String in DirAccess.get_files_at(path):
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name: String in DirAccess.get_directories_at(path):
		for inner: String in DirAccess.get_files_at(path.path_join(dir_name)):
			DirAccess.remove_absolute(path.path_join(dir_name).path_join(inner))
		DirAccess.remove_absolute(path.path_join(dir_name))
	DirAccess.remove_absolute(path)
