extends SceneTree
## Прицел при удержании: мышь и движение поворачивают удочку, не двигая рыбака.

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene := load("res://scenes/main.tscn").instantiate() as Node3D
	root.add_child(scene)
	var controller: Node = scene.get_node("FishingController")
	var player: Node3D = scene.get_node("Player")
	var camera: Camera3D = scene.get_node("CameraRig/Camera3D")
	var debug := root.get_node("DebugTools")
	player.position = Vector3(0, 0.6, -9)
	await create_timer(0.3).timeout
	_check(not controller.aim_at_screen(Vector2(640, 200)), "вне зарядки мышь не меняет направление заброса")
	Input.action_press(&"fish_action")
	controller._start_charge()
	_check(controller.camera_rig.focus == controller._preview and controller._cast_guide.visible,
		"при зарядке камера следует за маркером и показывает дугу")
	var start := Vector2(player.position.x, player.position.z)
	Input.action_press(&"move_right")
	await create_timer(0.3).timeout
	Input.action_release(&"move_right")
	_check(player.facing_direction().dot(Vector3.RIGHT) > 0.95, "клавиши движения поворачивают прицел")
	_check(Vector2(player.position.x, player.position.z).distance_to(start) < 0.01, "прицеливание не двигает персонажа")
	var target := Vector3(5, 0, -23)
	var motion := InputEventMouseMotion.new()
	motion.position = camera.unproject_position(target)
	motion.relative = Vector2(10, 4)
	controller._unhandled_input(motion)
	var desired := (target - Vector3(player.position.x, 0, player.position.z)).normalized()
	_check(player.facing_direction().dot(desired) > 0.999, "мышь проецируется на водную плоскость")
	controller._charge_time = 0.95
	controller._update_preview()
	controller.camera_rig._process(10.0)
	_check(camera.is_position_in_frustum(controller._preview.global_position) and camera.is_position_in_frustum(player.global_position + Vector3.UP),
		"маркер дальней зарядки и рыбак остаются в кадре")
	Input.action_release(&"fish_action")
	controller._release_cast()
	_check(controller.session != null and controller._cast_dir.dot(desired) > 0.999, "выбранное направление используется при создании заброса")
	_check(not controller._preview.visible and not controller._cast_guide.visible, "после отпускания предпросмотр скрывается")
	await create_timer(0.8).timeout
	controller._end_session()
	controller._to_idle()
	var old_touch: bool = debug.touch_ui
	debug.touch_ui = true
	Input.action_press(&"fish_action")
	controller._start_charge()
	var before_touch: Vector3 = player.facing_direction()
	motion.position = Vector2(1100, 550)
	controller._unhandled_input(motion)
	_check(player.facing_direction().is_equal_approx(before_touch), "эмуляция мыши от тач-кнопки не уводит прицел")
	Input.action_press(&"move_left")
	controller._aim_with_movement(1.0)
	Input.action_release(&"move_left")
	_check(player.facing_direction().dot(Vector3.LEFT) > 0.99, "тач-джойстик и стик используют тот же прицел движения")
	controller._charge_time = 0.0
	Input.action_release(&"fish_action")
	controller._release_cast()
	_check(controller.phase == 0 and controller.camera_rig.focus == null and not controller._cast_guide.visible,
		"неудачный заброс на сушу полностью убирает прицел")
	debug.touch_ui = old_touch
	scene.queue_free()
	await process_frame
	quit(1 if _failures else 0)


func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
