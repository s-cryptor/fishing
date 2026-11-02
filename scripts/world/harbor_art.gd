extends Node3D
## Художественный слой не владеет прогрессом и сохраняет игровые коллизии.

func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	var main := get_parent()
	var water_mesh := main.get_node("Lake/Water") as MeshInstance3D
	var water_material := water_mesh.mesh.surface_get_material(0) as ShaderMaterial
	water_material.set_shader_parameter("shore_waves", ShoreProfile.WAVES)
	water_material.set_shader_parameter("shore_cove", ShoreProfile.COVE)
	for island in ["Island", "MangroveIsland", "FjordIsland"]:
		for child in main.get_node(island).get_children():
			if child is MeshInstance3D:
				child.hide()
	IslandTerrain.build(self, Vector3.ZERO, 0)
	IslandTerrain.build(self, Vector3(80, 0, 0), 1)
	IslandTerrain.build(self, Vector3(160, 0, 0), 2)
	for biome in 3:
		NatureArt.scatter(self, Vector3(biome * 80, 0, 0), biome)
		NatureArt.shoreline(self, Vector3(biome * 80, 0, 0), biome)
	var house := main.get_node("House") as Node3D
	for child in house.get_children():
		if child is MeshInstance3D:
			child.hide()
	CottageArt.build(house)
	HarborProps.garden(self)
	HarborProps.lilies(self)
	for point in [Vector3(73, 0.5, -3), Vector3(85, 0.5, -6), Vector3(87, 0.5, 4), Vector3(76, 0.5, 6)]:
		NatureArt.tree(self, point, true)
		var body := StaticBody3D.new()
		body.position = point + Vector3.UP * 1.2
		var collision := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.3
		shape.height = 2.4
		collision.shape = shape
		body.add_child(collision)
		add_child(body)
