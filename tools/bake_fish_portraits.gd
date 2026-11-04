extends SceneTree
## Детерминированные PNG-портреты из игровых моделей. Запуск с графическим рендером:
## godot --path . --rendering-method gl_compatibility -s res://tools/bake_fish_portraits.gd -- --save=user://portrait-bake.json --mute

const OUTPUT := "res://assets/portraits/fish"

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var debug := root.get_node("DebugTools")
	if DisplayServer.get_name() == "headless" or debug.save_path.is_empty() or ProjectSettings.globalize_path(debug.save_path).simplify_path() == ProjectSettings.globalize_path("user://save.json").simplify_path():
		printerr("Для портретов нужен графический рендер и отдельный --save")
		quit(1)
		return
	debug.automated = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.size = Vector2i(384, 160)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#c6d9cc")
	environment.environment.ambient_light_energy = 0.65
	viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	sun.light_color = Color("#fff0c9")
	sun.light_energy = 0.9
	viewport.add_child(sun)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 0.4, 4)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.9
	camera.current = true
	var state := root.get_node("GameState")
	for fish in state.catalog.fish:
		# Модель загружается после автозагрузок и импорта внешних сцен.
		var model: Node3D = load("res://scripts/world/fish_model.gd").new()
		model.build(fish)
		var turntable := Node3D.new()
		turntable.rotation = Vector3(0.7 if fish.id == &"greenland_halibut" else (0.25 if fish.id == &"sawfish" else 0.0), -0.22, 0)
		viewport.add_child(turntable)
		turntable.add_child(model)
		model.position = -model.presentation_center()
		model._process(0.35)
		model.set_process(false)
		for player: AnimationPlayer in model.find_children("*", "AnimationPlayer", true, false):
			player.process_mode = Node.PROCESS_MODE_DISABLED
			player.seek(0.35, true)
		for frame in 4:
			await process_frame
		RenderingServer.force_draw(false)
		var error := viewport.get_texture().get_image().save_png(OUTPUT.path_join(String(fish.id) + ".png"))
		if error != OK:
			printerr("Не удалось сохранить портрет %s: %s" % [fish.id, error_string(error)])
			quit(1)
			return
		print("Портрет: %s" % fish.id)
		turntable.queue_free()
		await process_frame
	viewport.queue_free()
	await process_frame
	quit()
