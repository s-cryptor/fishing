class_name HumanPlayer
extends RefCounted
## Бот, похожий на человека: видит шкалу с задержкой реакции и
## действует с гистерезисом — отпускает в красной зоне, снова мотает,
## когда стрелка вернулась в зелёную. Время реакции плавает от решения
## к решению. Нужен для балансных тестов.

## Средняя реакция; конкретная — от 0.7× до 1.6× от неё.
var reaction_time := 0.25
var release_above := 0.85
var resume_below := 0.6

var _time := 0.0
var _bite_seen_at := -1.0
var _reeling := true
var _current_reaction: float
var _rng := RandomNumberGenerator.new()
## [[время, натяжение], ...] — что игрок «видел» в прошлом.
var _seen: Array[Vector2] = []


func _init(p_reaction_time := 0.25, seed_value := 0) -> void:
	reaction_time = p_reaction_time
	_rng.seed = seed_value
	_roll_reaction()


func wants_action(session: FishingSession, delta: float) -> bool:
	_time += delta
	match session.state:
		FishingSession.State.BITING:
			if _bite_seen_at < 0.0:
				_bite_seen_at = _time
			return _time - _bite_seen_at >= _current_reaction
		FishingSession.State.FIGHTING:
			_seen.append(Vector2(_time, session.tension))
			while _seen.size() > 1 and _seen[1].x <= _time - _current_reaction:
				_seen.pop_front()
			var tension := _seen[0].y
			if _reeling and tension >= release_above:
				_reeling = false
				_roll_reaction()
			elif not _reeling and tension <= resume_below:
				_reeling = true
				_roll_reaction()
			return _reeling
	return false


func _roll_reaction() -> void:
	_current_reaction = reaction_time * _rng.randf_range(0.7, 1.6)
