extends SceneTree
## Свободный обзор не перехватывает меню и не ломает кадрирование заброса.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var rig: Node = scene.get_node("CameraRig")
	var camera: Camera3D = rig.get_node("Camera3D")
	var controller: Node = scene.get_node("FishingController")
	var hud: Node = scene.get_node("Hud")
	var player: Node3D = scene.get_node("Player")
	await process_frame
	_check(is_equal_approx(rig._zoom_size, 19.0) and is_zero_approx(rig._desired_yaw), "начальный ракурс остаётся прежним")
	var button := InputEventMouseButton.new()
	button.button_index = MOUSE_BUTTON_RIGHT
	button.pressed = true
	rig._unhandled_input(button)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(100, 0)
	rig._unhandled_input(motion)
	_check(is_equal_approx(rig._desired_yaw, -0.6), "правая кнопка мыши поворачивает обзор")
	button.pressed = false
	rig._input(button)
	rig._unhandled_input(motion)
	_check(is_equal_approx(rig._desired_yaw, -0.6), "отпускание над GUI тоже останавливает поворот")
	button.button_index = MOUSE_BUTTON_WHEEL_UP
	button.pressed = true
	rig._unhandled_input(button)
	_check(is_equal_approx(rig._zoom_size, 17.5), "колесо приближает диораму")
	rig.zoom_view(-10000.0)
	_check(rig._zoom_size == rig.MIN_SIZE, "приближение ограничено для читаемости")
	rig.zoom_view(10000.0)
	_check(rig._zoom_size == rig.MAX_SIZE, "отдаление ограничено размером бухты")
	var reset := InputEventKey.new()
	reset.physical_keycode = KEY_HOME
	reset.pressed = true
	rig._unhandled_input(reset)
	_check(is_zero_approx(rig._desired_yaw) and rig._zoom_size == 19.0, "Home возвращает исходный вид")
	Input.action_press(&"camera_right")
	Input.action_press(&"camera_zoom_out")
	rig._process(0.5)
	Input.action_release(&"camera_right")
	Input.action_release(&"camera_zoom_out")
	_check(rig._desired_yaw < -0.7 and rig._zoom_size > 23.0, "клавиши и правый стик используют одинаковые действия камеры")
	hud._toggle_collection()
	var yaw: float = rig._desired_yaw
	var zoom: float = rig._zoom_size
	rig._unhandled_input(button)
	Input.action_press(&"camera_right")
	rig._process(0.5)
	Input.action_release(&"camera_right")
	_check(rig._desired_yaw == yaw and rig._zoom_size == zoom, "открытое меню блокирует мышь и стик камеры")
	hud._toggle_collection()
	rig.reset_view()
	_touch(rig, 0, Vector2(300, 300), true)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(350, 300)
	rig._unhandled_input(drag)
	_check(rig._zoom_size == 19.0 and rig._desired_yaw == 0.0, "один палец не меняет камеру и не мешает джойстику")
	_touch(rig, 1, Vector2(450, 300), true)
	drag.index = 1
	drag.position = Vector2(550, 300)
	rig._unhandled_input(drag)
	_check(rig._zoom_size == rig.MIN_SIZE, "разведение двух пальцев приближает вид")
	drag.position = Vector2(450, 400)
	rig._unhandled_input(drag)
	_check(absf(rig._desired_yaw) > 0.7, "поворот двух пальцев вращает обзор")
	_touch(rig, 0, Vector2(350, 300), false)
	_check(not rig._touches.has(0), "отпускание пальца очищается до обработки GUI")
	_touch(rig, 1, Vector2(450, 400), false)
	_check(rig._touches.is_empty(), "после жеста нет залипших касаний")
	rig.reset_view()
	rig.turn_view(PI * 0.5)
	rig.zoom_view(-6.0)
	rig._process(10.0)
	var offset: Vector3 = camera.global_position - rig.global_position
	_check(absf(offset.x) > 13.9 and absf(offset.z) < 0.01 and is_equal_approx(offset.y, 18.0), "орбита сохраняет безопасную высоту камеры")
	player.position = Vector3(0, 0.6, -9)
	root.get_node("GameState").equipped_gear_id = "abyss"
	controller._start_charge()
	controller._charge_time = 1.0
	controller._update_preview()
	rig._process(10.0)
	_check(camera.size >= 19.0 and camera.is_position_in_frustum(controller._preview.global_position)
		and camera.is_position_in_frustum(player.global_position + Vector3.UP), "повёрнутая приближенная камера автоматически вмещает заброс и рыбака")
	_check(camera.size > 19.0, "дальняя удочка учитывает и ширину бокового кадра")
	yaw = rig._desired_yaw
	zoom = rig._zoom_size
	rig._unhandled_input(button)
	Input.action_press(&"camera_left")
	rig._process(0.2)
	Input.action_release(&"camera_left")
	_check(rig._desired_yaw == yaw and rig._zoom_size == zoom, "во время заброса ручной обзор не сбивает прицел")
	controller._to_idle()
	controller._preview.hide()
	controller._cast_guide.hide()
	rig._process(10.0)
	_check(is_equal_approx(camera.size, rig.MIN_SIZE), "после рыбалки возвращается выбранный масштаб")
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _touch(rig: Node, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	rig._input(event)
	rig._unhandled_input(event)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
