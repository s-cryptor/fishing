extends Node
## Прогресс игрока: деньги, садок, коллекция, снаряжение.
## Единственное место, где меняется сохраняемое состояние — позже эти
## методы станут командами для сервера.

signal money_changed(money: int)
signal inventory_changed
signal gear_changed
signal orders_changed
signal order_completed(order: Dictionary)
signal journey_changed
signal milestone_reached(title: String, reward: int)
signal supplies_changed
signal save_failed(message: String)

const CATALOG: FishCatalog = preload("res://data/fish_catalog.tres")
const GEAR_CATALOG: GearCatalog = preload("res://data/gear_catalog.tres")
const JOURNEY: JourneyData = preload("res://data/journey.tres")
const BAIT: BaitData = preload("res://data/bait.tres")
const BOAT: BoatStats = preload("res://data/boats/explorer.tres")
const BIOMES: BiomeCatalog = preload("res://data/biome_catalog.tres")
const LANDMARKS: LandmarkCatalog = preload("res://data/landmark_catalog.tres")

var catalog: FishCatalog = CATALOG
var gear_catalog: GearCatalog = GEAR_CATALOG
## Надетая удочка.
var gear: GearStats:
	get:
		return gear_catalog.get_rod(StringName(equipped_gear_id))
var money := 0
## Пойманная, но ещё не проданная рыба: [{fish_id, weight_kg}].
var inventory: Array[Dictionary] = []
## fish_id -> {count, best_kg}
var collection: Dictionary = {}
var owned_gear: Array[String] = []
var equipped_gear_id := ""
var orders := OrderBook.new(CATALOG)
var claimed_goals: Array[String] = []
var visited_biomes: Array[String] = ["home_lake"]
var discovered_landmarks: Array[String] = []
var sales := 0
var bait_charges := 0
var bait_enabled := false
var boat_upgraded := false
## Подробности последнего улова для карточки результата.
var last_catch_report: Dictionary = {}
var save_recovery_notice := ""

var _store := SaveStore.new(DebugTools.save_path if DebugTools.save_path else "user://save.json")


func _ready() -> void:
	_load()


## Записывает улов. Возвращает true, если вид пойман впервые.
func register_catch(fish: FishData, weight_kg: float) -> bool:
	var key := String(fish.id)
	var is_new := not collection.has(key)
	var entry: Dictionary = collection.get(key, {"count": 0, "best_kg": 0.0})
	var old_best := float(entry["best_kg"])
	entry["count"] = int(entry["count"]) + 1
	entry["best_kg"] = maxf(entry["best_kg"], weight_kg)
	collection[key] = entry
	inventory.append({"fish_id": key, "weight_kg": weight_kg})
	var completed := orders.register_catch(fish, weight_kg)
	for order in completed:
		money += int(order["reward"])
	orders.refill()
	last_catch_report = {"record": not is_new and weight_kg > old_best,
		"previous_best": old_best, "trophy": is_trophy(fish, weight_kg), "rewards": []}
	last_catch_report["rewards"] = _claim_goals()
	_save()
	inventory_changed.emit()
	orders_changed.emit()
	for order in completed:
		order_completed.emit(order)
	if not completed.is_empty():
		money_changed.emit(money)
	journey_changed.emit()
	return is_new


func inventory_value() -> int:
	var total := 0
	for item in inventory:
		var fish := catalog.get_fish(StringName(item["fish_id"]))
		if fish:
			total += fish.value_for(item["weight_kg"])
	return total


func sell_all() -> int:
	var total := inventory_value()
	inventory.clear()
	money += total
	if total > 0:
		sales += 1
	_claim_goals()
	_save()
	inventory_changed.emit()
	money_changed.emit(money)
	journey_changed.emit()
	return total


func owns_gear(id: StringName) -> bool:
	return String(id) in owned_gear


func buy_bait() -> bool:
	if money < BAIT.price:
		return false
	money -= BAIT.price
	bait_charges += BAIT.charges
	bait_enabled = true
	_supplies_updated(true)
	return true


func upgrade_boat() -> bool:
	if boat_upgraded or money < BOAT.price:
		return false
	money -= BOAT.price
	boat_upgraded = true
	orders.available_habitats.assign([&"lake", &"mangrove", &"fjord"])
	_claim_goals()
	_supplies_updated(true)
	journey_changed.emit()
	return true


func toggle_bait() -> void:
	if bait_charges <= 0:
		return
	bait_enabled = not bait_enabled
	_supplies_updated()


## Бонусы применяем к копии, общий ресурс удочки остаётся неизменным.
func fishing_gear(habitat: StringName) -> GearStats:
	var result := gear.duplicate() as GearStats
	if boat_upgraded and habitat != &"lake":
		result.luck += BOAT.scouting_luck
	if bait_enabled and bait_charges > 0:
		result.luck += BAIT.luck_bonus
		result.bite_time_mult *= BAIT.bite_time_mult
	return result


## Вызывать только после создания сессии: заброс на сушу приманку не тратит.
func consume_bait() -> void:
	if not bait_enabled or bait_charges <= 0:
		return
	bait_charges -= 1
	if bait_charges == 0:
		bait_enabled = false
	_supplies_updated()


