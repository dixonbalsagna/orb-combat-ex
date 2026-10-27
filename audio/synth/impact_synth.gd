class_name ImpactSynth
extends RefCounted
## Renders an impact, crash or debris sound from a recipe in data/impacts.json: a list of layers summed, saturated and
## normalised. Layer types:
##   tone    a sine that glides from f to f_to (time constant tau) with optional 2nd and 3rd harmonics and saturation.
##           The pitch drop is what gives a hit its body; the harmonics keep it audible on small speakers.
##   noise   filtered white noise ("hp", "lp", "bp", or "none"), the cutoff optionally gliding f -> f_to.
##   rumble  low-passed noise with a slow swell, optionally wobbled: a rolling, distant sound.
##   grains  a scatter of short damped rings (pebbles, plaster, falling rock). The rate starts at rate0 grains a second
##           and falls with time constant tau; each grain has a random pitch in [f0, f1] Hz.
## Every layer is normalised to a peak of 1 and then scaled by its gain, so gain reads as a relative level.
## Times are seconds, frequencies Hz. A recipe's "jitter" widens each variant a little (pitch, decay, level).


## Render one variant of a recipe to a mono buffer at recipe.rate. bank_seed and id pick the noise; variant picks jitter.
static func render(recipe: Dictionary, bank_seed: int, id: String, variant: int) -> PackedFloat32Array:
	return AudioSlice.run_sync(Callable(ImpactSynth, "render_a"), [recipe, bank_seed, id, variant])


static func render_a(recipe: Dictionary, bank_seed: int, id: String, variant: int) -> PackedFloat32Array:
	var rate: int = int(recipe.get("rate", 32000))
	var sd: int = SimRng.deriveSeed(bank_seed, "audio.bank." + id + "." + str(variant))
	var rnd := AudioDsp.Rand.new(sd)
	var jit: Dictionary = recipe.get("jitter", {})
	var jf: float = float(jit.get("f", 0.0))
	var jt: float = float(jit.get("t60", 0.0))
	var jg: float = float(jit.get("gain", 0.0))
	var mix := PackedFloat32Array()
	var k: int = 0
	for L in recipe.layers:
		if AudioSlice.due():
			await AudioSlice.next_frame()
		var P: Dictionary = L.duplicate()
		for key in ["f", "f_to", "lp"]:
			if P.has(key):
				P[key] = _scaled(P[key], rnd.pm(jf))
		if P.has("t60"):
			P["t60"] = float(P["t60"]) * rnd.pm(jt)
		P["gain"] = float(P.get("gain", 1.0)) * rnd.pm(jg)
		var buf: PackedFloat32Array = await _layer_a(P, rate, SimRng.deriveSeed(sd, "layer" + str(k)))
		await AudioDspA.mix_into(mix, buf, int(float(P.get("at", 0.0)) * rate), float(P["gain"]))
		k += 1
	await AudioDspA.saturate(mix, float(recipe.get("drive", 0.0)))
	await AudioDspA.dc_block(mix, 20.0, rate)
	await AudioDspA.normalize(mix, AudioDsp.db_to_lin(float(recipe.get("peak_db", -3.0))))
	await AudioDspA.fade(mix, 0.0004, 0.008, rate)
	return mix


static func _scaled(v, k: float):
	if typeof(v) == TYPE_ARRAY:
		return [float(v[0]) * k, float(v[1]) * k]
	return float(v) * k


static func _layer_a(P: Dictionary, rate: int, sd: int) -> PackedFloat32Array:
	var buf: PackedFloat32Array
	match String(P.type):
		"tone":
			buf = await _tone_a(P, rate)
		"noise":
			buf = await _noise_a(P, rate, sd)
		"rumble":
			buf = await _rumble_a(P, rate, sd)
		"grains":
			buf = await _grains_a(P, rate, sd)
		_:
			push_warning("ImpactSynth: unknown layer type '%s'" % String(P.type))
			buf = PackedFloat32Array()
	await AudioDspA.normalize(buf, 1.0)
	return buf


static func _length(P: Dictionary, rate: int) -> int:
	var t60: float = float(P.get("t60", 0.1))
	return int((float(P.get("attack", 0.0)) + t60 * 1.05) * rate)


