class_name FishData
extends Resource
## Описание вида рыбы. Все параметры баланса живут здесь, а не в коде.

enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

const RARITY_NAMES: Array[String] = ["Обычная", "Необычная", "Редкая", "Эпическая", "Легендарная"]
const RARITY_COLORS: Array[Color] = [
	Color("#c8d0d8"), Color("#5fd35f"), Color("#4fa3ff"), Color("#b36bff"), Color("#ffb52e"),
]

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var rarity := Rarity.COMMON
## Цвет-заглушка, пока нет моделей и иконок.
@export var color := Color.WHITE

@export_group("Вес и цена")
@export var min_weight_kg := 0.1
@export var max_weight_kg := 1.0
@export var price_per_kg := 10.0

@export_group("Поведение на крючке")
## Сила тяги 0..1 (до поправки на вес особи).
@export_range(0.0, 1.0) var strength := 0.3
## Среднее число рывков в секунду у свежей рыбы.
@export var thrash_rate := 0.3
## Запас сил в секундах борьбы.
@export var stamina := 6.0

@export_group("Появление")
@export var spawn_weight := 100.0
@export var habitats: Array[StringName] = [&"lake"]


func rarity_name() -> String:
	return RARITY_NAMES[rarity]


func rarity_color() -> Color:
	return RARITY_COLORS[rarity]


func value_for(weight_kg: float) -> int:
	return maxi(1, roundi(price_per_kg * weight_kg))
