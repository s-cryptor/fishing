extends Node3D
## Небольшие живые детали без текстур: дым из трубы и чайки над водой.

var _smoke: Array[MeshInstance3D] = []
var _birds: Array[Node3D] = []
var _time := 0.0
var _fireflies: MultiMeshInstance3D


func _ready() -> void:
	for i in 6:
		var puff := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radial_segments = 10
		sphere.rings = 5
		puff.mesh = sphere
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = Color(0.86, 0.85, 0.76, 0.2)
		puff.material_override = material
		add_child(puff)
		_smoke.append(puff)
	for i in 3:
		var bird := Node3D.new()
		add_child(bird)
		var body := ArtMesh.new()
		body.pebble(Vector3.ZERO, Vector3(0.09, 0.07, 0.25), Color("#ede6d1"))
		body.instance(bird, "Body").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for side in [-1, 1]:
			var wing := Node3D.new()
			wing.name = "Left" if side == -1 else "Right"
			bird.add_child(wing)
			var art := ArtMesh.new()
			art.triangle(Vector3(0, 0, -0.12), Vector3(side * 0.65, 0.02, -0.18), Vector3(side * 0.4, 0, 0.15), Color("#e4decb"))
			art.instance(wing).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_birds.append(bird)
	_fireflies = MultiMeshInstance3D.new()
	var multi := MultiMesh.new()
	multi.transform_format = MultiMesh.TRANSFORM_3D
	multi.use_colors = true
	var glow := QuadMesh.new()
	glow.size = Vector2(0.06, 0.06)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color("#f2d28e")
	glow.material = material
	multi.mesh = glow
	multi.instance_count = 24
	_fireflies.multimesh = multi
	_fireflies.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fireflies)


func _process(delta: float) -> void:
	_time += delta
	_fireflies.visible = WorldClock.hour > 19.0 or WorldClock.hour < 6.0
	if _fireflies.visible:
		for i in 24:
			var point := Vector3(80 + sin(i * 2.4) * 8, 1.0 + sin(_time * 0.4 + i) * 0.5, cos(i * 3.1) * 7)
			point.x += sin(_time * 0.3 + i) * 0.5
			_fireflies.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, point))
			_fireflies.multimesh.set_instance_color(i, Color(1, 1, 1, 0.5 + sin(_time * 1.5 + i) * 0.4))
	for i in _smoke.size():
		var phase := fmod(_time * 0.12 + float(i) / _smoke.size(), 1.0)
		var puff := _smoke[i]
		puff.position = Vector3(-1.9 + phase * 1.4, 5.2 + phase * 2.6, 1.3 + sin(phase * 4.0) * 0.3)
		puff.scale = Vector3.ONE * (0.32 + phase * 0.8)
		var color := Color(0.86, 0.85, 0.76, sin(phase * PI) * 0.18)
		(puff.material_override as StandardMaterial3D).albedo_color = color
	for i in _birds.size():
		var angle := _time * (0.11 + i * 0.015) + i * 2.0
		var bird := _birds[i]
		bird.position = Vector3(cos(angle) * (13.0 + i), 4.3 + sin(angle * 2.0) * 0.5, -17.0 + sin(angle) * 5.0)
		bird.rotation.y = -angle
		bird.get_node("Left").rotation.z = sin(_time * 3.3 + i) * 0.24
		bird.get_node("Right").rotation.z = -sin(_time * 3.3 + i) * 0.24
