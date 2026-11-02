class_name FishingWater
extends Node3D
## Водоём вокруг фигурного острова. Отвечает на вопрос «эта точка — вода?»
## и задаёт, какие рыбы здесь водятся.

@export var biome: BiomeData
@export var water_level := 0.0
## Средний радиус контура; бухта и изгибы заданы в ShoreProfile.
@export var shore_radius := 12.8


func is_water(point: Vector3) -> bool:
	var offset := point - global_position
	return Vector2(offset.x, offset.z).length() > ShoreProfile.radius_at(atan2(offset.z, offset.x), shore_radius)


func habitat_id() -> StringName:
	return biome.habitat if biome else &"lake"


## Рыбное место, в которое попала точка, или null.
func spot_at(point: Vector3) -> FishingSpot:
	for child in get_children():
		var spot := child as FishingSpot
		if spot and spot.contains(point):
			return spot
	return null
