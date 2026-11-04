class_name DriftMessageCatalog
extends Resource

@export var messages: Array[DriftMessageData] = []


func get_message(id: StringName) -> DriftMessageData:
	for message in messages:
		if message.id == id:
			return message
	return null
