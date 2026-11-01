class_name ShoreBarrier
extends StaticBody3D
## Невидимая стенка по кромке круглого берега: кольцо из коротких
## коробок-коллайдеров, собранное при запуске. Когда появятся острова
## произвольной формы, заменим на коллизию из модели берега.

@export var radius := 12.6
@export var segments := 48
@export var height := 3.0
@export var thickness := 0.5


func _ready() -> void:
	var width := TAU * (radius + thickness) / segments * 1.1
	for i in segments:
		var angle := TAU * i / segments
		var box := BoxShape3D.new()
		box.size = Vector3(width, height, thickness)
		var shape := CollisionShape3D.new()
		shape.shape = box
		var center := Vector3(sin(angle), 0.0, cos(angle)) * (radius + thickness * 0.5)
		shape.transform = Transform3D(Basis(Vector3.UP, angle), center + Vector3.UP * height * 0.5)
		add_child(shape)
