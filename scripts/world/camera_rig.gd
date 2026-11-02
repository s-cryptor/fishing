class_name CameraRig
extends Node3D
## Изометрическая камера: следует за целью, а во время рыбалки
## смещается к середине между игроком и поплавком.

@export var target: Node3D
@export var follow_speed := 5.0
const DEFAULT_SIZE := 19.0
const MIN_SIZE := 13.0
const MAX_SIZE := 28.0
const VIEW_OFFSET := Vector3(0, 18, 14)

## Дополнительная точка интереса (поплавок); null — смотрим только на цель.
var focus: Node3D

@onready var _camera: Camera3D = $Camera3D
var _controller: Node
var _yaw := 0.0
var _desired_yaw := 0.0
var _zoom_size := DEFAULT_SIZE
var _dragging := false
var _touches: Dictionary = {}


func _ready() -> void:
	if target:
		global_position = _idle_goal()
	_camera.look_at(global_position)


func _process(delta: float) -> void:
	if target == null:
		return
	if _manual_allowed():
		turn_view(-Input.get_axis(&"camera_left", &"camera_right") * delta * 1.5)
		zoom_view(Input.get_axis(&"camera_zoom_in", &"camera_zoom_out") * delta * 9.0)
	else:
		_dragging = false
		_touches.clear()
	_yaw = lerp_angle(_yaw, _desired_yaw, 1.0 - exp(-10.0 * delta))
	_camera.position = VIEW_OFFSET.rotated(Vector3.UP, _yaw)
	_camera.look_at(global_position)
	var goal := target.global_position
	var desired_size := _zoom_size
	if focus and focus.visible:
		goal = goal.lerp(focus.global_position, 0.5)
		# На дальней снасти оставляем в кадре и рыбака, и поплавок.
		var projected_distance := absf((focus.global_position - target.global_position).dot(_camera.global_basis.y))
		desired_size = maxf(maxf(DEFAULT_SIZE, _zoom_size), projected_distance * 1.75 + 5.0)
		var horizontal := absf((focus.global_position - target.global_position).dot(_camera.global_basis.x))
		var viewport_size := get_viewport().get_visible_rect().size
		var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
		desired_size = maxf(desired_size, (horizontal * 1.25 + 5.0) / aspect)
		# Подводим сцену к безопасной части экрана над нижними шкалами.
		goal -= _camera.global_basis.y * desired_size * 0.1
	else:
		goal = _idle_goal()
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
	_camera.size = lerpf(_camera.size, desired_size, 1.0 - exp(-follow_speed * delta))


func _manual_allowed() -> bool:
	if get_tree().paused:
		return false
	if _controller == null:
		_controller = get_tree().get_first_node_in_group(&"fishing_controller")
	return _controller == null or (_controller.phase == FishingController.Phase.IDLE and not _controller.hud.is_modal_open())


func turn_view(radians: float) -> void:
	_desired_yaw = wrapf(_desired_yaw + radians, -PI, PI)


func zoom_view(amount: float) -> void:
	_zoom_size = clampf(_zoom_size + amount, MIN_SIZE, MAX_SIZE)


func reset_view() -> void:
	_desired_yaw = 0.0
	_zoom_size = DEFAULT_SIZE
	_dragging = false
	_touches.clear()


func _input(event: InputEvent) -> void:
	# Отпускание над интерфейсом тоже завершает жест, даже если GUI поглотит событие.
	if event is InputEventScreenTouch and not event.pressed:
		_touches.erase(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		_dragging = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_dragging = false
		_touches.clear()


func _unhandled_input(event: InputEvent) -> void:
	if not _manual_allowed():
		_dragging = false
		_touches.clear()
		return
	if event.is_action_pressed(&"camera_reset"):
		reset_view()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available() and not DebugTools.touch_ui:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_view(-1.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.5)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		turn_view(-event.relative.x * 0.006)
		get_viewport().set_input_as_handled()
	elif event is InputEventMagnifyGesture:
		if event.factor > 0.0:
			_zoom_size = clampf(_zoom_size / event.factor, MIN_SIZE, MAX_SIZE)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		if _touches.size() == 2:
			var indices := _touches.keys()
			var before: Vector2 = _touches[indices[1]] - _touches[indices[0]]
			_touches[event.index] = event.position
			var after: Vector2 = _touches[indices[1]] - _touches[indices[0]]
			if before.length() > 20.0 and after.length() > 20.0:
				_zoom_size = clampf(_zoom_size * before.length() / after.length(), MIN_SIZE, MAX_SIZE)
				turn_view(-wrapf(after.angle() - before.angle(), -PI, PI))
			get_viewport().set_input_as_handled()
		else:
			_touches[event.index] = event.position


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
