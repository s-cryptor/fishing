class_name MealCatalog
extends Resource

@export var meals: Array[MealData] = []


func get_meal(id: StringName) -> MealData:
	for meal in meals:
		if meal.id == id:
			return meal
	return null
