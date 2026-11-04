class_name FishAppearance
extends Resource
## Внешний вид отделён от FishData: чистая рыбалка не загружает 3D-сцены.

@export var fish_id: StringName
@export var scene: PackedScene
@export var orientation := Vector3.ZERO
@export var length := 3.1
@export var eye_anchor := Vector3(1.1, 0.08, 0.19)
@export var animation_name: StringName
@export var tint := Color.WHITE
@export var head_bone: StringName
