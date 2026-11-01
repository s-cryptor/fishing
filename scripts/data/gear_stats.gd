class_name GearStats
extends Resource
## Итоговые характеристики снаряжения (удочка + катушка + приманка).

@export var display_name := ""
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
