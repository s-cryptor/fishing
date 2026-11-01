class_name GearStats
extends Resource
## Итоговые характеристики снаряжения (удочка + катушка + приманка).

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var price := 0
## Делитель натяжения: прочная леска держит более сильные рывки.
@export var line_strength := 1.0
## Скорость подмотки, м/с.
@export var reel_speed := 1.8
@export var min_cast_m := 3.0
@export var max_cast_m := 14.0
## Сколько лески на катушке: рыба, утянувшая дальше, обрывает её.
@export var max_line_m := 25.0
## Множитель времени ожидания поклёвки (меньше — быстрее клюёт).
@export var bite_time_mult := 1.0
## Удача: повышает шанс редких видов.
@export var luck := 0.0


func stats_text() -> String:
	var text := "Леска ×%.2f · подмотка %.1f м/с · заброс до %d м · запас лески %d м" % [
		line_strength, reel_speed, roundi(max_cast_m), roundi(max_line_m)]
	if luck > 0.0:
		text += " · удача +%d%%" % roundi(luck * 100.0)
	if bite_time_mult < 1.0:
		text += " · клюёт быстрее на %d%%" % roundi((1.0 - bite_time_mult) * 100.0)
	return text
