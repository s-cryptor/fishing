class_name LandmarkCatalog
extends Resource

@export var landmarks: Array[LandmarkData] = []


func get_landmark(id: StringName) -> LandmarkData:
	for landmark in landmarks:
		if landmark.id == id:
			return landmark
	return null
