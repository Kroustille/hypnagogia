class_name WakeTuning
extends Resource
## Values of the wake time (story 6.6). Read-only at runtime (see Tuning.WAKE).

## Minute of the day the night starts at (1380 = 23:00).
@export_range(0, 1439, 1) var start_minute_of_day: int = 1380
## Minutes one phase (one floor) covers.
@export_range(1, 600, 1, "or_greater") var phase_minutes: int = 78
## A death never reads the end of the phase: it stops this many minutes before it (0 disables the cap).
@export_range(0, 600, 1, "or_greater") var death_cap_margin_minutes: int = 1


## True when the values are usable: a positive phase, a start inside the day, a margin smaller than the phase.
func is_valid() -> bool:
	return phase_minutes > 0 and start_minute_of_day >= 0 and start_minute_of_day < 1440 \
			and death_cap_margin_minutes >= 0 and death_cap_margin_minutes < phase_minutes
