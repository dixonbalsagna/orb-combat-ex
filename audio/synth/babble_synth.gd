class_name BabbleSynth
extends RefCounted
## Renders the babble bank (data/babble.json): a few short syllables per voice, in four timbres, and a laugh. A
## syllable is one call to the grunt voice engine (GruntSynth): an onset (a plosive burst, a nasal murmur, a breath or
## nothing) gliding into a vowel, about 100 ms long, at the voice's reference pitch. The player then changes its pitch
## a few semitones per syllable to make the contour. Bank ids: "babble.<voice>.<timbre>.<syllable>" and
## "babble.<voice>.laugh". Pure functions of the data and the fixed bank seed.


static func render(id: String, cfg: Dictionary) -> PackedFloat32Array:
	var p: PackedStringArray = id.split(".")
	if p.size() == 3 and p[2] == "blip":
		return blip(cfg, p[1])
	if p.size() == 3 and (p[2] == "laugh" or p[2] == "laugh_boom"):
		return laugh(cfg, p[1], 0, p[2] == "laugh_boom")
	if p.size() == 4:
		return syllable(cfg, p[1], p[2], p[3])
	return PackedFloat32Array()


static func _scaled(v: Dictionary, k: float) -> Dictionary:
	var f: Array = []
	for x in v.f:
		f.append(float(x) * k)
	return {"f": f, "bw": v.bw}


## The recipe of one syllable as a GruntSynth definition.
static func syllable_def(cfg: Dictionary, voice: String, timbre: String, syl: String, f0_mul: float = 1.0) -> Dictionary:
	var V: Dictionary = cfg.voices[voice]
	var S: Dictionary = cfg.syllables[syl]
	var on: Dictionary = cfg.onsets[S.onset]
	var tm: Dictionary = cfg.timbres[timbre]
	var k: float = float(V.formant_k)
	var vowel: Dictionary = _scaled(cfg.vowels[S.vowel], k)
	var onset: Dictionary = _scaled(cfg.nasal, k) if bool(on.nasal) else vowel
	var dur: float = float(V.syl_ms) * 0.001
	var f0: float = float(V.ref_f0) * f0_mul * float(S.get("f0_mul", 1.0))
	return {
		"rate": int(cfg.rate), "dur": dur, "f0": [f0, f0 * 0.94], "f0_tau": 0.05,
		"f0_jitter": float(V.jitter) * float(tm.jitter), "shimmer": float(V.shimmer) * float(tm.shimmer),
		"open": clampf(float(V.open) * float(tm.open) * float(S.get("open_mul", 1.0)), 0.3, 0.9), "fry": maxf(float(tm.fry), float(S.get("fry", 0.0))),
		"vowel_a": onset, "vowel_b": vowel, "glide": on.glide,
		"breath": float(on.breath) * float(tm.breath), "h_onset": float(on.h_onset), "breath_body": 0.08,
		"attack": 0.006 * float(tm.attack), "hold": dur * 0.35, "t60": dur * 0.5,
		"drive": float(V.drive) * float(tm.drive), "peak_db": -8.0
	}


static func syllable(cfg: Dictionary, voice: String, timbre: String, syl: String) -> PackedFloat32Array:
	var def: Dictionary = syllable_def(cfg, voice, timbre, syl)
	var buf: PackedFloat32Array = GruntSynth.render(def, int(cfg.bank_seed), "babble.%s.%s.%s" % [voice, timbre, syl], 0)
	buf = _chorus(buf, cfg.voices[voice], int(cfg.rate))
	_crush(buf, cfg.voices[voice])
	buf = _comb(buf, cfg.voices[voice], int(cfg.rate))
	return buf


## A laugh: pulses of "ha" (a breath into an open vowel) falling or rising in pitch, spaced and fading as the voice says.
static func laugh(cfg: Dictionary, voice: String, variant: int, boom: bool = false) -> PackedFloat32Array:
	var V: Dictionary = cfg.voices[voice]
	var L: Dictionary = V.laugh_boom if boom else V.laugh
	var rate: int = int(cfg.rate)
	var pulses: int = int(L.pulses)
	var cfg2: Dictionary = cfg
	if L.has("formant_k"):
		# a laugh with its own vocal-tract size (a deep, booming one): the syllables are built from a copy of the voice
		var vcopy: Dictionary = V.duplicate()
		vcopy["formant_k"] = L.formant_k
		cfg2 = cfg.duplicate()
		cfg2["voices"] = cfg.voices.duplicate()
		cfg2.voices[voice] = vcopy
	var mix := PackedFloat32Array()
	var t: float = 0.0
	var gain: float = 1.0
	for p in range(pulses):
		var u: float = float(p) / float(maxi(pulses - 1, 1))
		var f0: float = lerpf(float(L.f0[0]), float(L.f0[1]), u) * pow(2.0, float(L.step_st) * float(p) / 12.0)
		var def: Dictionary = syllable_def(cfg2, voice, "base", "ha", f0 / float(V.ref_f0))
		def["dur"] = float(L.pulse_ms) * 0.001
		def["hold"] = def.dur * 0.3
		def["t60"] = def.dur * 0.45
		def["breath"] = float(L.breath)
		def["f0"] = [f0, f0 * 0.9]
		var pb: PackedFloat32Array = GruntSynth.render(def, int(cfg.bank_seed), "babble.%s.laugh.%d.%d" % [voice, variant, p], 0)
		AudioDsp.mix_into(mix, pb, int(t * rate), gain)
		t += lerpf(float(L.spacing[0]), float(L.spacing[1]), u) * (1.0 + 0.08 * float(variant))
		gain *= float(L.decay)
	mix = _chorus(mix, V, rate)
	_crush(mix, V)
	mix = _comb(mix, V, rate)
	AudioDsp.normalize(mix, AudioDsp.db_to_lin(-7.0))
	return mix


