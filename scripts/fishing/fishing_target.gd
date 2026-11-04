class_name FishingTarget
extends RefCounted
## Подсказки личной цели. Не меняет выбор рыбы, снасть или случайные числа сессии.


static func title(fish: FishData, known: bool, trophy: bool) -> String:
	var name := fish.display_name if known else "Неизвестный вид · %s" % fish.rarity_name().to_lower()
	return "%s: %s" % ["Золотой трофей" if trophy else "Найти вид", name]


static func status(fish: FishData, hour: float, habitat: StringName, boat_upgraded: bool,
		biomes: BiomeCatalog) -> String:
	var places: Array[String] = []
	for id in fish.habitats:
		var biome := biomes.for_habitat(id)
		if biome:
			places.append(biome.display_name)
	if &"fjord" in fish.habitats and fish.habitats.size() == 1 and not boat_upgraded:
		return "%s\nСначала улучши лодку у Луки" % ", ".join(places)
	var wait := DayTime.hours_until_active(fish.active_times, hour)
	var next_hour := fposmod(hour + wait, 24.0)
	var timing := "Сейчас клюёт" if is_zero_approx(wait) else "Клёв с %02d:%02d" % [int(next_hour), roundi(fmod(next_hour, 1.0) * 60.0)]
	if wait < 0.0:
		timing = "Сейчас не клюёт"
	if habitat in fish.habitats:
		return "%s · здесь\nИщи круги рыбных мест на воде" % timing
	return "%s\n%s · путь через причал" % [", ".join(places), timing]
