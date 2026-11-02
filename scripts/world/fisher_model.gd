class_name FisherModel
extends Node3D
## Собственная игрушечная модель рыбака, собранная из low-poly деталей.

var _legs: Array[Node3D] = []
var _arms: Array[Node3D] = []
var _step := 0.0
var fishing := false
var charge := 0.0
var tension := 0.0
var reeling := false
var cast_kick := 0.0
var _pose := 0.0
var _bend := 0.0
var _rod := ImmediateMesh.new()


func _ready() -> void:
	var coat := BoxMesh.new()
	coat.size = Vector3(0.64, 0.65, 0.43)
	$Body.mesh = coat
	$Body.position.y = 1.05
	var coat_material := StandardMaterial3D.new()
	coat_material.albedo_color = Color("#dc7547")
	$Body.material_override = coat_material
	for side in [-1, 1]:
		var leg := Node3D.new()
		leg.position = Vector3(side * 0.17, 0.66, 0)
		add_child(leg)
		_legs.append(leg)
		var trouser := CylinderMesh.new()
		trouser.top_radius = 0.13
		trouser.bottom_radius = 0.11
		trouser.height = 0.46
		trouser.radial_segments = 6
		_part(leg, trouser, Vector3(0, -0.22, 0), Color("#355765"))
		var boot := BoxMesh.new()
		boot.size = Vector3(0.24, 0.21, 0.38)
		_part(leg, boot, Vector3(0, -0.52, 0.07), Color("#39433d"))
		var arm := Node3D.new()
		arm.position = Vector3(side * 0.43, 1.3, 0)
		arm.rotation.x = -0.35
		add_child(arm)
		_arms.append(arm)
		var sleeve := CapsuleMesh.new()
		sleeve.radius = 0.12
		sleeve.height = 0.48
		sleeve.radial_segments = 6
		sleeve.rings = 3
		_part(arm, sleeve, Vector3(0, -0.2, 0), Color("#dc7547"))
		var hand := SphereMesh.new()
		hand.radius = 0.1
		hand.height = 0.2
		hand.radial_segments = 8
		hand.rings = 4
		_part(arm, hand, Vector3(0, -0.46, 0), Color("#f5c69d"))
		var eye := SphereMesh.new()
		eye.radius = 0.035
		eye.height = 0.07
		_part(self, eye, Vector3(side * 0.1, 1.65, 0.235), Color("#26383e"))
	var brim := CylinderMesh.new()
	brim.top_radius = 0.44
	brim.bottom_radius = 0.44
	brim.height = 0.055
	brim.radial_segments = 12
	_part(self, brim, Vector3(0, 1.82, 0), Color("#e9c76c"))
	var backpack := BoxMesh.new()
	backpack.size = Vector3(0.48, 0.5, 0.24)
	_part(self, backpack, Vector3(0, 1.1, -0.32), Color("#718459"))
	var pocket := BoxMesh.new()
	pocket.size = Vector3(0.28, 0.22, 0.08)
	_part(self, pocket, Vector3(0, 1.05, -0.48), Color("#536749"))
	$Rod.position = Vector3(0.36, 1.35, 0.55)
	$Rod.rotation.x = deg_to_rad(48)
	$RodTip.position = Vector3(0.36, 1.8, 1.05)
	$Rod.hide()
	var rod_visual := MeshInstance3D.new()
	rod_visual.mesh = _rod
	var rod_material := StandardMaterial3D.new()
	rod_material.vertex_color_use_as_albedo = true
	rod_material.roughness = 0.65
	rod_visual.material_override = rod_material
	add_child(rod_visual)


func animate_walk(moving: bool, delta: float) -> void:
	_pose = lerpf(_pose, 1.0 if fishing else 0.0, 1.0 - exp(-10 * delta))
	_bend = lerpf(_bend, tension, 1.0 - exp(-14 * delta))
	cast_kick = move_toward(cast_kick, 0.0, delta * 3)
	if moving:
		_step += delta * 11.0
	for i in _legs.size():
		var swing := sin(_step + i * PI) * 0.5 if moving else 0.0
		_legs[i].rotation.x = lerpf(_legs[i].rotation.x, swing, 1.0 - exp(-16.0 * delta))
		var arm_target := lerpf(-0.35 - swing * 0.6, -1.05 - charge * 0.4 - _bend * 0.15, _pose)
		if reeling and i == 0:
			arm_target += sin(Time.get_ticks_msec() * 0.022) * 0.12
		_arms[i].rotation.x = lerpf(_arms[i].rotation.x, arm_target, 1.0 - exp(-16.0 * delta))
	$Body.rotation.x = -_bend * 0.08
	_draw_rod()


func _draw_rod() -> void:
	var base := Vector3(0.36, 1.08, 0.35)
	var tip := Vector3(0.36, 2.12 + charge * 0.65 - _bend * 0.7, 1.55 - charge * 0.95 + cast_kick * 0.45)
	var middle := base.lerp(tip, 0.5) + Vector3(0, 0.32 + _bend * 0.55, 0)
	_rod.clear_surfaces()
	_rod.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 12:
		var t := i / 12.0
		var t2 := (i + 1) / 12.0
		var a := _curve(base, middle, tip, t)
		var b := _curve(base, middle, tip, t2)
		var axis := (b - a).normalized()
		var u := axis.cross(Vector3.RIGHT).normalized()
		var v := axis.cross(u)
		var r := lerpf(0.035, 0.009, t)
		var r2 := lerpf(0.035, 0.009, t2)
		_rod.surface_set_color(Color("#b89b62") if i < 3 else Color("#454f45"))
		for side in 6:
			var n := u * cos(TAU * side / 6) + v * sin(TAU * side / 6)
			var n2 := u * cos(TAU * (side + 1) / 6) + v * sin(TAU * (side + 1) / 6)
			for vertex in [a + n * r, b + n * r2, b + n2 * r2, a + n * r, b + n2 * r2, a + n2 * r]:
				_rod.surface_set_normal((n + n2).normalized())
				_rod.surface_add_vertex(vertex)
	_rod.surface_end()
	$RodTip.position = tip


func _curve(a: Vector3, b: Vector3, c: Vector3, t: float) -> Vector3:
	return a.lerp(b, t).lerp(b.lerp(c, t), t)


func _part(parent: Node3D, mesh: Mesh, point: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.material_override = material
	parent.add_child(instance)
