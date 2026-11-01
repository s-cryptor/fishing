class_name FishingLine
extends MeshInstance3D
## Леска от кончика удочки до поплавка с провисанием.

const SEGMENTS := 16

var from_node: Node3D
var to_node: Node3D
## 0 — натянута в струну, 1 — сильно провисла.
var slack := 0.5

var _mesh := ImmediateMesh.new()


func _ready() -> void:
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.95, 0.95, 0.9)
	material_override = material


func attach(from: Node3D, to: Node3D) -> void:
	from_node = from
	to_node = to
	show()


func detach() -> void:
	from_node = null
	to_node = null
	_mesh.clear_surfaces()
	hide()


func _process(_delta: float) -> void:
	if from_node == null or to_node == null:
		return
	var a := from_node.global_position
	var b := to_node.global_position
	var sag := a.distance_to(b) * 0.15 * slack
	_mesh.clear_surfaces()
	_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		_mesh.surface_add_vertex(a.lerp(b, t) + Vector3.DOWN * sin(t * PI) * sag)
	_mesh.surface_end()
