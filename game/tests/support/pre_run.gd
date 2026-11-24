extends GutHookScript
## Runs once before the suite. The game starts in the bedroom (story 6.5); the tests that build Main expect a Run at
## launch, so the suite starts with the bedroom off. The bedroom tests turn it on themselves and put it back.
## The save files go to a temporary folder (story 6.7): the suite never writes the player's profile.


func run() -> void:
	Main.start_in_bedroom = false
	var temp: DirAccess = DirAccess.create_temp("hypnagogia_suite", true)
	if temp != null:
		SaveService.set_directory(temp.get_current_dir())
