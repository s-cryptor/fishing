class_name Player
extends CharacterBody3D

@export var move_speed := 5.0
@export var turn_speed := 12.0

var can_move := true

@onready var _model: FisherModel = $Model
@onready var rod_tip: Marker3D = $Model/RodTip


func _ready() -> void:
	add_to_group(&"player")


func _physics_process(delta: float) -> void:
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	if not can_move:
		input = Vector2.ZERO
	# Ввод относительно камеры: «вверх» — всегда от зрителя.
	var direction := Vector3(input.x, 0.0, input.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity += get_gravity() * delta
	move_and_slide()
	_model.animate_walk(direction.length_squared() > 0.01, delta)

	if direction.length_squared() > 0.01:
		var yaw := atan2(direction.x, direction.z)
		_model.rotation.y = lerp_angle(_model.rotation.y, yaw, turn_speed * delta)


## Куда смотрит персонаж (горизонтально).
func facing_direction() -> Vector3:
	var forward := _model.global_basis.z
	forward.y = 0.0
	return forward.normalized()


func fishing_pose(active: bool, charge: float, tension: float, reeling: bool) -> void:
	_model.fishing = active
	_model.charge = charge
	_model.tension = tension
	_model.reeling = reeling


func cast_gesture() -> void:
	_model.cast_kick = 1.0
