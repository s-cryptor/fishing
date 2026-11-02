class_name CottageArt
extends RefCounted

static func build(parent: Node3D) -> void:
	var art := ArtMesh.new()
	var wood := Color("#725747")
	var trim := Color("#e8d4ad")
	art.box(Vector3(0, 0.12, 0), Vector3(4.15, 0.25, 3.5), Color("#8a8c78"))
	art.box(Vector3(0, 1.4, 0), Vector3(4, 2.5, 3.4), Color("#d1c6a5"))
	for x in [-1.95, 1.95]:
		for z in [-1.7, 1.7]:
			art.box(Vector3(x, 1.4, z), Vector3(0.16, 2.65, 0.16), wood)
	for z in [-1.72, 1.72]:
		art.triangle(Vector3(-2, 2.6, z), Vector3(2, 2.6, z), Vector3(0, 3.8, z), trim)
		art.tube(Vector3(-2.5, 2.5, z * 1.23), Vector3(0, 3.85, z * 1.23), 0.09, wood)
		art.tube(Vector3(0, 3.85, z * 1.23), Vector3(2.5, 2.5, z * 1.23), 0.09, wood)
	for side in [-1, 1]:
		art.box(Vector3(side * 1.2, 3.12, 0), Vector3(2.8, 0.16, 4.25), wood, Vector3(0, 0, -side * 0.46))
		for row in 4:
			for col in 8:
				var x: float = side * (0.3 + row * 0.61)
				var y := 3.88 - (0.3 + row * 0.61) * 0.5
				var color := Color("#ae624f").lightened(float((row + col) % 3) * 0.035)
				art.box(Vector3(x, y, -1.93 + col * 0.55), Vector3(0.72, 0.13, 0.52), color, Vector3(0, 0, -side * 0.46))
	art.tube(Vector3(0, 3.98, -2.15), Vector3(0, 3.98, 2.15), 0.09, Color("#9c5347"))
	# Дверь, наличники и ступени.
	art.box(Vector3(0.8, 0.94, 1.74), Vector3(1.06, 1.9, 0.15), wood)
	art.box(Vector3(0.8, 0.92, 1.84), Vector3(0.8, 1.65, 0.06), Color("#4b7470"))
	for i in 4:
		art.box(Vector3(0.5 + i * 0.2, 0.9, 1.89), Vector3(0.025, 1.5, 0.025), Color("#3a5a58"))
	art.pebble(Vector3(1.05, 0.9, 1.96), Vector3.ONE * 0.055, Color("#d7b66f"))
	art.box(Vector3(0.8, 0.06, 2.0), Vector3(1.5, 0.12, 0.8), Color("#aaa38d"))
	for x in [-1.1]:
		art.box(Vector3(x, 1.55, 1.75), Vector3(1.05, 1.0, 0.14), wood)
		art.box(Vector3(x, 1.55, 1.84), Vector3(0.84, 0.79, 0.06), Color("#c7c492"))
		art.box(Vector3(x, 1.55, 1.9), Vector3(0.06, 0.85, 0.04), trim)
		art.box(Vector3(x, 1.55, 1.9), Vector3(0.9, 0.06, 0.04), trim)
		for side in [-1, 1]:
			art.box(Vector3(x + side * 0.68, 1.55, 1.78), Vector3(0.23, 0.95, 0.1), Color("#507771"))
		art.box(Vector3(x, 0.97, 1.95), Vector3(1.25, 0.26, 0.4), wood)
		for i in 7:
			art.pebble(Vector3(x - 0.5 + i * 0.16, 1.18, 2.0), Vector3(0.14, 0.17, 0.13), Color("#728755"), i)
			art.pebble(Vector3(x - 0.5 + i * 0.16, 1.32, 2.04), Vector3.ONE * 0.085, Color("#d59b90"), i)
	art.box(Vector3(1.1, 3.9, -0.7), Vector3(0.5, 1.35, 0.6), Color("#8b8e80"))
	for y in [3.5, 3.85, 4.2]:
		art.box(Vector3(1.1, y, -0.7), Vector3(0.53, 0.04, 0.63), Color("#b9b7a0"))
	art.box(Vector3(1.1, 4.6, -0.7), Vector3(0.7, 0.15, 0.8), wood)
	art.box(Vector3(-2.04, 1.55, 0.1), Vector3(0.16, 1.0, 1.04), wood)
	art.box(Vector3(-2.16, 1.55, 0.1), Vector3(0.04, 0.85, 0.06), trim)
	art.box(Vector3(-2.16, 1.55, 0.1), Vector3(0.04, 0.06, 0.9), trim)
	# Свободный обзор открывает задний фасад: он тоже должен выглядеть жилым.
	art.box(Vector3(-0.75, 1.55, -1.76), Vector3(1.16, 1.04, 0.14), wood)
	art.box(Vector3(-0.75, 1.55, -1.91), Vector3(0.06, 0.86, 0.035), trim)
	for x in [-1.48, -0.02]:
		art.box(Vector3(x, 1.55, -1.79), Vector3(0.23, 0.98, 0.1), Color("#507771"))
	art.box(Vector3(-0.75, 1.55, -1.91), Vector3(0.94, 0.06, 0.035), trim)
	art.box(Vector3(-0.75, 0.98, -1.88), Vector3(1.3, 0.13, 0.4), wood)
	for layer in 2:
		for log_index in 3 - layer:
			var x := 0.55 + log_index * 0.27 + layer * 0.13
			var y := 0.25 + layer * 0.23
			art.tube(Vector3(x, y, -1.75), Vector3(x, y, -2.27), 0.13, wood.darkened(0.08), 0.12, 7)
			art.tube(Vector3(x, y, -2.275), Vector3(x, y, -2.29), 0.095, Color("#b99b6a"), 0.095, 7)
	art.instance(parent, "HarborCottage")
	var lights := Node3D.new()
	lights.set_script(load("res://scripts/world/cottage_lights.gd"))
	parent.add_child(lights)
