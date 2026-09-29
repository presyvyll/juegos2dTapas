class_name TropicalRaceMusic
extends RefCounted
## Generates a compact two-bar techno-tropical loop for the active circuit.

const MIX_RATE := 16000
const MAJOR_PENTATONIC := [0, 2, 4, 7, 9]
const MINOR_PENTATONIC := [0, 3, 5, 7, 10]

static func build(theme_id: String, seed_value: int) -> AudioStreamWAV:
	return _build_loop(theme_id, seed_value, 4, false)

static func build_menu() -> AudioStreamWAV:
	return _build_loop("tropical", 20260929, 16, true)

static func _build_loop(theme_id: String, seed_value: int, beats: int, menu: bool) -> AudioStreamWAV:
	var parameters := _parameters(theme_id, seed_value)
	if menu:
		parameters.merge({"bpm": 138.0, "root": 47, "electronic": 0.72, "tropical": 1.0, "brightness": 0.92, "minor": false}, true)
	var bpm: float = parameters.bpm
	var duration := beats * 60.0 / bpm
	var sample_count := ceili(duration * MIX_RATE)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 4)
	var melody := _melody(seed_value, parameters.minor, beats)
	var bass_pattern := [0, 0, 7, 5]
	for sample_index in range(sample_count):
		var time := float(sample_index) / MIX_RATE
		var beat := time * bpm / 60.0
		var beat_index := int(floor(beat)) % beats
		var beat_phase := fposmod(beat, 1.0)
		var half_step := int(floor(beat * 2.0)) % (beats * 2)
		var local_half_step := half_step % 8
		var half_phase := fposmod(beat * 2.0, 1.0)
		var noise := _noise(sample_index, seed_value)
		var kick := sin(TAU * (50.0 + 48.0 * exp(-beat_phase * 14.0)) * time) * exp(-beat_phase * 13.0)
		var snare := 0.0
		if beat_index % 4 in [1, 3]:
			snare = noise * exp(-beat_phase * 18.0)
		var hat := noise * exp(-half_phase * 34.0)
		var bass_note: int = parameters.root + bass_pattern[beat_index % bass_pattern.size()]
		var bass_frequency := _midi_frequency(bass_note)
		var bass_wave := asin(sin(TAU * bass_frequency * time)) * 2.0 / PI
		var bass := bass_wave * (0.72 + 0.28 * exp(-beat_phase * 5.0))
		var tropical := 0.0
		if melody[half_step] >= 0:
			var note_frequency := _midi_frequency(parameters.root + 12 + melody[half_step])
			var pluck_envelope := exp(-half_phase * (8.0 + parameters.brightness * 4.0))
			tropical = (sin(TAU * note_frequency * time) + sin(TAU * note_frequency * 2.01 * time) * 0.36) * pluck_envelope
		var clave := 0.0
		if local_half_step in [0, 3, 6]:
			clave = sin(TAU * (1180.0 + parameters.brightness * 340.0) * time) * exp(-half_phase * 46.0)
		var synth_pulse := 0.0
		if beat_index % 2 == 0:
			var pulse_frequency := _midi_frequency(parameters.root + 24 + (7 if beat_index == 4 else 0))
			synth_pulse = sin(TAU * pulse_frequency * time) * exp(-beat_phase * 5.5)
		var electronic_mix: float = parameters.electronic
		var tropical_mix: float = parameters.tropical
		var center := kick * (0.54 + electronic_mix * 0.16) + bass * 0.24 + snare * 0.16 + hat * (0.055 + electronic_mix * 0.035)
		var melody_signal := tropical * (0.19 + tropical_mix * 0.13) + clave * (0.08 + tropical_mix * 0.06) + synth_pulse * electronic_mix * 0.10
		var stereo_swing := -0.16 if half_step % 2 == 0 else 0.16
		var fade := minf(1.0, minf(float(sample_index) / 96.0, float(sample_count - sample_index - 1) / 96.0))
		var left := clampf((center + melody_signal * (1.0 - stereo_swing)) * 0.70 * fade, -0.96, 0.96)
		var right := clampf((center + melody_signal * (1.0 + stereo_swing)) * 0.70 * fade, -0.96, 0.96)
		_encode_sample(bytes, sample_index * 4, left)
		_encode_sample(bytes, sample_index * 4 + 2, right)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = true
	stream.data = bytes
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream

static func _parameters(theme_id: String, seed_value: int) -> Dictionary:
	var result := {
		"bpm": 132.0 + posmod(seed_value, 5) * 2.0,
		"root": 43 + posmod(seed_value, 5),
		"electronic": 0.62,
		"tropical": 0.78,
		"brightness": 0.55,
		"minor": false,
	}
	match theme_id:
		"neon", "eclipse":
			result.merge({"bpm": 148.0, "electronic": 0.96, "tropical": 0.58, "brightness": 0.92, "minor": true}, true)
		"canal_turbo":
			result.merge({"bpm": 152.0, "electronic": 0.92, "tropical": 0.70, "brightness": 0.80}, true)
		"tormenta":
			result.merge({"bpm": 144.0, "root": 41, "electronic": 0.88, "tropical": 0.55, "brightness": 0.35, "minor": true}, true)
		"templo", "laberinto", "ojo", "remolino":
			result.merge({"bpm": 134.0, "electronic": 0.68, "tropical": 0.66, "brightness": 0.42, "minor": true}, true)
		"cascada", "express", "titan":
			result.merge({"bpm": 140.0, "electronic": 0.76, "tropical": 0.82, "brightness": 0.68}, true)
		"fuente", "jardin", "plaza", "tropical":
			result.merge({"bpm": 130.0, "electronic": 0.60, "tropical": 1.0, "brightness": 0.86}, true)
	return result

static func _melody(seed_value: int, minor: bool, beats: int) -> PackedInt32Array:
	var scale: Array = MINOR_PENTATONIC if minor else MAJOR_PENTATONIC
	var rhythm := [true, false, true, true, false, true, false, true, true, false, true, false, true, true, false, true]
	var notes := PackedInt32Array()
	for step in range(beats * 2):
		if not rhythm[step % rhythm.size()]:
			notes.append(-1)
			continue
		var scale_index := posmod(seed_value + step * 3 + step * step, scale.size())
		var phrase_step := step % 16
		notes.append(scale[scale_index] + (12 if phrase_step in [7, 15] else 0))
	return notes

static func _midi_frequency(note: int) -> float:
	return 440.0 * pow(2.0, (note - 69) / 12.0)

static func _noise(index: int, seed_value: int) -> float:
	var value := posmod(index * 1103515245 + seed_value * 12345, 2147483647)
	return float(value) / 1073741823.5 - 1.0

static func _encode_sample(bytes: PackedByteArray, offset: int, sample: float) -> void:
	var encoded := clampi(roundi(sample * 32767.0), -32768, 32767)
	if encoded < 0:
		encoded += 65536
	bytes.encode_u16(offset, encoded)
