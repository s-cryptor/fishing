class_name FishCatalog
extends Resource
## Список всех видов. Явный список вместо сканирования папки — так он
## одинаково работает в редакторе и в экспортированных сборках.

@export var fish: Array[FishData] = []


func get_fish(id: StringName) -> FishData:
	for f in fish:
		if f.id == id:
			return f
	return null


func for_habitat(habitat: StringName) -> Array[FishData]:
	return fish.filter(func(f: FishData) -> bool: return habitat in f.habitats)
