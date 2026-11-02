class_name BoatArt
extends RefCounted
## Дощатая лодка с открытым кокпитом, бортами, вёслами и походным парусом.

static func build(parent: Node3D) -> Node3D:
	var art := ArtMesh.new()
	var wood := Color("#997a52")
	var rim := Color("#c2a577")
	var paint := Color("#476f67")
	var sections := [Vector2(1.6, 0.62), Vector2(1.1, 0.87), Vector2(0.3, 0.98), Vector2(-0.6, 0.87), Vector2(-1.45, 0.5), Vector2(-2.1, 0.025)]
	for i in sections.size() - 1:
		var a: Vector2 = sections[i]
		var b: Vector2 = sections[i + 1]
		for side in [-1, 1]:
			var at := Vector3(side * a.y, 0.3, a.x)
			var bt := Vector3(side * b.y, 0.3, b.x)
			var ab := Vector3(side * a.y * 0.6, -0.3, a.x * 0.9)
			var bb := Vector3(side * b.y * 0.6, -0.3, b.x * 0.9)
			art.quad(at, ab, bb, bt, paint.lightened(i * 0.012))
			art.quad(at - Vector3(side * 0.09, 0, 0), bt - Vector3(side * 0.09, 0, 0), bb, ab, wood)
			art.tube(at, bt, 0.065, rim, 0.065, 6)
			art.tube(at.lerp(ab, 0.45), bt.lerp(bb, 0.45), 0.018, paint.darkened(0.2), 0.018, 5)
		art.quad(Vector3(-a.y * 0.6, -0.3, a.x * 0.9), Vector3(a.y * 0.6, -0.3, a.x * 0.9),
			Vector3(b.y * 0.6, -0.3, b.x * 0.9), Vector3(-b.y * 0.6, -0.3, b.x * 0.9), wood.darkened(0.2))
	art.box(Vector3(0, 0, 1.56), Vector3(1.22, 0.57, 0.12), paint)
	art.tube(Vector3(-0.65, 0.3, 1.6), Vector3(0.65, 0.3, 1.6), 0.065, rim)
	for plank in 12:
		var z := 1.35 - plank * 0.22
		var width := 1.3 if z > -0.6 else lerpf(1.3, 0.4, (-z - 0.6) / 0.8)
		art.box(Vector3(0, -0.1, z), Vector3(width, 0.07, 0.2), wood.lightened((plank % 3) * 0.035))
	for z in [-0.6, 0.8]:
		art.box(Vector3(0, 0.2, z), Vector3(1.68, 0.12, 0.35), rim)
		for x in [-0.7, 0.7]:
			art.box(Vector3(x, 0.267, z), Vector3(0.025, 0.008, 0.26), wood.darkened(0.2))
	for side in [-1, 1]:
		art.tube(Vector3(side * 0.75, 0.37, 0.75), Vector3(side * 1.23, 0.4, -1.2), 0.035, wood, 0.025)
		art.box(Vector3(side * 1.2, 0.4, -1.18), Vector3(0.18, 0.05, 0.55), rim, Vector3(0, side * 0.24, 0))
	art.box(Vector3(0.4, 0.08, 1.1), Vector3(0.38, 0.3, 0.32), Color("#6e8260"))
	art.box(Vector3(0.4, 0.24, 1.1), Vector3(0.4, 0.04, 0.34), Color("#8c9b78"))
	art.instance(parent, "WoodenHull")
	var rig := Node3D.new()
	rig.name = "ExplorerRig"
	parent.add_child(rig)
	var sail := ArtMesh.new()
	sail.tube(Vector3(0, 0, -0.85), Vector3(0, 2.55, -0.85), 0.04, wood, 0.025)
	sail.tube(Vector3(-0.85, 0.95, -0.85), Vector3(0.9, 0.95, -0.85), 0.025, wood)
	sail.triangle(Vector3(0, 2.48, -0.85), Vector3(-0.78, 1.02, -0.78), Vector3(0, 1.02, -0.6), Color("#e4d6ad"))
	sail.triangle(Vector3(0, 2.48, -0.85), Vector3(0, 1.02, -0.6), Vector3(0.82, 1.02, -0.78), Color("#d9c595"))
	sail.triangle(Vector3(0, 2.48, -0.84), Vector3(-0.42, 1.72, -0.8), Vector3(0, 1.72, -0.7), Color("#64877b"))
	sail.triangle(Vector3(0, 2.48, -0.84), Vector3(0, 1.72, -0.7), Vector3(0.43, 1.72, -0.8), Color("#64877b"))
	sail.tube(Vector3(0, 2.5, -0.85), Vector3(0, 0.35, 1.5), 0.009, rim, 0.009, 5)
	sail.instance(rig, "Sail")
	return rig
