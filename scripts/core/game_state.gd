extends Node
## Прогресс игрока: деньги, садок, коллекция, снаряжение.
## Единственное место, где меняется сохраняемое состояние — позже эти
## методы станут командами для сервера.

signal money_changed(money: int)
signal inventory_changed
signal gear_changed

const CATALOG: FishCatalog = preload("res://data/fish_catalog.tres")
const GEAR_CATALOG: GearCatalog = preload("res://data/gear_catalog.tres")

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

var _store := SaveStore.new(DebugTools.save_path if DebugTools.save_path else "user://save.json")


func _ready() -> void:
	_load()


## Записывает улов. Возвращает true, если вид пойман впервые.
func register_catch(fish: FishData, weight_kg: float) -> bool:
	var key := String(fish.id)
	var is_new := not collection.has(key)
	var entry: Dictionary = collection.get(key, {"count": 0, "best_kg": 0.0})
	entry["count"] = int(entry["count"]) + 1
	entry["best_kg"] = maxf(entry["best_kg"], weight_kg)
	collection[key] = entry
	inventory.append({"fish_id": key, "weight_kg": weight_kg})
	_save()
	inventory_changed.emit()
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
	_save()
	inventory_changed.emit()
	money_changed.emit(money)
	return total


func owns_gear(id: StringName) -> bool:
	return String(id) in owned_gear


func buy_gear(rod: GearStats) -> bool:
	if owns_gear(rod.id) or money < rod.price:
		return false
	money -= rod.price
	owned_gear.append(String(rod.id))
	equipped_gear_id = String(rod.id)
	_save()
	money_changed.emit(money)
	gear_changed.emit()
	return true


func equip_gear(rod: GearStats) -> void:
	if not owns_gear(rod.id) or equipped_gear_id == String(rod.id):
		return
	equipped_gear_id = String(rod.id)
	_save()
	gear_changed.emit()


func _save() -> void:
	_store.save_data({
		"money": money,
		"inventory": inventory,
		"collection": collection,
		"owned_gear": owned_gear,
		"equipped_gear": equipped_gear_id,
	})


func _load() -> void:
	var data := _store.load_data()
	money = int(data.get("money", 0))
	inventory.assign(data.get("inventory", []))
	collection = data.get("collection", {})
	# В сохранениях v1 снастей не было — выдаём стартовую удочку.
	var starter := String(gear_catalog.rods[0].id)
	owned_gear.assign(data.get("owned_gear", [starter]))
	equipped_gear_id = data.get("equipped_gear", starter)
	if gear_catalog.get_rod(StringName(equipped_gear_id)) == null:
		equipped_gear_id = starter
