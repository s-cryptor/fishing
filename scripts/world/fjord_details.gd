extends Node3D
## Собственные снежные ели и скалы фьорда; проходы к причалу свободны.

func _ready() -> void:
	for point in [Vector3(-6, 0.5, -6), Vector3(3, 0.5, -5), Vector3(7, 0.5, -3), Vector3(5, 0.5, 6), Vector3(-3, 0.5, 7)]:
		var trunk := CylinderMesh.new()
		trunk.top_radius = 0.12
		trunk.bottom_radius = 0.22
		trunk.height = 2.0
		_add(trunk, point + Vector3.UP, Color("#6d625a"))
		var body := StaticBody3D.new()
		body.position = point + Vector3.UP
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.25
		cylinder.height = 2.0
		shape.shape = cylinder
		body.add_child(shape)
		add_child(body)
		for i in 3:
			var branches := CylinderMesh.new()
			branches.top_radius = 0.0
			branches.bottom_radius = 1.6 - i * 0.35
			branches.height = 2.0
			branches.radial_segments = 7
			_add(branches, point + Vector3.UP * (1.6 + i * 0.9), Color("#80aeb7"))
			var snow := CylinderMesh.new()
			snow.top_radius = 0.0
			snow.bottom_radius = branches.bottom_radius * 0.9
			snow.height = 1.75
			snow.radial_segments = 7
			_add(snow, point + Vector3.UP * (1.85 + i * 0.9), Color("#a9c3c8"))
	for point in [Vector3(6, 0.7, -7), Vector3(9, 0.7, 3), Vector3(-5, 0.7, 8)]:
		var rock := SphereMesh.new()
		rock.radius = 1.2
		rock.height = 2.2
		rock.radial_segments = 5
		rock.rings = 3
		_add(rock, point, Color("#829ba9"))


func _add(mesh: Mesh, point: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.position = point
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	instance.material_override = material
	add_child(instance)
