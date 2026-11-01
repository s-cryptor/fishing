extends Node
## Игровое время суток. Логика рыбалки получает текущую часть суток
## как входной параметр, поэтому сессия остаётся детерминированной.

signal phase_changed(phase: DayTime.Phase)

## Длительность игровых суток в реальных секундах.
@export var day_length_sec := 480.0

## Текущий час 0..24.
var hour := 7.0
var phase: DayTime.Phase


func _ready() -> void:
	if DebugTools.start_hour >= 0.0:
		hour = DebugTools.start_hour
	if DebugTools.day_length > 0.0:
		day_length_sec = DebugTools.day_length
	phase = DayTime.phase_for_hour(hour)


func _process(delta: float) -> void:
	hour = fmod(hour + delta * 24.0 / day_length_sec, 24.0)
	var new_phase := DayTime.phase_for_hour(hour)
	if new_phase != phase:
		phase = new_phase
		phase_changed.emit(phase)


func phase_name() -> String:
	return DayTime.PHASE_NAMES[phase]


func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]
