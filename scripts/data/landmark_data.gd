class_name LandmarkData
extends Resource
## Место для открытия: запись дневника, положение и семейство собственного арта.

enum Kind { LIGHTHOUSE, BOATKEEPER_HUT, STONE_ARCH }
@export var id: StringName
@export var title := ""
@export var habitat: StringName
@export_multiline var description := ""
@export var clue := ""
@export var position := Vector3.ZERO
@export var kind := Kind.LIGHTHOUSE

