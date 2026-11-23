class_name WaveList
extends Resource
## The waves of a room and their rhythm (story 2.6). The runner loops back to the first wave after the last.
## Durations in seconds, slots in tiles (room coordinates, origin = top-left corner of the wall frame).
## Neutral defaults: the values live in the .tres, an empty list makes the runner inert (reported).

@export var waves: Array[WaveDef] = []
## Delay between the start of the room and the first wave.
@export_range(0.0, 60.0, 0.1, "or_greater") var start_delay: float = 0.0
## Pause between the last enemy of a wave dying and the next wave.
@export_range(0.0, 60.0, 0.1, "or_greater") var pause_duration: float = 0.0
## Fixed spawn requests, walked through in order across waves (the room moves a point that is too close or taken).
@export var spawn_slots: PackedVector2Array = PackedVector2Array()
