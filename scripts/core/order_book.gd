class_name OrderBook
extends RefCounted
## Заказы соседей: «поймай N рыб вида X весом от Y кг». Чистая логика
## без сцены — генерация по счётчику seed, учёт улова, сериализация.
## Заказ: {giver, fish_id, min_kg, count, progress, reward}.

const ACTIVE_ORDERS := 3
const GIVERS: Array[String] = ["Повар Марта", "Торговец Лука", "Смотритель маяка", "Бабушка Агата"]
## Сколько рыб просят в зависимости от редкости.
const COUNT_BY_RARITY: Array[Vector2i] = [Vector2i(2, 5), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 1), Vector2i(1, 1)]
## Награда — во сколько раз дороже, чем просто продать такой улов.
const REWARD_MULT := 2.5
## Первые заказы — обучающие: 1–2 обычные рыбы любого веса.
const TUTORIAL_ORDERS := 2

var orders: Array[Dictionary] = []
## Сколько заказов уже выдано: из него получается seed следующего.
var issued := 0
var available_habitats: Array[StringName] = [&"lake", &"mangrove"]

var _catalog: FishCatalog


func _init(catalog: FishCatalog) -> void:
	_catalog = catalog


## Добирает заказы до ACTIVE_ORDERS. Возвращает true, если что-то добавилось.
func refill() -> bool:
	var added := false
	while orders.size() < ACTIVE_ORDERS:
		orders.append(generate(issued))
		issued += 1
		added = true
	return added


func generate(seed_value: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_value)
	# Просим чаще обычную рыбу, но не только её.
	var pool: Array[FishData] = _catalog.fish.filter(_is_available)
	if seed_value < TUTORIAL_ORDERS:
		pool = pool.filter(func(f: FishData) -> bool: return f.rarity == FishData.Rarity.COMMON and &"lake" in f.habitats)
	var weights := PackedFloat32Array()
	for f in pool:
		weights.append(sqrt(f.spawn_weight))
	var fish := pool[rng.rand_weighted(weights)]
	var range_kg := fish.max_weight_kg - fish.min_weight_kg
	var min_kg := snappedf(fish.min_weight_kg + range_kg * rng.randf_range(0.1, 0.45), 0.1)
	var counts := COUNT_BY_RARITY[fish.rarity]
	var count := rng.randi_range(counts.x, counts.y)
	if seed_value < TUTORIAL_ORDERS:
		min_kg = 0.0
		count = rng.randi_range(1, 2)
	# Награду считаем хотя бы от среднего веса, иначе «любая рыба» стоит копейки.
	var average_kg := (fish.min_weight_kg + fish.max_weight_kg) * 0.5
	return {
		"giver": GIVERS[rng.randi() % GIVERS.size()],
		"fish_id": String(fish.id),
		"min_kg": min_kg,
		"count": count,
		"progress": 0,
		"reward": roundi(fish.value_for(maxf(min_kg, average_kg)) * count * REWARD_MULT) + 10,
	}


func _is_available(fish: FishData) -> bool:
	for habitat in fish.habitats:
		if habitat in available_habitats:
			return true
	return false


## Засчитывает улов. Возвращает выполненные заказы (уже убранные из списка).
func register_catch(fish: FishData, weight_kg: float) -> Array[Dictionary]:
	var completed: Array[Dictionary] = []
	for order in orders:
		if order["fish_id"] == String(fish.id) and weight_kg >= order["min_kg"]:
			order["progress"] = int(order["progress"]) + 1
			if order["progress"] >= int(order["count"]):
				completed.append(order)
			# Одна рыба закрывает только один заказ.
			break
	for order in completed:
		orders.erase(order)
	return completed


static func describe(order: Dictionary, catalog: FishCatalog) -> String:
	var fish := catalog.get_fish(StringName(order["fish_id"]))
	return "%s: %s%s — %d/%d" % [order["giver"], fish.display_name if fish else "?",
			" от %.1f кг" % order["min_kg"] if order["min_kg"] > 0.0 else "", int(order["progress"]), int(order["count"])]


func to_dict() -> Dictionary:
	return {"orders": orders, "issued": issued}


func load_dict(data: Dictionary) -> void:
	orders.assign(data.get("orders", []))
	issued = int(data.get("issued", 0))
