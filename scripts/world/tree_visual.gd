extends StaticBody3D


func _ready() -> void:
	for child in get_children():
		if child is MeshInstance3D:
			child.hide()
	NatureArt.tree(self)
