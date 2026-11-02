extends Node3D
## Собственные снежные ели и скалы фьорда; проходы к причалу свободны.

func _ready() -> void:
	for point in [Vector3(-6, 0.5, -6), Vector3(3, 0.5, -5), Vector3(7, 0.5, -3), Vector3(5, 0.5, 6), Vector3(-3, 0.5, 7)]:
		NatureArt.fir(self, point)
		var body := StaticBody3D.new()
		body.position = point + Vector3.UP
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = 0.25
		cylinder.height = 2.0
		shape.shape = cylinder
		body.add_child(shape)
		add_child(body)
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
