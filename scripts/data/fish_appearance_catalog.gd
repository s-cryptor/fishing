class_name FishAppearanceCatalog
extends Resource

@export var appearances: Array[FishAppearance] = []


func get_appearance(id: StringName) -> FishAppearance:
	for appearance in appearances:
		if appearance.fish_id == id:
			return appearance
	return null