static func _tone_a(P: Dictionary, rate: int) -> PackedFloat32Array:
	var n: int = _length(P, rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var fs: float = float(rate)
	var f0: float = float(P.f)
	var f1: float = float(P.get("f_to", f0))
	var tau: float = maxf(float(P.get("tau", 0.05)), 0.001)
	var attack: float = float(P.get("attack", 0.001))
	var h2: float = float(P.get("h2", 0.0))
	var h3: float = float(P.get("h3", 0.0))
	var dec: float = exp(-AudioDsp.LN60 / (fs * float(P.t60)))
	var glide: float = exp(-1.0 / (fs * tau))
	var phase: float = 0.0
	var gl: float = 1.0
	var amp: float = 1.0
	var _c12: int = 0
	var _e12: int = n
	while _c12 < _e12:
		for i in range(_c12, mini(_c12 + 1024, _e12)):
			var f: float = f1 + (f0 - f1) * gl
			gl *= glide
			phase += TAU * f / fs
			var e: float = amp
			var t: float = float(i) / fs
			if t < attack:
				e *= t / attack
			amp *= dec
			out[i] = (sin(phase) + h2 * sin(2.0 * phase) + h3 * sin(3.0 * phase)) * e
		_c12 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	await AudioDspA.saturate(out, float(P.get("drive", 0.0)))
	return out


static func _noise_a(P: Dictionary, rate: int, sd: int) -> PackedFloat32Array:
	var n: int = _length(P, rate)
	var out: PackedFloat32Array = await AudioDspA.noise(n, sd)
	var kind: String = String(P.get("filter", "none"))
	if kind != "none":
		var f0: float = float(P.f)
		await AudioDspA.filter(out, kind, f0, float(P.get("f_to", f0)), float(P.get("tau", 0.0)), float(P.get("q", 0.7)), rate)
	await _envelope_a(out, float(P.get("attack", 0.0005)), float(P.t60), rate)
	return out


static func _rumble_a(P: Dictionary, rate: int, sd: int) -> PackedFloat32Array:
	var n: int = _length(P, rate)
	var out: PackedFloat32Array = await AudioDspA.noise(n, sd)
	var lp: float = float(P.lp)
	await AudioDspA.filter(out, "lp", lp, lp, 0.0, 0.7, rate)
	await AudioDspA.filter(out, "lp", lp, lp, 0.0, 0.7, rate)
	await _envelope_a(out, float(P.get("attack", 0.02)), float(P.t60), rate)
	var wob: float = float(P.get("wobble", 0.0))
	if wob > 0.0:
		var w: float = TAU * float(P.get("wobble_hz", 7.0)) / float(rate)
		var _c13: int = 0
		var _e13: int = n
		while _c13 < _e13:
			for i in range(_c13, mini(_c13 + 1024, _e13)):
				out[i] *= 1.0 + wob * sin(w * float(i))
			_c13 += 1024
			if AudioSlice.due():
				await AudioSlice.next_frame()
	return out


## Linear attack, then an exponential decay that reaches -60 dB at t60 (in place).
static func _envelope_a(buf: PackedFloat32Array, attack: float, t60: float, rate: int) -> void:
	var fs: float = float(rate)
	var dec: float = exp(-AudioDsp.LN60 / (fs * t60))
	var amp: float = 1.0
	var na: int = int(attack * fs)
	var _c14: int = 0
	var _e14: int = buf.size()
	while _c14 < _e14:
		for i in range(_c14, mini(_c14 + 1024, _e14)):
			var e: float = amp
			if i < na:
				e *= float(i) / float(na)
			amp *= dec
			buf[i] *= e
		_c14 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()


static func _grains_a(P: Dictionary, rate: int, sd: int) -> PackedFloat32Array:
	var fs: float = float(rate)
	var length: float = float(P.get("len", 1.0))
	var t60: float = float(P.t60)
	var n: int = int((length + t60) * fs)
	var out := PackedFloat32Array()
	out.resize(n)
	var rnd := AudioDsp.Rand.new(sd)
	var rate0: float = float(P.rate0)
	var tau: float = maxf(float(P.get("tau", 0.5)), 0.001)
	var flo: float = float(P.f[0])
	var fhi: float = float(P.f[1])
	var click: float = float(P.get("click", 0.5))
	var per_sample: float = rate0 / fs
	var fall: float = exp(-1.0 / (fs * tau))
	var p: float = per_sample
	var glen: int = int(t60 * 1.1 * fs)
	var _c16: int = 0
	var _e16: int = int(length * fs)
	while _c16 < _e16:
		for i in range(_c16, mini(_c16 + 1024, _e16)):
			if rnd.next() < p:
				var f: float = flo * pow(fhi / flo, rnd.next())
				var a: float = 0.15 + 0.85 * pow(rnd.next(), 2.0)
				var gt60: float = t60 * (0.6 + 0.8 * rnd.next())
				var w: float = TAU * f / fs
				var gd: float = exp(-AudioDsp.LN60 / (fs * gt60))
				var amp: float = a
				var m: int = mini(glen, n - i)
				var _c15: int = 0
				var _e15: int = m
				while _c15 < _e15:
					for j in range(_c15, mini(_c15 + 1024, _e15)):
						out[i + j] += amp * sin(w * float(j))
						amp *= gd
					_c15 += 1024
					if AudioSlice.due():
						await AudioSlice.next_frame()
				for j in range(mini(3, m)):
					out[i + j] += click * a * (rnd.next() * 2.0 - 1.0)
			p *= fall
		_c16 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out
