class_name SfxSynth
## Синтез звуков-заглушек прямо в коде: без файлов и зависимостей,
## одинаково работает на всех платформах. Когда появятся настоящие
## записи, Sfx просто начнёт грузить их вместо этих функций.

const MIX_RATE := 22050


## Всплеск: шум с быстрой атакой и затуханием, приглушённый фильтром.
static func splash(duration := 0.4, brightness := 0.35) -> AudioStreamWAV:
	var rng := _rng(1)
	var samples := PackedFloat32Array()
	var filtered := 0.0
	var count := int(duration * MIX_RATE)
	for i in count:
		var t := float(i) / count
		filtered = lerpf(filtered, rng.randf_range(-1.0, 1.0), brightness * (1.0 - t * 0.7))
		samples.append(filtered * _envelope(t, 0.03) * 1.6)
	return _to_wav(samples)


## Поклёвка: короткий «бульк» — синус с падающей частотой.
static func plop() -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var phase := 0.0
	var count := int(0.14 * MIX_RATE)
	for i in count:
		var t := float(i) / count
		phase += TAU * lerpf(700.0, 180.0, t) / MIX_RATE
		samples.append(sin(phase) * _envelope(t, 0.05) * 0.8)
	return _to_wav(samples)


## Треск катушки: зацикленная серия щелчков.
static func reel_loop() -> AudioStreamWAV:
	var rng := _rng(2)
	var samples := PackedFloat32Array()
	var click_every := int(0.035 * MIX_RATE)
	var count := click_every * 8
	for i in count:
		var since_click := i % click_every
		var decay := exp(-since_click / 25.0)
		samples.append(rng.randf_range(-1.0, 1.0) * decay * 0.5)
	return _to_wav(samples, true)


## Обрыв: резкий щелчок и низкий глухой удар.
static func snap() -> AudioStreamWAV:
	var rng := _rng(3)
	var samples := PackedFloat32Array()
	var count := int(0.3 * MIX_RATE)
	var phase := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		phase += TAU * 90.0 / MIX_RATE
		var crack := rng.randf_range(-1.0, 1.0) * exp(-t * 90.0)
		var thump := sin(phase) * exp(-t * 14.0) * 0.6
		samples.append(crack + thump)
	return _to_wav(samples)


## Заброс: «вжух» — шум с плавным нарастанием и спадом.
static func whoosh() -> AudioStreamWAV:
	var rng := _rng(4)
	var samples := PackedFloat32Array()
	var filtered := 0.0
	var count := int(0.35 * MIX_RATE)
	for i in count:
		var t := float(i) / count
		filtered = lerpf(filtered, rng.randf_range(-1.0, 1.0), lerpf(0.05, 0.4, sin(t * PI)))
		samples.append(filtered * sin(t * PI) * 1.8)
	return _to_wav(samples)


## Улов: арпеджио вверх. notes — полутоны от до первой октавы.
static func jingle(notes: Array[int] = [0, 4, 7, 12]) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	var note_len := int(0.11 * MIX_RATE)
	for n in notes.size():
		var freq := 261.63 * pow(2.0, notes[n] / 12.0)
		var length := note_len * (3 if n == notes.size() - 1 else 1)
		for i in length:
			var t := float(i) / length
			var tone := sin(TAU * freq * i / MIX_RATE) + 0.3 * sin(TAU * freq * 2.0 * i / MIX_RATE)
			samples.append(tone * _envelope(t, 0.02) * 0.35)
	return _to_wav(samples)


static func _envelope(t: float, attack: float) -> float:
	if t < attack:
		return t / attack
	return pow(1.0 - (t - attack) / (1.0 - attack), 2.0)


static func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


## Пик выше этого уровня ужимается — без клиппинга.
const MAX_PEAK := 0.9


static func _to_wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
	var gain := MAX_PEAK / peak if peak > MAX_PEAK else 1.0
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(samples[i] * gain * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav
