class_name FishSilhouette
extends RefCounted
## Общий неброский силуэт для стай и борьбы: без раскрытия вида рыбы.

static var _mesh: Mesh
static var _material: StandardMaterial3D


static func create(parent: Node3D) -> MeshInstance3D:
	if _mesh == null:
		var art := ArtMesh.new()
		for i in 20:
			var a := TAU * i / 20
			var b := TAU * (i + 1) / 20
			art.triangle(Vector3.ZERO, Vector3(sin(a) * 0.18, 0, cos(a) * 0.44), Vector3(sin(b) * 0.18, 0, cos(b) * 0.44), Color.WHITE)
		art.triangle(Vector3(0, 0, -0.32), Vector3(-0.21, 0, -0.7), Vector3(0.21, 0, -0.7), Color.WHITE)
		for side in [-1, 1]:
			art.triangle(Vector3(side * 0.1, 0, 0.1), Vector3(side * 0.29, 0, -0.13), Vector3(side * 0.1, 0, -0.08), Color.WHITE)
		var temporary := Node3D.new()
		var instance := art.instance(temporary)
		_mesh = instance.mesh
		temporary.free()
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color = Color(0.07, 0.24, 0.25, 0.3)
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	var node := MeshInstance3D.new()
	node.mesh = _mesh
	node.material_override = _material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node
