class_name ArtMesh
extends RefCounted
## Собирает цветные low-poly детали в один меш без внешних ассетов.

var _surface := SurfaceTool.new()
static var _material: StandardMaterial3D


func _init() -> void:
	_surface.begin(Mesh.PRIMITIVE_TRIANGLES)


func triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.000001:
		return
	normal = normal.normalized()
	# Godot считает лицевой сторону с обходом по часовой стрелке.
	for point in [a, c, b]:
		_surface.set_color(color)
		_surface.set_normal(normal)
		_surface.add_vertex(point)


func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	triangle(a, b, c, color)
	triangle(a, c, d, color)


func box(center: Vector3, size: Vector3, color: Color, rotation := Vector3.ZERO) -> void:
	var s := size * 0.5
	var basis := Basis.from_euler(rotation)
	var corners: Array[Vector3] = []
	for point in [Vector3(-s.x, -s.y, s.z), Vector3(s.x, -s.y, s.z), Vector3(s.x, s.y, s.z), Vector3(-s.x, s.y, s.z),
			Vector3(-s.x, -s.y, -s.z), Vector3(s.x, -s.y, -s.z), Vector3(s.x, s.y, -s.z), Vector3(-s.x, s.y, -s.z)]:
		corners.append(center + basis * point)
	for face in [[0, 1, 2, 3], [5, 4, 7, 6], [1, 5, 6, 2], [4, 0, 3, 7], [3, 2, 6, 7], [4, 5, 1, 0]]:
		quad(corners[face[0]], corners[face[1]], corners[face[2]], corners[face[3]], color)


func tube(a: Vector3, b: Vector3, radius: float, color: Color, end_radius := -1.0, sides := 7) -> void:
	var axis := (b - a).normalized()
	var u := axis.cross(Vector3.FORWARD).normalized()
	if u.length_squared() < 0.01:
		u = axis.cross(Vector3.RIGHT).normalized()
	var v := axis.cross(u)
	var r2 := radius if end_radius < 0.0 else end_radius
	for i in sides:
		var p := u * cos(TAU * i / sides) + v * sin(TAU * i / sides)
		var q := u * cos(TAU * (i + 1) / sides) + v * sin(TAU * (i + 1) / sides)
		quad(a + p * radius, a + q * radius, b + q * r2, b + p * r2, color)
		triangle(a, a + q * radius, a + p * radius, color)
		triangle(b, b + p * r2, b + q * r2, color)


func pebble(center: Vector3, size: Vector3, color: Color, seed_value := 0.0) -> void:
	for row in 5:
		for side in 9:
			var points: Array[Vector3] = []
			for cell in [Vector2(side, row), Vector2(side + 1, row), Vector2(side + 1, row + 1), Vector2(side, row + 1)]:
				var theta: float = PI * cell.y / 5.0
				var phi: float = TAU * cell.x / 9.0
				var p := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi))
				var wobble := 1.0 + sin(p.x * 7.0 + p.z * 3.0 + seed_value) * 0.09
				points.append(center + p * size * wobble)
			var tint := color.lightened(sin(side * 3.0 + row * 9.0 + seed_value) * 0.035)
			quad(points[0], points[1], points[2], points[3], tint)


func instance(parent: Node3D, label := "Art") -> MeshInstance3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.vertex_color_use_as_albedo = true
		_material.vertex_color_is_srgb = true
		_material.roughness = 0.95
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = _surface.commit()
	node.material_override = _material
	parent.add_child(node)
	return node
