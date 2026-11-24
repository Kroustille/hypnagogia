extends GutHookScript
## Runs once before the suite. The game starts in the bedroom (story 6.5); the tests that build Main expect a Run at
## launch, so the suite starts with the bedroom off. The bedroom tests turn it on themselves and put it back.


func run() -> void:
	Main.start_in_bedroom = false
