class_name CameraRig
extends Node3D
## Изометрическая камера: следует за целью, а во время рыбалки
## смещается к середине между игроком и поплавком.

@export var target: Node3D
@export var follow_speed := 5.0

## Дополнительная точка интереса (поплавок); null — смотрим только на цель.
var focus: Node3D

@onready var _camera: Camera3D = $Camera3D


func _ready() -> void:
	if target:
		global_position = target.global_position
	_camera.look_at(global_position)


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position
	if focus and focus.visible:
		goal = goal.lerp(focus.global_position, 0.5)
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
