class_name CameraRig
extends Node3D
## Изометрическая камера: следует за целью, а во время рыбалки
## смещается к середине между игроком и поплавком.

@export var target: Node3D
@export var follow_speed := 5.0

## Дополнительная точка интереса (поплавок); null — смотрим только на цель.
var focus: Node3D

@onready var _camera: Camera3D = $Camera3D
var _controller: Node


func _ready() -> void:
	if target:
		global_position = _idle_goal()
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
		desired_size = maxf(19.0, projected_distance * 1.75 + 5.0)
		# Подводим сцену к безопасной части экрана над нижними шкалами.
		goal -= _camera.global_basis.y * desired_size * 0.1
	else:
		goal = _idle_goal()
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_camera.size = lerpf(_camera.size, desired_size, 1.0 - exp(-follow_speed * delta))


func snap_to_target() -> void:
	if target:
		global_position = _idle_goal()


func _idle_goal() -> Vector3:
	var point := target.global_position
	if target is Player and is_instance_valid(target.ride_target):
		return point - target.ride_target.global_basis.z * 2.5
	if _controller == null:
		_controller = get_tree().get_first_node_in_group(&"fishing_controller")
	var center := Vector3.ZERO
	if _controller != null and _controller.water != null:
		center = _controller.water.global_position
	var inward := center - point
	inward.y = 0
	# На южном берегу смотрим внутрь острова, а не на пустую воду под интерфейсом.
	return point + inward.limit_length(2.5)
