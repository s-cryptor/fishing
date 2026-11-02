class_name BiomeData
extends Resource
## Описание рыбного биома. Визуальная сцена может меняться независимо,
## а рыбы привязываются к стабильному habitat.

@export var id: StringName
@export var display_name := ""
@export var habitat: StringName
@export_multiline var description := ""
@export var accent_color := Color.WHITE
