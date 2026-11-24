extends GutHookScript
## Runs once before the suite. The game starts in the bedroom (story 6.5); the tests that build Main expect a Run at
## launch, so the suite starts with the bedroom off. The bedroom tests turn it on themselves and put it back.
## The save files go to a temporary folder (story 6.7): the suite never writes the player's profile. post_run.gd removes it.

## The folder of this suite, for post_run.gd.
static var temp_directory: String = ""


func run() -> void:
	Main.start_in_bedroom = false
	var temp: DirAccess = DirAccess.create_temp("hypnagogia_suite", true)
	if temp == null:
		# Never fall back to user://: from the editor that would write the player's own files.
		push_error("pre_run: cannot create the temporary save folder: the suite stops")
		abort() # GUT runs nothing, user:// is never used
		(Engine.get_main_loop() as SceneTree).quit(1)
		return
	temp_directory = temp.get_current_dir()
	SaveService.set_directory(temp_directory)
