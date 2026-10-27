class_name AmbienceSynth
extends RefCounted
## An ambience bed that loops without a seam (docs/audio/biomes.md): wind, surf, rustle, a city's hum. Built from a few
## layers of filtered noise and low partials whose every movement is a whole number of cycles in the loop, and whose
## noise is filtered round the loop twice (the second pass is kept), so the last sample runs straight into the first.
## A bed is a pure function of its recipe and its seed: the same on every machine. Played by AudioVoices as a looped
## voice whose level the world mapper moves (the fight's intensity ducks it).
## Recipe (data/world_cues.json "beds"):
##   rate        samples a second (the beds are low, nothing above about 1 kHz: 6000 is plenty and renders fast)
##   seconds     the loop's length
##   seed        picks the noise
##   peak_db     the peak after normalising
##   layers      summed; each is rendered to an RMS of 1 and then scaled by its gain:
##     gust      noise that is dark (lo) and brightens towards hi as a gust swells; cycles/amps are the gust's whole
##               cycles in the loop and their weights, floor the level between gusts (0..1), sharp > 1 makes gusts peakier,
##               filter "lp" or "bp", q the resonance, lo_gain how much of the dark noise stays in a gust
##     flutter   noise (filter, f, q) whose level is chopped by a smooth random flutter: rate_hz nodes a second, depth 0..1
##     hum       partials [[multiple, amplitude]] of a fundamental f (snapped to whole cycles), with an optional slow
##               beat: beat cycles in the loop, beat_depth 0..1
##     pulses    count low sweeps f -> f_to of length len seconds at random places (a frog, a glug, a distant knock)


static func render(recipe: Dictionary) -> PackedFloat32Array:
	return AudioSlice.run_sync(Callable(AmbienceSynth, "render_a"), [recipe])


static func render_a(recipe: Dictionary) -> PackedFloat32Array:
	var rate: int = int(recipe.get("rate", 6000))
	var n: int = int(round(float(recipe.get("seconds", 12.0)) * float(rate)))
	var seed_: int = int(recipe.get("seed", 1))
	var mix := PackedFloat32Array()
	mix.resize(n)
	var k: int = 0
	for L in recipe.layers:
		if AudioSlice.due():
			await AudioSlice.next_frame()
		var buf: PackedFloat32Array
		var sd: int = SimRng.deriveSeed(seed_, "amb.layer" + str(k))
		match String(L.type):
			"gust":
				buf = await _gust_a(L, n, rate, sd)
			"flutter":
				buf = await _flutter_a(L, n, rate, sd)
			"hum":
				buf = await _hum_a(L, n, rate, sd)
			"pulses":
				buf = await _pulses_a(L, n, rate, sd)
			_:
				buf = PackedFloat32Array()
		if buf.size() == n:
			var r: float = await AudioDspA.rms(buf)
			var g: float = float(L.get("gain", 1.0)) / maxf(r, 1e-9)
			if String(L.type) == "pulses":
				g = float(L.get("gain", 1.0)) / maxf(await AudioDspA.peak(buf), 1e-9) * 0.5      # a sparse accent is set by its peak
			var _c32: int = 0
			var _e32: int = n
			while _c32 < _e32:
				for i in range(_c32, mini(_c32 + 1024, _e32)):
					mix[i] += buf[i] * g
				_c32 += 1024
				if AudioSlice.due():
					await AudioSlice.next_frame()
		k += 1
	# the DC block runs round the loop twice too (the second pass kept), so it leaves no step at the seam
	var two := PackedFloat32Array()
	two.resize(n * 2)
	var _c33: int = 0
	var _e33: int = n
	while _c33 < _e33:
		for i in range(_c33, mini(_c33 + 1024, _e33)):
			two[i] = mix[i]
			two[n + i] = mix[i]
		_c33 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	await AudioDspA.dc_block(two, 18.0, rate)
	var _c34: int = 0
	var _e34: int = n
	while _c34 < _e34:
		for i in range(_c34, mini(_c34 + 1024, _e34)):
			mix[i] = two[n + i]
		_c34 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	await AudioDspA.normalize(mix, AudioDsp.db_to_lin(float(recipe.get("peak_db", -12.0))))
	return mix


