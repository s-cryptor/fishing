extends SceneTree
## Подсказки согласованы, читаются без цвета и не меняют исход рыбалки.

var _failures := 0

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# SceneTree-скрипт компилируется до автозагрузок; UI загружаем после их создания.
	var button_script: Script = load("res://scripts/ui/action_button.gd")
	var controller_script: Script = load("res://scripts/fishing/fishing_controller.gd")
	var phases: Dictionary = controller_script.get_script_constant_map()["Phase"]
	var fish: FishData = load("res://data/fish/pike.tres")
	var gear: GearStats = load("res://data/gear/bamboo_rod.tres")
	var rng := RandomNumberGenerator.new()
	rng.seed = 15
	var session := FishingSession.new(fish, 2.0, 14.0, gear, rng)
	_check(session.bite_time_left() == 0.0 and session.telegraph_progress() == 0.0, "до поклёвки нет ложных индикаторов времени")
	session.tick(10.0, false)
	var state: Dictionary = button_script.state_for(phases.SESSION, session)
	_check(state["label"] == "ПОДСЕЧЬ!" and is_equal_approx(state["progress"], 1.0), "поклёвка начинает полный круг реакции")
	var left := session.bite_time_left()
	_check(left > 0 and is_equal_approx(left, session.bite_window()), "публичный таймер совпадает с окном подсечки")
	session.tick(left * 0.5, false)
	state = button_script.state_for(phases.SESSION, session)
	_check(is_equal_approx(state["progress"], 0.5), "круг реакции убывает вместе с реальным таймером")
	session.hook()
	_check(session.bite_time_left() == 0.0, "после подсечки круг поклёвки исчезает")
	session._thrash_timer = 1.0
	session.tension = 0.5
	var feedback := FishingFeedback.fight(session)
	_check(feedback["label"] == "ТЯНИ", "обычная борьба предлагает подмотку")
	session.tension = 0.9
	feedback = FishingFeedback.fight(session)
	_check(feedback["label"] == "ОТПУСТИ" and feedback["color"] == FishingFeedback.DANGER, "опасное натяжение требует отпустить")
	session.tension = 0.5
	session.is_thrashing = true
	feedback = FishingFeedback.fight(session)
	_check(feedback["label"] == "ОТПУСТИ" and feedback["detail"].contains("рывок"), "во время рывка кнопка не советует тянуть")
	session.tension = 0.0
	_check(FishingFeedback.fight(session)["label"] == "ТЯНИ", "крайний провис имеет приоритет, чтобы не потерять рыбу")
	session.tension = 0.5
	session.is_thrashing = false
	session._thrash_timer = FishingSession.THRASH_WARNING * 0.5
	feedback = FishingFeedback.fight(session)
	_check(feedback["label"] == "ГОТОВЬСЯ" and is_equal_approx(feedback["progress"], 0.5), "замах предупреждает заранее, а не выдаёт ложный рывок")
	session._thrash_timer = 1.0
	session.control = 1.0
	feedback = FishingFeedback.fight(session)
	_check(feedback["label"] == "ДЕРЖИ" and feedback["detail"].contains("18%"), "хороший контроль показывает реальный бонус")
	var before := [session.state, session.tension, session.stamina, session.distance, session._thrash_timer, rng.state]
	for i in 100:
		FishingFeedback.fight(session)
		button_script.state_for(phases.SESSION, session)
	_check(before == [session.state, session.tension, session.stamina, session.distance, session._thrash_timer, rng.state],
		"отрисовка не расходует время, RNG, силы и дистанцию")
	for phase in phases.values():
		state = button_script.state_for(phase, session, 0.6)
		var label_width := ThemeDB.fallback_font.get_string_size(state["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var detail_width := ThemeDB.fallback_font.get_string_size(state["detail"], HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		_check(label_width <= 150 and detail_width <= 150, "подписи фазы %d помещаются в тач-кнопке" % phase)
	state = button_script.state_for(phases.CHARGING, null, 0.6)
	_check(is_equal_approx(state["progress"], 0.6), "круг зарядки соответствует силе заброса")
	_check(button_script.state_for(phases.SESSION, null)["label"] == "ЗАБРОС", "пустая сессия обрабатывается безопасно")
	quit(1 if _failures else 0)

func _check(ok: bool, message: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", message])
	if not ok:
		_failures += 1