func _supplies_updated(spent_money := false) -> void:
	_save()
	if spent_money:
		money_changed.emit(money)
	supplies_changed.emit()


func buy_gear(rod: GearStats) -> bool:
	if owns_gear(rod.id) or money < rod.price:
		return false
	money -= rod.price
	owned_gear.append(String(rod.id))
	equipped_gear_id = String(rod.id)
	_claim_goals()
	_save()
	money_changed.emit(money)
	gear_changed.emit()
	journey_changed.emit()
	return true


func visit_biome(id: StringName) -> void:
	if String(id) in visited_biomes:
		return
	visited_biomes.append(String(id))
	_claim_goals()
	_save()
	journey_changed.emit()


func is_trophy(fish: FishData, weight: float) -> bool:
	return weight >= lerpf(fish.min_weight_kg, fish.max_weight_kg, 0.85)


func discover_landmark(id: StringName) -> bool:
	if LANDMARKS.get_landmark(id) == null or String(id) in discovered_landmarks:
		return false
	discovered_landmarks.append(String(id))
	_claim_goals()
	_save()
	journey_changed.emit()
	return true


func journey_progress(metric: String) -> int:
	match metric:
		"landmarks": return discovered_landmarks.size()
		"sales": return sales
		"species": return collection.size()
		"rods": return owned_gear.size()
		"mangrove_visit": return 1 if "mangrove_shallows" in visited_biomes else 0
		"fjord_visit": return 1 if "ice_fjord" in visited_biomes else 0
		"boat": return 1 if boat_upgraded else 0
	var count := 0
	for fish in catalog.fish:
		var entry: Dictionary = collection.get(String(fish.id), {})
		if entry.is_empty():
			continue
		match metric:
			"catches": count += int(entry["count"])
			"lake_species": count += 1 if &"lake" in fish.habitats else 0
			"mangrove_species": count += 1 if &"mangrove" in fish.habitats else 0
			"fjord_species": count += 1 if &"fjord" in fish.habitats else 0
			"trophies": count += 1 if is_trophy(fish, float(entry["best_kg"])) else 0
	return count


func next_goal() -> Dictionary:
	for goal in JOURNEY.goals:
		if goal["id"] not in claimed_goals:
			return goal
	return {}


func _claim_goals() -> Array[Dictionary]:
	var rewards: Array[Dictionary] = []
	for goal in JOURNEY.goals:
		if goal["id"] in claimed_goals or journey_progress(goal["metric"]) < int(goal["target"]):
			continue
		claimed_goals.append(goal["id"])
		money += int(goal["reward"])
		rewards.append(goal)
		milestone_reached.emit(goal["title"], int(goal["reward"]))
	if not rewards.is_empty():
		money_changed.emit(money)
	return rewards


func equip_gear(rod: GearStats) -> void:
	if not owns_gear(rod.id) or equipped_gear_id == String(rod.id):
		return
	equipped_gear_id = String(rod.id)
	_save()
	gear_changed.emit()


func _save() -> void:
	var saved := _store.save_data({
		"money": money,
		"inventory": inventory,
		"collection": collection,
		"owned_gear": owned_gear,
		"equipped_gear": equipped_gear_id,
		"orders": orders.to_dict(),
		"claimed_goals": claimed_goals,
		"visited_biomes": visited_biomes,
		"discovered_landmarks": discovered_landmarks,
		"sales": sales,
		"bait_charges": bait_charges,
		"bait_enabled": bait_enabled,
		"boat_upgraded": boat_upgraded,
	})
	if not saved:
		save_failed.emit(_store.last_error)


func _load() -> void:
	var data := _store.load_data()
	save_recovery_notice = "Сохранение восстановлено после сбоя" if not _store.recovered_from.is_empty() else _store.last_error
	money = int(data.get("money", 0))
	inventory.assign(data.get("inventory", []))
	collection = data.get("collection", {})
	claimed_goals.assign(data.get("claimed_goals", []))
	visited_biomes.assign(data.get("visited_biomes", ["home_lake"]))
	# До v6 открытий не было. Неизвестные и повторные записи не дают прогресс.
	discovered_landmarks.clear()
	for id in data.get("discovered_landmarks", []):
		if LANDMARKS.get_landmark(StringName(str(id))) and str(id) not in discovered_landmarks:
			discovered_landmarks.append(str(id))
	sales = int(data.get("sales", 0))
	bait_charges = maxi(0, int(data.get("bait_charges", 0)))
	bait_enabled = bool(data.get("bait_enabled", false)) and bait_charges > 0
	boat_upgraded = bool(data.get("boat_upgraded", false))
	orders.available_habitats.assign([&"lake", &"mangrove", &"fjord"] if boat_upgraded else [&"lake", &"mangrove"])
	# В сохранениях v1 снастей не было — выдаём стартовую удочку.
	var starter := String(gear_catalog.rods[0].id)
	owned_gear.assign(data.get("owned_gear", [starter]))
	equipped_gear_id = data.get("equipped_gear", starter)
	if gear_catalog.get_rod(StringName(equipped_gear_id)) == null:
		equipped_gear_id = starter
	# До v3 заказов не было — refill выдаст первые.
	orders.load_dict(data.get("orders", {}))
	orders.refill()