## Noise filtered round the loop: the buffer is run through twice and the second pass kept, so its start continues its end.
static func _round_filter_a(white: PackedFloat32Array, kind: String, f: float, q: float, rate: int) -> PackedFloat32Array:
	var n: int = white.size()
	var two := PackedFloat32Array()
	two.resize(n * 2)
	var _c35: int = 0
	var _e35: int = n
	while _c35 < _e35:
		for i in range(_c35, mini(_c35 + 1024, _e35)):
			two[i] = white[i]
			two[n + i] = white[i]
		_c35 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	await AudioDspA.filter(two, kind, f, f, 0.0, q, rate)
	if kind == "lp":
		await AudioDspA.filter(two, kind, f, f, 0.0, 0.6, rate)      # two poles in a row: the highs fall away at 24 dB an octave, so a bed stays low
	var out := PackedFloat32Array()
	out.resize(n)
	var _c36: int = 0
	var _e36: int = n
	while _c36 < _e36:
		for i in range(_c36, mini(_c36 + 1024, _e36)):
			out[i] = two[n + i]
		_c36 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out


## A periodic curve in 0..1 from whole cycles of a loop, with weights, peaked by sharp.
static func _curve_a(n: int, cycles: Array, amps: Array, sharp: float, rnd: AudioDsp.Rand) -> PackedFloat32Array:
	var c := PackedFloat32Array()
	c.resize(n)
	var lo: float = 1e9
	var hi: float = -1e9
	var ph: Array = []
	var _c37: int = 0
	var _e37: int = cycles.size()
	while _c37 < _e37:
		for j in range(_c37, mini(_c37 + 1024, _e37)):
			ph.append(rnd.next() * TAU)
		_c37 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	var _c39: int = 0
	var _e39: int = n
	while _c39 < _e39:
		for i in range(_c39, mini(_c39 + 1024, _e39)):
			var s: float = 0.0
			var _c38: int = 0
			var _e38: int = cycles.size()
			while _c38 < _e38:
				for j in range(_c38, mini(_c38 + 1024, _e38)):
					s += float(amps[j]) * sin(TAU * float(int(cycles[j])) * float(i) / float(n) + float(ph[j]))
				_c38 += 1024
				if AudioSlice.due():
					await AudioSlice.next_frame()
			c[i] = s
			lo = minf(lo, s)
			hi = maxf(hi, s)
		_c39 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	var span: float = maxf(hi - lo, 1e-9)
	var _c40: int = 0
	var _e40: int = n
	while _c40 < _e40:
		for i in range(_c40, mini(_c40 + 1024, _e40)):
			c[i] = pow(clampf((c[i] - lo) / span, 0.0, 1.0), sharp)
		_c40 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return c


static func _gust_a(L: Dictionary, n: int, rate: int, sd: int) -> PackedFloat32Array:
	var rnd := AudioDsp.Rand.new(sd)
	var kind: String = String(L.get("filter", "lp"))
	var q: float = float(L.get("q", 0.7))
	var dark: PackedFloat32Array = await _round_filter_a(await AudioDspA.noise(n, sd), kind, float(L.lo), q, rate)
	var bright: PackedFloat32Array = await _round_filter_a(await AudioDspA.noise(n, sd + 7), kind, float(L.hi), q, rate)
	var rd: float = maxf(await AudioDspA.rms(dark), 1e-9)
	var rb: float = maxf(await AudioDspA.rms(bright), 1e-9)
	var g: PackedFloat32Array = await _curve_a(n, L.cycles, L.amps, float(L.get("sharp", 1.0)), rnd)
	var floor_: float = float(L.get("floor", 0.3))
	var lo_gain: float = float(L.get("lo_gain", 0.6))
	var out := PackedFloat32Array()
	out.resize(n)
	var _c41: int = 0
	var _e41: int = n
	while _c41 < _e41:
		for i in range(_c41, mini(_c41 + 1024, _e41)):
			var gi: float = g[i]
			out[i] = (dark[i] / rd * (1.0 - gi * (1.0 - lo_gain)) + bright[i] / rb * gi) * (floor_ + (1.0 - floor_) * gi)
		_c41 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out


