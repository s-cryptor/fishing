class_name FishingSpot
extends Node3D
## Рыбное место: пузыри и тень рыбы на воде. Заброс сюда ускоряет поклёвку
## и повышает шанс редких рыб. Место «выдыхается» после улова или со временем
## и переезжает в другую точку водоёма.

@export var radius := 2.5
@export var bite_time_mult := 0.5
@export var luck_bonus := 1.0
@export var min_lifetime := 40.0
@export var max_lifetime := 75.0
## Насколько далеко от берега может появиться место, м.
@export var min_offshore := 2.0
@export var max_offshore := 12.0

var _water: FishingWater
var _lifetime := 0.0
var _time := 0.0
var _relocating := false

@onready var _shadow: Node3D = $Shadow
@onready var _bubbles: Array[Node] = $Bubbles.get_children()


func _ready() -> void:
	add_to_group(&"fishing_spot")
	_water = get_parent() as FishingWater
	_relocate(false)


func contains(point: Vector3) -> bool:
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() <= radius


## Снасти с бонусами места. Исходный ресурс не меняем — он общий.
func boost(gear: GearStats) -> GearStats:
	var boosted := gear.duplicate() as GearStats
	boosted.bite_time_mult *= bite_time_mult
	boosted.luck += luck_bonus
	return boosted


## Рыбу отсюда вытащили — место переезжает.
func deplete() -> void:
	if not _relocating:
		_relocate(true)


func _process(delta: float) -> void:
	_time += delta
	_lifetime -= delta
	if _lifetime <= 0.0 and not _relocating:
		_relocate(true)
	# Тень рыбы лениво кружит, пузыри поднимаются и появляются заново.
	_shadow.position = Vector3(cos(_time * 0.7), 0.0, sin(_time * 0.7)) * radius * 0.35
	_shadow.rotation.y = -_time * 0.7
	for i in _bubbles.size():
		var bubble := _bubbles[i] as Node3D
		var phase := fmod(_time * 0.8 + i * 0.37, 1.0)
		bubble.position.y = phase * 0.25
		bubble.scale = Vector3.ONE * (1.0 - phase)


func _relocate(animated: bool) -> void:
	_relocating = true
	if animated:
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector3.ONE * 0.01, 0.6)
		await tween.finished
	_lifetime = randf_range(min_lifetime, max_lifetime)
	var angle := randf() * TAU
	var distance := _water.shore_radius + randf_range(min_offshore, max_offshore)
	global_position = _water.global_position + Vector3(cos(angle) * distance, _water.water_level + 0.02, sin(angle) * distance)
	scale = Vector3.ONE * 0.01
	var appear := create_tween()
	appear.tween_property(self, "scale", Vector3.ONE, 0.8)
	_relocating = false
