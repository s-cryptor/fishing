class_name DriftMessageData
extends Resource
## Письмо на воде: место поиска, подсказка и небольшая глава общей истории.

@export var id: StringName
@export var title := ""
@export var habitat: StringName
@export var position := Vector3.ZERO
@export var clue := ""
@export_multiline var body := ""