static func _flutter_a(L: Dictionary, n: int, rate: int, sd: int) -> PackedFloat32Array:
	var rnd := AudioDsp.Rand.new(sd + 3)
	var body: PackedFloat32Array = await _round_filter_a(await AudioDspA.noise(n, sd), String(L.get("filter", "bp")), float(L.f), float(L.get("q", 0.6)), rate)
	var nodes: int = maxi(int(round(float(L.get("rate_hz", 8.0)) * float(n) / float(rate))), 3)
	var rv: Array = []
	var _c42: int = 0
	var _e42: int = nodes
	while _c42 < _e42:
		for j in range(_c42, mini(_c42 + 1024, _e42)):
			rv.append(rnd.next())
		_c42 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	var depth: float = float(L.get("depth", 0.8))
	var out := PackedFloat32Array()
	out.resize(n)
	var _c43: int = 0
	var _e43: int = n
	while _c43 < _e43:
		for i in range(_c43, mini(_c43 + 1024, _e43)):
			var p: float = float(i) * float(nodes) / float(n)
			var j: int = int(p)
			var f: float = p - float(j)
			f = 0.5 - 0.5 * cos(PI * f)
			var r: float = lerpf(float(rv[j % nodes]), float(rv[(j + 1) % nodes]), f)
			out[i] = body[i] * (1.0 - depth + depth * r)
		_c43 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out


static func _hum_a(L: Dictionary, n: int, rate: int, sd: int) -> PackedFloat32Array:
	var cycles: int = maxi(1, int(round(float(L.f) * float(n) / float(rate))))
	var w: float = TAU * float(cycles) / float(n)
	var beat: int = int(L.get("beat", 0))
	var bd: float = float(L.get("beat_depth", 0.0))
	var out := PackedFloat32Array()
	out.resize(n)
	var _c44: int = 0
	var _e44: int = n
	while _c44 < _e44:
		for i in range(_c44, mini(_c44 + 1024, _e44)):
			var s: float = 0.0
			for p in L.partials:
				s += float(p[1]) * sin(w * float(int(p[0])) * float(i))
			if beat > 0:
				s *= 1.0 - bd + bd * (0.5 + 0.5 * sin(TAU * float(beat) * float(i) / float(n)))
			out[i] = s
		_c44 += 1024
		if AudioSlice.due():
			await AudioSlice.next_frame()
	return out


static func _pulses_a(L: Dictionary, n: int, rate: int, sd: int) -> PackedFloat32Array:
	var rnd := AudioDsp.Rand.new(sd)
	var out := PackedFloat32Array()
	out.resize(n)
	var ln: int = int(float(L.get("len", 0.08)) * float(rate))
	var count: int = int(L.get("count", 3))
	for k in range(count):
		# spread over the loop with a jitter, so no two are the same distance apart
		var at: int = int((float(k) + rnd.range_(0.15, 0.85)) * float(n) / float(count))
		var f0: float = float(L.f) * rnd.pm(0.12)
		var f1: float = float(L.get("f_to", L.f)) * rnd.pm(0.12)
		var amp: float = rnd.range_(0.6, 1.0)
		var ph: float = 0.0
		var _c45: int = 0
		var _e45: int = ln
		while _c45 < _e45:
			for i in range(_c45, mini(_c45 + 1024, _e45)):
				var u: float = float(i) / float(ln)
				var f: float = lerpf(f0, f1, u)
				ph += TAU * f / float(rate)
				var env: float = sin(PI * minf(u * 8.0, 1.0) * 0.5) * exp(-4.5 * u)
				out[(at + i) % n] += amp * env * sin(ph)
			_c45 += 1024
			if AudioSlice.due():
				await AudioSlice.next_frame()
	return out