## A bit-crush and sample-hold for the mechanical voice (crush_bits 0 leaves the buffer alone).
static func _crush(buf: PackedFloat32Array, V: Dictionary) -> void:
	var bits: int = int(V.get("crush_bits", 0))
	var hold: int = maxi(int(V.get("hold", 1)), 1)
	if bits <= 0 and hold <= 1:
		return
	var q: float = pow(2.0, float(bits) - 1.0) if bits > 0 else 0.0
	var held: float = 0.0
	for i in range(buf.size()):
		if i % hold == 0:
			held = buf[i]
		buf[i] = roundf(held * q) / q if q > 0.0 else held


## A short synthetic blip (the Cyborg's: a square-ish wave with a soft attack, bit-crushed), at the voice's blip pitch; the plan
## moves it a few semitones. Data: the voice's `blip` {f, ms, bits, hold}.
static func blip(cfg: Dictionary, voice: String) -> PackedFloat32Array:
	var B: Dictionary = cfg.voices[voice].blip
	var rate: int = int(cfg.rate)
	var n: int = int(float(B.ms) * 0.001 * float(rate))
	var out := PackedFloat32Array()
	out.resize(n)
	var w: float = TAU * float(B.f) / float(rate)
	for i in range(n):
		var t: float = float(i) / float(rate)
		var env: float = minf(1.0, t / 0.004) * pow(10.0, -3.0 * float(i) / float(n))
		var ph: float = w * float(i)
		out[i] = (sin(ph) + sin(3.0 * ph) / 3.0 + sin(5.0 * ph) / 5.0) * env
	AudioDsp.normalize(out, AudioDsp.db_to_lin(-9.0))
	_crush(out, {"crush_bits": int(B.get("bits", 5)), "hold": int(B.get("hold", 1))})
	return out


## The Empress's two voices a hair apart (a chorus) and one faint early reflection (so she sounds larger than the room),
## baked into the clip. Data: the voice's `chorus` {detune_st, wet, delay_ms, reflect_ms, reflect_gain}; absent leaves the clip alone.
static func _chorus(buf: PackedFloat32Array, V: Dictionary, rate: int) -> PackedFloat32Array:
	if not V.has("chorus") or buf.is_empty():
		return buf
	var C: Dictionary = V.chorus
	var step: float = pow(2.0, float(C.detune_st) / 12.0)
	var d1: int = int(float(C.delay_ms) * 0.001 * float(rate))
	var d2: int = int(float(C.reflect_ms) * 0.001 * float(rate))
	var n: int = buf.size() + d2
	var out := PackedFloat32Array()
	out.resize(n)
	var peak: float = AudioDsp.peak(buf)
	for i in range(buf.size()):
		out[i] += buf[i]
		out[i + d2] += buf[i] * float(C.reflect_gain)
	var m: int = int(float(buf.size()) / step)
	for j in range(m):
		var p: float = float(j) * step
		var i0: int = int(p)
		var f: float = p - float(i0)
		var a: float = buf[i0]
		var b: float = buf[i0 + 1] if i0 + 1 < buf.size() else 0.0
		out[j + d1] += (a + (b - a) * f) * float(C.wet)
	AudioDsp.normalize(out, peak)
	return out


## A short feedback comb (a metallic resonance in the chassis), baked. Data: the voice's `comb` {delay_ms, feedback}.
static func _comb(buf: PackedFloat32Array, V: Dictionary, rate: int) -> PackedFloat32Array:
	if not V.has("comb") or buf.is_empty():
		return buf
	var K: Dictionary = V.comb
	var d: int = maxi(1, int(float(K.delay_ms) * 0.001 * float(rate)))
	var fb: float = float(K.feedback)
	var n: int = buf.size() + 4 * d
	var out := PackedFloat32Array()
	out.resize(n)
	var peak: float = AudioDsp.peak(buf)
	for i in range(n):
		var x: float = buf[i] if i < buf.size() else 0.0
		out[i] = x + (fb * out[i - d] if i >= d else 0.0)
	AudioDsp.normalize(out, peak)
	return out
