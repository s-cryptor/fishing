extends Node3D
## Детерминированный декор островов без внешних ассетов.

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1907
	for i in 24:
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(8.0, 11.5)
		var point := Vector3(cos(angle) * radius, 0.55, sin(angle) * radius)
		# Не закрываем подходы к лодке и прилавку.
		if point.z < -7.0 or point.distance_to(Vector3(4.5, 0.55, -6)) < 3.0:
			continue
		var rock := SphereMesh.new()
		rock.radial_segments = 6
		rock.rings = 3
		rock.radius = rng.randf_range(0.25, 0.6)
		rock.height = rock.radius * 1.5
		_mesh(self, rock, point, Color("#849b93"))
		for j in 3:
			var stem := CylinderMesh.new()
			stem.top_radius = 0.01
			stem.bottom_radius = 0.025
			stem.height = rng.randf_range(0.25, 0.5)
			var flower_pos := point + Vector3(rng.randf_range(-0.7, 0.7), stem.height * 0.5, rng.randf_range(-0.7, 0.7))
			_mesh(self, stem, flower_pos, Color("#477b47"))
			var flower := SphereMesh.new()
			flower.radius = 0.09
			flower.height = 0.12
			flower.radial_segments = 5
			flower.rings = 2
			_mesh(self, flower, flower_pos + Vector3.UP * stem.height * 0.5, Color("#f4d189") if i % 2 == 0 else Color("#e7a8aa"))
	for point in [Vector3(73, 0.5, -3), Vector3(85, 0.5, -6), Vector3(87, 0.5, 4), Vector3(76, 0.5, 6)]:
		_mangrove(point)


func _mangrove(point: Vector3) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.22
	trunk.bottom_radius = 0.38
	trunk.height = 2.8
	trunk.radial_segments = 7
	_mesh(self, trunk, point + Vector3.UP * 1.4, Color("#795b42"))
	for i in 5:
		var angle := TAU * i / 5.0
		var outward := Vector3(cos(angle), 0, sin(angle))
		var root := CylinderMesh.new()
		root.top_radius = 0.09
		root.bottom_radius = 0.13
		root.height = 2.2
		root.radial_segments = 5
		var branch := _mesh(self, root, point + outward * 0.7 + Vector3.UP * 0.6, Color("#795b42"))
		branch.quaternion = Quaternion(Vector3.UP, (Vector3.UP * 1.3 - outward * 1.4).normalized())
		var crown := SphereMesh.new()
		crown.radius = 1.5
		crown.height = 1.65
		crown.radial_segments = 7
		crown.rings = 3
		_mesh(self, crown, point + outward * 1.0 + Vector3.UP * 3.0, Color("#2d805e") if i % 2 == 0 else Color("#459b6a"))


func _mesh(parent: Node3D, mesh: Mesh, point: Vector3, color: Color) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	instance.material_override = material
	parent.add_child(instance)
	return instance
