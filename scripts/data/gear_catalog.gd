class_name GearCatalog
extends Resource
## Удочки, которые продаются в магазине. Первая — стартовая.

@export var rods: Array[GearStats] = []


func get_rod(id: StringName) -> GearStats:
	for rod in rods:
		if rod.id == id:
			return rod
	return null
