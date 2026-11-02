class_name ShoreBarrier
extends StaticBody3D
## Невидимая стенка вдоль общего фигурного контура, включая бухту.

@export var radius := 12.6
@export var segments := 96
@export var height := 3.0
@export var thickness := 0.5


func _ready() -> void:
	for i in segments:
		var angle := TAU * i / segments
		var next_angle := TAU * (i + 1) / segments
		var a := Vector3(cos(angle), 0.0, sin(angle)) * (ShoreProfile.radius_at(angle, radius + 0.2) - 0.15)
		var b := Vector3(cos(next_angle), 0.0, sin(next_angle)) * (ShoreProfile.radius_at(next_angle, radius + 0.2) - 0.15)
		var tangent := b - a
		var outward := Vector3(tangent.z, 0, -tangent.x).normalized()
		var box := BoxShape3D.new()
		box.size = Vector3(tangent.length() * 1.08, height, thickness)
		var shape := CollisionShape3D.new()
		shape.shape = box
		var center := (a + b) * 0.5
		shape.transform = Transform3D(Basis(Vector3.UP, atan2(outward.x, outward.z)), center + Vector3.UP * height * 0.5)
		add_child(shape)
