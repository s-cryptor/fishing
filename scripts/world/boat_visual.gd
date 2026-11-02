extends Node3D
## Собственный low-poly корпус, покачивание и парус улучшенной лодки.

var _origin: Vector3
var _sail: MeshInstance3D
var _mast: MeshInstance3D


func _ready() -> void:
	_origin = position
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 12:
		var a := TAU * i / 12.0
		var b := TAU * (i + 1) / 12.0
		var top_a := Vector3(cos(a) * 1.1, 0.2, sin(a) * 2.1)
		var top_b := Vector3(cos(b) * 1.1, 0.2, sin(b) * 2.1)
		var bottom_a := Vector3(top_a.x * 0.55, -0.4, top_a.z * 0.8)
		var bottom_b := Vector3(top_b.x * 0.55, -0.4, top_b.z * 0.8)
		for vertex in [top_a, bottom_a, top_b, top_b, bottom_a, bottom_b, bottom_a, Vector3(0, -0.4, 0), bottom_b]:
			surface.add_vertex(vertex)
		for vertex in [Vector3(top_a.x * 0.8, -0.1, top_a.z * 0.9), Vector3(0, -0.1, 0), Vector3(top_b.x * 0.8, -0.1, top_b.z * 0.9)]:
			surface.add_vertex(vertex)
	surface.generate_normals()
	$Hull.mesh = surface.commit()
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#b95b3c")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	$Hull.material_override = material
	_sail = MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(1.2, 1.7, 0.08)
	_sail.mesh = mesh
	_sail.position = Vector3(0, 1.7, 0.5)
	var sail_material := StandardMaterial3D.new()
	sail_material.albedo_color = Color("#ffe0a0")
	_sail.material_override = sail_material
	add_child(_sail)
	_mast = MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.035
	mast_mesh.bottom_radius = 0.045
	mast_mesh.height = 2.5
	_mast.mesh = mast_mesh
	_mast.position = Vector3(0, 1.1, 0.5)
	_mast.material_override = material
	add_child(_mast)
	GameState.supplies_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_sail.visible = GameState.boat_upgraded
	_mast.visible = GameState.boat_upgraded


func _process(_delta: float) -> void:
	var time := Time.get_ticks_msec() / 1000.0
	position.y = _origin.y + sin(time * 1.3 + _origin.x) * 0.06
	rotation.z = sin(time * 0.8) * 0.025
