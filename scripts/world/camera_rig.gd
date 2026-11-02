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
		global_position = target.global_position + Vector3(0, 0, 2.5)
	_camera.look_at(global_position)


func _process(delta: float) -> void:
	if target == null:
		return
	var goal := target.global_position
	var desired_size := 19.0
	if focus and focus.visible:
		goal = goal.lerp(focus.global_position, 0.5)
		# На дальней снасти оставляем в кадре и рыбака, и поплавок.
		var projected_distance := absf((focus.global_position - target.global_position).dot(_camera.global_basis.y))
		desired_size = maxf(19.0, projected_distance + 5.0)
	else:
		goal += Vector3(0, 0, 2.5)
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_camera.size = lerpf(_camera.size, desired_size, 1.0 - exp(-follow_speed * delta))


func snap_to_target() -> void:
	if target:
		global_position = target.global_position + Vector3(0, 0, 2.5)
