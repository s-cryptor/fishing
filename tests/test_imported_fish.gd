extends SceneTree
## Импортированный вид участвует в игре, сохраняя исходный риг и ресурсы ассета.

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var state := root.get_node("GameState")
	var fish: FishData = state.catalog.get_fish(&"mangrove_snapper")
	_check(fish != null and fish.habitats == [&"mangrove"], "луциан добавлен только в мангровые отмели")
	_check(fish.is_active(DayTime.Phase.DAWN) and fish.is_active(DayTime.Phase.DUSK) and fish.is_active(DayTime.Phase.NIGHT)
		and not fish.is_active(DayTime.Phase.DAY), "расписание луциана оставляет цель для сумерек и ночи")
	var appearance := FishModel.appearance_for(fish.id)
	_check(appearance != null and appearance.scene != null and appearance.length > 0 and appearance.eye_anchor.is_finite(),
		"внешний вид задан отдельным валидным ресурсом")
	_check(FishModel.appearance_for(&"roach") == null, "существующие виды продолжают использовать собственные модели")
	var original := appearance.scene.instantiate() as Node3D
	var source_player: AnimationPlayer = original.find_children("*", "AnimationPlayer", true, false)[0]
	var source_loop := source_player.get_animation(appearance.animation_name).loop_mode
	var source_material: Material = (original.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).get_active_material(0)
	var source_color: Color = source_material.albedo_color
	var showcase := FishShowcase.new()
	showcase.size = Vector2(440, 160)
	root.add_child(showcase)
	showcase.fish = fish
	await process_frame
	await process_frame
	var model: Node3D = showcase._model
	var holder: Node3D = model.get_node("ImportedRig")
	var imported: Node3D = holder.get_child(0).get_child(0)
	_check(imported.transform == original.transform, "нормализация не перезаписывает FBX-масштаб и поворот корня")
	var bounds := AABB()
	var found := false
	for mesh: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		var relative := model.global_transform.affine_inverse() * mesh.global_transform
		var box := relative * mesh.get_aabb()
		bounds = bounds.merge(box) if found else box
		found = true
	_check(bounds.size.is_finite() and bounds.size.x > 3.0 and bounds.size.x < 3.3 and bounds.get_center().length() < 0.2,
		"сцена центрирована и вписана в трофей независимо от исходных единиц")
	var player: AnimationPlayer = model.find_children("*", "AnimationPlayer", true, false)[0]
	_check(player.is_playing() and player.current_animation == appearance.animation_name
		and player.get_animation(appearance.animation_name).loop_mode == Animation.LOOP_LINEAR, "исходная Swim-анимация работает в цикле")
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	var attachments := skeleton.find_children("FaceAttachment", "BoneAttachment3D", true, false)
	_check(attachments.size() == 1 and attachments[0].bone_name == appearance.head_bone,
		"добавленные глаза прикреплены к кости головы, а не висят рядом с плавающим телом")
	var poses: Array[Transform3D] = []
	for index in skeleton.get_bone_count():
		poses.append(skeleton.get_bone_pose(index))
	player.advance(0.25)
	var moved := false
	for index in skeleton.get_bone_count():
		moved = moved or not skeleton.get_bone_pose(index).is_equal_approx(poses[index])
	_check(moved, "анимационные треки двигают кости, а не только счётчик времени")
	_check(source_player.get_animation(appearance.animation_name).loop_mode == source_loop and source_material.albedo_color == source_color,
		"повтор и оттенок меняются на копиях, а не в исходном FBX-ресурсе")
	showcase.hide()
	var stopped := player.current_animation_position
	await create_timer(0.15).timeout
	_check(is_equal_approx(player.current_animation_position, stopped) and not player.can_process(), "скрытая карточка останавливает и вложенный AnimationPlayer")
	showcase.show()
	await create_timer(0.15).timeout
	_check(player.current_animation_position > stopped, "повторное открытие продолжает плавание")
	state.inventory.clear()
	state.collection.clear()
	state.claimed_goals.clear()
	for goal in state.JOURNEY.goals:
		state.claimed_goals.append(goal["id"])
	state.register_catch(fish, 1.5)
	state._load()
	_check(state.inventory.size() == 1 and state.inventory[0]["fish_id"] == "mangrove_snapper"
		and state.collection.has("mangrove_snapper"), "новый вид сохраняется в садке и коллекции")
	_check(state.cooking_selection(state.MEALS.get_meal(&"fish_soup")).is_empty(), "редкий луциан не расходуется кухней как обычный улов")
	var money: int = state.money
	var value: int = state.sell_all()
	_check(value == fish.value_for(1.5) and state.money == money + value and state.collection.has("mangrove_snapper"),
		"продажа использует цену ресурса и не стирает рекорд нового вида")
	var orders := OrderBook.new(state.catalog)
	var requested := false
	for seed_value in range(2, 200):
		if orders.generate(seed_value)["fish_id"] == "mangrove_snapper":
			requested = true
			break
	_check(requested, "генератор заказов подхватывает новый вид без отдельного кода")
	state.money = 0
	state.collection.clear()
	state.claimed_goals.erase("mangrove_complete")
	for known in state.catalog.for_habitat(&"mangrove"):
		if known.id != fish.id:
			state.collection[String(known.id)] = {"count": 1, "best_kg": known.min_weight_kg}
	state._claim_goals()
	_check(state.money == 0 and "mangrove_collection" in state.claimed_goals, "старое достижение четырёх видов остаётся выданным, без повторной выплаты")
	state.collection[String(fish.id)] = {"count": 1, "best_kg": 1.5}
	state._claim_goals()
	state._claim_goals()
	_check(state.money == 120 and "mangrove_complete" in state.claimed_goals, "пятый вид даёт отдельную награду ровно один раз")
	var original_store: SaveStore = state._store
	var future := SaveStore.new("user://future-fish-schema-fixture.json")
	var future_text := JSON.stringify({"version": SaveStore.VERSION + 1, "money": 999, "inventory": "unknown future structure"})
	var file := FileAccess.open(future.path, FileAccess.WRITE)
	file.store_string(future_text)
	file.close()
	state._store = future
	state._load()
	_check(state.progress_read_only and state.inventory.is_empty() and not state.save_recovery_notice.is_empty(),
		"будущая схема не интерпретируется текущей игрой и явно помечена только для чтения")
	state._save()
	_check(FileAccess.get_file_as_string(future.path) == future_text, "текущая игра не перезаписывает данные будущей версии")
	state._store = original_store
	state._load()
	original.free()
	showcase.queue_free()
	await process_frame
	quit(1 if _failures else 0)

func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
