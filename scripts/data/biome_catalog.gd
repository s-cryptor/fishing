class_name BiomeCatalog
extends Resource

@export var biomes: Array[BiomeData] = []


func for_habitat(habitat: StringName) -> BiomeData:
	for biome in biomes:
		if biome.habitat == habitat:
			return biome
	return null
