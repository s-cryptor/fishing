class_name FishShowcase
extends Control
## Объёмный улов в собственном маленьком мире; скрытая карточка не рендерится.

var fish: FishData:
	set(value):
		fish = value
		if is_node_ready():
			_rebuild()
var _viewport: SubViewport
var _holder: Node3D
var _model: FishModel
var _time := 0.0
var _yaw := -0.22


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.size = Vector2i(440, 160)
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.handle_input_locally = false
	container.add_child(_viewport)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0, 0, 0, 0)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#c6d9cc")
	environment.environment.ambient_light_energy = 0.65
	_viewport.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -25, 0)
	sun.light_color = Color("#fff0c9")
	sun.light_energy = 0.9
	_viewport.add_child(sun)
	var camera := Camera3D.new()
	_viewport.add_child(camera)
	camera.position = Vector3(0, 0.4, 4)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.8
	camera.current = true
	_holder = Node3D.new()
	_viewport.add_child(_holder)
	visibility_changed.connect(_update_rendering)
	_update_rendering()
	if fish:
		_rebuild()


func _rebuild() -> void:
	if _model:
		_holder.remove_child(_model)
		_model.queue_free()
	_model = FishModel.new()
	_model.build(fish)
	_holder.add_child(_model)
	_yaw = -0.22
	_time = 0.0


func _update_rendering() -> void:
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED
	set_process(is_visible_in_tree())
	if _model:
		_model.set_process(is_visible_in_tree())


func _process(delta: float) -> void:
	_time += delta
	var tilt := 0.7 if fish and fish.id == &"greenland_halibut" else (0.25 if fish and fish.id == &"sawfish" else 0.0)
	_holder.rotation = Vector3(tilt, _yaw + sin(_time * 0.5) * 0.09, sin(_time * 0.7) * 0.025)
	_holder.position.y = sin(_time * 1.5) * 0.035
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_yaw += event.relative.x * 0.012
		accept_event()
	elif event is InputEventScreenDrag:
		_yaw += event.relative.x * 0.012
		accept_event()


func _draw() -> void:
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color("#204a43")
	panel.set_corner_radius_all(12)
	draw_style_box(panel, Rect2(Vector2.ZERO, size))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(0, size.y - 8), "Проведи по рыбе, чтобы рассмотреть", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, Color("#a7bca5"))
